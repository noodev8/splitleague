/*
=======================================================================================================================================
API Route: get_league_members
=======================================================================================================================================
Method: POST
Purpose: Retrieves all members of a specific league
=======================================================================================================================================
Request Payload:
{
  "league_id": 1                        // integer - ID of the league to get members for
}

Success Response:
{
  "return_code": "SUCCESS",
  "members": [
    {
      "id": 1,                          // integer - User ID
      "name": "John Doe",               // string - User name
      "nickname": "johndoe",            // string - User nickname
      "is_creator": true,               // boolean - Whether the user is the creator of the league
      "joined_at": "2025-04-10T12:00:00.000Z" // timestamp - When the user joined the league
    }
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"
"LEAGUE_NOT_FOUND"
"NO_MEMBERS_FOUND"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /get_league_members
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract league ID from request body and convert to integer
    const league_id = parseInt(req.body.league_id);
    
    console.log('Received league_id:', league_id, 'Type:', typeof league_id);
    
    if (!league_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League ID is required'
      });
    }
    
    // Check if the league exists
    const leagueResult = await pool.query(
      'SELECT * FROM league WHERE id = $1',
      [league_id]
    );
    
    console.log('League query result:', leagueResult.rows);
    
    if (leagueResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found'
      });
    }
    
    // Check if the user is a member of the league or the creator
    const userId = req.userId;
    const membershipResult = await pool.query(
      `SELECT 1 FROM league_members 
       WHERE league_id = $1 AND user_id = $2
       UNION
       SELECT 1 FROM league
       WHERE id = $1 AND created_by = $2`,
      [league_id, userId]
    );
    
    if (membershipResult.rows.length === 0) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You are not a member of this league'
      });
    }
    
    const creator_id = leagueResult.rows[0].created_by;

    const membersResult = await pool.query(
      `SELECT 
        u.id, 
        u.name, 
        u.nickname,
        lm.joined_at
       FROM league_members lm
       JOIN app_user u ON u.id = lm.user_id
       WHERE lm.league_id = $1
       ORDER BY u.name ASC`,
      [league_id]
    );

    // Add is_creator flag to each member
    const members = membersResult.rows.map(member => ({
      ...member,
      is_creator: member.id === creator_id
    }));
    
    // Return success response with members data
    return res.status(200).json({
      return_code: 'SUCCESS',
      members: members
    });
  } catch (error) {
    console.error('Error in get_league_members route:', error);
    
    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
