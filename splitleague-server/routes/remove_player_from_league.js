/*
=======================================================================================================================================
API Route: remove_player_from_league
=======================================================================================================================================
Method: POST
Purpose: Allows a league organizer to remove a player from their league.
         Will fail if fixtures have already been generated.

         If the removed player is a guest, and that removal leaves them belonging to no
         league at all, their app_user row is deleted too. A guest row exists only to be a
         placeholder in somebody's league - once it is in no league it is unreachable by
         every screen in the app, and nothing else in the codebase would ever clean it up.
=======================================================================================================================================
Request Payload:
{
  "league_id": 1,                      // integer, required - ID of the league
  "player_id": 2                       // integer, required - ID of the player to remove
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Player successfully removed from the league",
  "guest_deleted": false               // boolean - true if the player was a guest whose
                                       //           app_user row was also deleted
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"LEAGUE_NOT_FOUND"
"UNAUTHORIZED"
"PLAYER_NOT_FOUND"
"FIXTURES_EXIST"
"INVALID_OPERATION"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /remove_player_from_league
router.post('/', verifyToken, async (req, res) => {
  // Take a dedicated client so the membership delete and the guest cleanup that may follow
  // it happen as one unit. There are no foreign keys on app_user in this database, so
  // nothing at the storage layer would stop us leaving a half-finished removal behind.
  const client = await pool.connect();

  try {
    // Extract data from request body
    const { league_id, player_id } = req.body;

    // Check if required fields are provided
    if (!league_id || !player_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League ID and player ID are required'
      });
    }

    // Get the authenticated user ID from the token
    const organizerId = req.userId;

    // Begin transaction
    await client.query('BEGIN');

    // Check if the league exists
    const leagueResult = await client.query(
      'SELECT * FROM league WHERE id = $1',
      [league_id]
    );

    // If league doesn't exist, return error
    if (leagueResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found'
      });
    }

    // Get the league details
    const league = leagueResult.rows[0];

    // Check if the authenticated user is the league organizer
    if (parseInt(league.created_by) !== parseInt(organizerId)) {
      await client.query('ROLLBACK');
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'Only the league organizer can remove players'
      });
    }

    // Check if the organizer is trying to remove themselves
    if (parseInt(player_id) === parseInt(organizerId)) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        return_code: 'INVALID_OPERATION',
        message: 'League organizer cannot remove themselves from the league'
      });
    }

    // Check if the player is a member of the league
    const membershipResult = await client.query(
      'SELECT * FROM league_members WHERE league_id = $1 AND user_id = $2',
      [league_id, player_id]
    );

    // If player is not a member, return error
    if (membershipResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        return_code: 'PLAYER_NOT_FOUND',
        message: 'Player is not a member of this league'
      });
    }

    // Check if fixtures have been generated for this league
    const fixturesResult = await client.query(
      'SELECT COUNT(*) FROM fixture WHERE league_id = $1',
      [league_id]
    );

    // If fixtures exist, return error
    if (parseInt(fixturesResult.rows[0].count) > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        return_code: 'FIXTURES_EXIST',
        message: 'Cannot remove player because fixtures have already been generated'
      });
    }

    // Look at the player before we remove them, so we still know whether they were a guest
    //
    // A guest is identified by the literal email 'guest' - not by the nickname prefix,
    // which has changed shape once already.
    const playerResult = await client.query(
      'SELECT id, lower(email) = $2 AS is_guest FROM app_user WHERE id = $1',
      [player_id, 'guest']
    );

    const isGuest = playerResult.rows.length > 0 && playerResult.rows[0].is_guest;

    // Remove the player from the league
    await client.query(
      'DELETE FROM league_members WHERE league_id = $1 AND user_id = $2',
      [league_id, player_id]
    );

    // If that was a guest, delete the guest row itself once it belongs to nothing
    //
    // A real user's account outlives any league they leave. A guest row does not: it was
    // created by add_guest_player purely to stand for a person in one league, it can never
    // log in, and no screen can reach it. Left behind it is dead weight that nothing else
    // in the app would ever clear out.
    //
    // Two conditions have to hold before we delete, and both are checked rather than
    // assumed, because this database has no foreign keys on app_user - nothing at the
    // storage layer will stop us cutting a row out from under a fixture that still
    // points at it.
    //
    //   1. The guest is now in no league at all. Guests are normally in exactly one, but
    //      convert_guest_to_user and any hand-editing of the data mean we check instead
    //      of trusting that.
    //   2. No fixture anywhere references them. The FIXTURES_EXIST guard above already
    //      blocks removal from a league that has fixtures, so this should never fire -
    //      it is the backstop that keeps a stale reference from becoming a broken one.
    let guestDeleted = false;

    if (isGuest) {
      const remainingResult = await client.query(
        'SELECT COUNT(*) FROM league_members WHERE user_id = $1',
        [player_id]
      );

      const fixtureRefsResult = await client.query(
        'SELECT COUNT(*) FROM fixture WHERE player_1_id = $1 OR player_2_id = $1',
        [player_id]
      );

      const stillInALeague = parseInt(remainingResult.rows[0].count) > 0;
      const referencedByFixture = parseInt(fixtureRefsResult.rows[0].count) > 0;

      if (!stillInALeague && !referencedByFixture) {
        await client.query('DELETE FROM app_user WHERE id = $1', [player_id]);
        guestDeleted = true;
      }
    }

    // Commit the transaction
    await client.query('COMMIT');

    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'Player successfully removed from the league',
      guest_deleted: guestDeleted
    });
  } catch (error) {
    // Roll back the transaction so a failed removal leaves nothing half-done
    await client.query('ROLLBACK');

    // Log the error for debugging
    console.error('Error in remove_player_from_league route:', error);

    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });

  } finally {
    // Release the client back to the pool
    client.release();
  }
});

module.exports = router;
