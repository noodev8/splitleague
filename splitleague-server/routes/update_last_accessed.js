/*
=======================================================================================================================================
API Route: update_last_accessed
=======================================================================================================================================
Method: POST
Purpose: Updates the last_accessed timestamp for a league member when they access a league.
=======================================================================================================================================
Request Payload:
{
  "league_id": 1                      // integer, required - ID of the league being accessed
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Last accessed timestamp updated successfully"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"LEAGUE_NOT_FOUND"
"NOT_A_MEMBER"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /update_last_accessed
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

    // Check if the user is a member of the league
    const membershipResult = await pool.query(
      'SELECT * FROM league_members WHERE league_id = $1 AND user_id = $2',
      [league_id, userId]
    );

    // If user is not a member, check if they are the creator
    if (membershipResult.rows.length === 0) {
      const creatorResult = await pool.query(
        'SELECT * FROM league WHERE id = $1 AND created_by = $2',
        [league_id, userId]
      );

      // If user is the creator but not in league_members, add them
      if (creatorResult.rows.length > 0) {
        await pool.query(
          'INSERT INTO league_members (league_id, user_id, active, joined_at, last_accessed) VALUES ($1, $2, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)',
          [league_id, userId]
        );
      } else {
        return res.status(403).json({
          return_code: 'NOT_A_MEMBER',
          message: 'You are not a member of this league'
        });
      }
    } else {
      // Update the last_accessed timestamp for the member
      await pool.query(
        'UPDATE league_members SET last_accessed = CURRENT_TIMESTAMP WHERE league_id = $1 AND user_id = $2',
        [league_id, userId]
      );
    }

    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'Last accessed timestamp updated successfully'
    });
  } catch (error) {
    console.error('Error in update_last_accessed route:', error);

    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
