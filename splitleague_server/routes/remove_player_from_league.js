/*
=======================================================================================================================================
API Route: remove_player_from_league
=======================================================================================================================================
Method: POST
Purpose: Allows a league organizer to remove a player from their league.
         Will fail if fixtures have already been generated.
=======================================================================================================================================
Request Payload:
{
  "league_id": 1,                      // integer, required - ID of the league
  "player_id": 2                       // integer, required - ID of the player to remove
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Player successfully removed from the league"
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

    // Check if the league exists
    const leagueResult = await pool.query(
      'SELECT * FROM league WHERE id = $1',
      [league_id]
    );

    // If league doesn't exist, return error
    if (leagueResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found'
      });
    }

    // Get the league details
    const league = leagueResult.rows[0];

    // Check if the authenticated user is the league organizer
    if (parseInt(league.created_by) !== parseInt(organizerId)) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'Only the league organizer can remove players'
      });
    }

    // Check if the organizer is trying to remove themselves
    if (parseInt(player_id) === parseInt(organizerId)) {
      return res.status(400).json({
        return_code: 'INVALID_OPERATION',
        message: 'League organizer cannot remove themselves from the league'
      });
    }

    // Check if the player is a member of the league
    const membershipResult = await pool.query(
      'SELECT * FROM league_members WHERE league_id = $1 AND user_id = $2',
      [league_id, player_id]
    );

    // If player is not a member, return error
    if (membershipResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'PLAYER_NOT_FOUND',
        message: 'Player is not a member of this league'
      });
    }

    // Check if fixtures have been generated for this league
    const fixturesResult = await pool.query(
      'SELECT COUNT(*) FROM fixture WHERE league_id = $1',
      [league_id]
    );

    // If fixtures exist, return error
    if (parseInt(fixturesResult.rows[0].count) > 0) {
      return res.status(400).json({
        return_code: 'FIXTURES_EXIST',
        message: 'Cannot remove player because fixtures have already been generated'
      });
    }

    // Remove the player from the league
    await pool.query(
      'DELETE FROM league_members WHERE league_id = $1 AND user_id = $2',
      [league_id, player_id]
    );

    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'Player successfully removed from the league'
    });
  } catch (error) {
    // Log the error for debugging
    console.error('Error in remove_player_from_league route:', error);

    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
