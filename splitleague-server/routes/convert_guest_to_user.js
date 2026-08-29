/*
=======================================================================================================================================
API Route: convert_guest_to_user
=======================================================================================================================================
Method: POST
Purpose: Converts a guest player to a registered user by updating database references and removing guest indicators.
         Only league organizers can perform this conversion.
=======================================================================================================================================
Request Payload:
{
  "guest_user_id": 24,               // integer, required - ID of the guest user to convert
  "registered_user_email": "user@example.com", // string, required - Email of the registered user to convert to
  "league_id": 1                     // integer, required - ID of the league for authorization
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Guest player successfully converted to registered user",
  "updates": {
    "league_members_updated": 1,     // integer - Number of league_members records updated
    "fixtures_updated": 5            // integer - Number of fixture records updated
  }
}

Error Responses:
{
  "return_code": "MISSING_FIELDS",
  "message": "Guest user ID, registered user email, and league ID are required"
}
{
  "return_code": "LEAGUE_NOT_FOUND",
  "message": "League not found"
}
{
  "return_code": "UNAUTHORIZED",
  "message": "Only the league organizer can convert guest players"
}
{
  "return_code": "GUEST_NOT_FOUND",
  "message": "Guest user not found or not a guest player"
}
{
  "return_code": "USER_NOT_FOUND",
  "message": "Registered user not found"
}
{
  "return_code": "USER_ALREADY_IN_LEAGUE",
  "message": "User is already a member of this league"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /convert_guest_to_user
router.post('/', verifyToken, async (req, res) => {
  // Get a client from the pool for transaction
  const client = await pool.connect();

  try {
    // Extract data from request body
    const { guest_user_id, registered_user_email, league_id } = req.body;

    // Check if required fields are provided
    if (!guest_user_id || !registered_user_email || !league_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Guest user ID, registered user email, and league ID are required'
      });
    }

    // Get the authenticated user ID from the token (the organizer)
    const organizerId = req.userId;

    // Begin transaction
    await client.query('BEGIN');

    // Check if the league exists and if the user is the organizer
    const leagueResult = await client.query(
      'SELECT * FROM league WHERE id = $1',
      [league_id]
    );

    if (leagueResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found'
      });
    }

    const league = leagueResult.rows[0];

    // Check if the authenticated user is the organizer of the league
    if (league.created_by !== organizerId) {
      await client.query('ROLLBACK');
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'Only the league organizer can convert guest players'
      });
    }

    // Check if the guest user exists and is actually a guest (email = 'guest')
    const guestResult = await client.query(
      'SELECT * FROM app_user WHERE id = $1 AND email = $2',
      [guest_user_id, 'guest']
    );

    if (guestResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        return_code: 'GUEST_NOT_FOUND',
        message: 'Guest user not found or not a guest player'
      });
    }

    // Check if the registered user exists and is not a guest
    const userResult = await client.query(
      'SELECT * FROM app_user WHERE email = $1 AND email != $2',
      [registered_user_email, 'guest']
    );

    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        return_code: 'USER_NOT_FOUND',
        message: 'Registered user not found'
      });
    }

    const registeredUser = userResult.rows[0];
    const registered_user_id = registeredUser.id;

    // Check if the registered user is already a member of this league
    const existingMemberResult = await client.query(
      `SELECT COUNT(*) FROM league_members
       WHERE league_id = $1 AND user_id = $2 AND active = true
       UNION ALL
       SELECT COUNT(*) FROM league
       WHERE id = $1 AND created_by = $2`,
      [league_id, registered_user_id]
    );

    // Check if user is already in the league (either as member or creator)
    const memberCount = existingMemberResult.rows.reduce((sum, row) => sum + parseInt(row.count), 0);
    if (memberCount > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        return_code: 'USER_ALREADY_IN_LEAGUE',
        message: 'User is already a member of this league'
      });
    }

    // Update league_members table
    const leagueMembersResult = await client.query(
      'UPDATE league_members SET user_id = $1 WHERE user_id = $2 RETURNING id',
      [registered_user_id, guest_user_id]
    );

    // Update fixture table - player_1_id
    const fixtures1Result = await client.query(
      'UPDATE fixture SET player_1_id = $1 WHERE player_1_id = $2 RETURNING id',
      [registered_user_id, guest_user_id]
    );

    // Update fixture table - player_2_id
    const fixtures2Result = await client.query(
      'UPDATE fixture SET player_2_id = $1 WHERE player_2_id = $2 RETURNING id',
      [registered_user_id, guest_user_id]
    );

    // Nothing to clean up on the registered user's nickname
    //
    // Guests used to carry a ' (g)' suffix, so this is where it was stripped off the
    // real account when a guest was converted. The suffix is gone - new guests never
    // get one and the old rows were backfilled - so the registered user's nickname is
    // left exactly as they typed it.

    // Delete the guest user record
    await client.query(
      'DELETE FROM app_user WHERE id = $1',
      [guest_user_id]
    );

    // Commit the transaction
    await client.query('COMMIT');

    // Calculate total fixtures updated
    const totalFixturesUpdated = fixtures1Result.rows.length + fixtures2Result.rows.length;

    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'Guest player successfully converted to registered user',
      updates: {
        league_members_updated: leagueMembersResult.rows.length,
        fixtures_updated: totalFixturesUpdated
      }
    });

  } catch (error) {
    // Rollback transaction on error
    await client.query('ROLLBACK');
    console.error('Error converting guest to user:', error);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while converting guest player'
    });
  } finally {
    // Release the client back to the pool
    client.release();
  }
});

module.exports = router;
