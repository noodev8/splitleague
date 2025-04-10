/*
=======================================================================================================================================
API Route: join_league
=======================================================================================================================================
Method: POST
Purpose: Allows a user to join a league using a 4-digit public code. If the user is already a member, returns success without adding them again.
         Will fail if fixtures have already been generated.
=======================================================================================================================================
Request Payload:
{
  "public_code": "1234"                // string, required - The 4-digit public code of the league to join
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Successfully joined the league"
}

Already Member Response:
{
  "return_code": "SUCCESS",
  "message": "You are already a member of this league"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_CODE"
"LEAGUE_INACTIVE"
"FIXTURES_EXIST"
"UNAUTHORIZED"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /join_league
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract public code from request body
    const { public_code } = req.body;

    // Check if public code is provided
    if (!public_code) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Public code is required'
      });
    }

    // Get the user ID from the authenticated token
    const userId = req.userId;

    // Find the league by public code
    const leagueResult = await pool.query(
      'SELECT * FROM league WHERE public_code = $1',
      [public_code]
    );

    // Check if league exists
    if (leagueResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'INVALID_CODE',
        message: 'League not found with the provided code'
      });
    }

    // Get the league
    const league = leagueResult.rows[0];

    // Check if league is active
    if (!league.active) {
      return res.status(400).json({
        return_code: 'LEAGUE_INACTIVE',
        message: 'This league is no longer active'
      });
    }

    // Check if user is already a member of the league
    const membershipResult = await pool.query(
      'SELECT * FROM league_members WHERE league_id = $1 AND user_id = $2',
      [league.id, userId]
    );

    // If user is already a member, return success message
    if (membershipResult.rows.length > 0) {
      return res.status(200).json({
        return_code: 'SUCCESS',
        message: 'You are already a member of this league'
      });
    }

    // Check if fixtures have been generated for this league
    const fixturesResult = await pool.query(
      'SELECT COUNT(*) FROM fixture WHERE league_id = $1',
      [league.id]
    );

    // If fixtures exist, return error
    if (parseInt(fixturesResult.rows[0].count) > 0) {
      return res.status(400).json({
        return_code: 'FIXTURES_EXIST',
        message: 'Cannot join this league because fixtures have already been generated'
      });
    }

    // Add user to the league
    await pool.query(
      'INSERT INTO league_members (league_id, user_id, active, joined_at) VALUES ($1, $2, true, CURRENT_TIMESTAMP)',
      [league.id, userId]
    );

    // Return simple success response
    return res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Successfully joined the league'
    });
  } catch (error) {
    console.error('Error in join_league route:', error);

    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
