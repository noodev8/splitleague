/*
=======================================================================================================================================
API Route: get_hidden_leagues
=======================================================================================================================================
Method: POST
Purpose: Retrieves all leagues that the authenticated user has hidden from their dashboard.
         These are leagues where the user's membership has active=false.
=======================================================================================================================================
Request Payload:
{
  // No additional parameters required - user is identified by JWT token
}

Success Response:
{
  "return_code": "SUCCESS",
  "leagues": [
    {
      "league_id": 1,
      "name": "Example League",
      "public_code": "1234",
      "share_slug": "7jwpbsz5ym",
      "created_at": "2023-01-01T00:00:00.000Z",
      "is_creator": false,
      "player_count": 5,
      // ... other league details
    }
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /get_hidden_leagues
router.post('/', verifyToken, async (req, res) => {
  try {
    // Get the authenticated user ID from the token
    const userId = req.userId;

    // Query to get all hidden leagues the user is a member of
    const result = await pool.query(`
      SELECT
        l.id as league_id,
        l.name,
        l.public_code,
        l.share_slug,
        l.created_at,
        l.created_by,
        CASE WHEN l.created_by = $1 THEN true ELSE false END as is_creator,
        lm.joined_at,
        lm.last_accessed,
        (
          SELECT COUNT(*)
          FROM league_members lm2
          WHERE lm2.league_id = l.id AND lm2.active = true
        ) as player_count
      FROM league l
      JOIN league_members lm ON l.id = lm.league_id
      WHERE lm.user_id = $1 AND lm.active = false
      ORDER BY lm.last_accessed DESC NULLS LAST
    `, [userId]);

    // Process the results to format them properly
    const leagues = result.rows.map(league => ({
      ...league,
      created_at: league.created_at.toISOString().split('T')[0], // Format date as YYYY-MM-DD
      joined_at: league.joined_at ? league.joined_at.toISOString().split('T')[0] : null,
      last_accessed: league.last_accessed ? league.last_accessed.toISOString() : null
    }));

    // Return success response with leagues data
    return res.status(200).json({
      return_code: 'SUCCESS',
      leagues: leagues
    });
  } catch (error) {
    console.error('Error in get_hidden_leagues route:', error);
    
    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
