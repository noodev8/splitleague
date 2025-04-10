/*
=======================================================================================================================================
API Route: deactivate_league_membership
=======================================================================================================================================
Method: POST
Purpose: Allows a user to remove themselves from a league by setting their active status to false.
         This will hide the league from their dashboard without actually deleting the membership record.
=======================================================================================================================================
Request Payload:
{
  "league_id": 1                      // integer, required - ID of the league to remove from dashboard
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "League successfully removed from your dashboard"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"LEAGUE_NOT_FOUND"
"NOT_A_MEMBER"
"LEAGUE_CREATOR"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /deactivate_league_membership
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract league ID from request body
    const { league_id } = req.body;

    // Check if league_id is provided
    if (!league_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League ID is required'
      });
    }

    // Get the user ID from the authenticated token
    const userId = req.userId;

    // Check if the league exists
    const leagueResult = await pool.query(
      'SELECT * FROM league WHERE id = $1',
      [league_id]
    );

    if (leagueResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found'
      });
    }

    // Check if the user is the creator of the league
    const league = leagueResult.rows[0];
    if (parseInt(league.created_by) === parseInt(userId)) {
      return res.status(400).json({
        return_code: 'LEAGUE_CREATOR',
        message: 'League creators cannot remove themselves from their own leagues'
      });
    }

    // Check if the user is a member of the league
    const membershipResult = await pool.query(
      'SELECT * FROM league_members WHERE league_id = $1 AND user_id = $2',
      [league_id, userId]
    );

    if (membershipResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'NOT_A_MEMBER',
        message: 'You are not a member of this league'
      });
    }

    // Update the active status to false
    await pool.query(
      'UPDATE league_members SET active = false WHERE league_id = $1 AND user_id = $2',
      [league_id, userId]
    );

    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'League successfully removed from your dashboard'
    });
  } catch (error) {
    console.error('Error in deactivate_league_membership route:', error);

    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
