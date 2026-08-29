/*
=======================================================================================================================================
API Route: get_notes
=======================================================================================================================================
Method: POST
Purpose: Retrieves organizer notes for a specific league member
=======================================================================================================================================
Request Payload:
{
  "league_id": 1,                     // integer, required - ID of the league
  "user_id": 2                        // integer, required - ID of the user to get notes for
}

Success Response:
{
  "return_code": "SUCCESS",
  "notes": "Player prefers evening games"  // string - Notes about the player
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"
"MISSING_FIELDS"
"LEAGUE_NOT_FOUND"
"USER_NOT_IN_LEAGUE"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /get_notes
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract parameters from request body
    const { league_id, user_id } = req.body;
    
    // Validate required fields
    if (!league_id || !user_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League ID and user ID are required'
      });
    }
    
    // Check if the league exists
    const leagueResult = await pool.query(
      'SELECT created_by FROM league WHERE id = $1',
      [league_id]
    );
    
    if (leagueResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found'
      });
    }
    
    // Get the league creator (organizer)
    const leagueCreator = leagueResult.rows[0].created_by;
    
    // Get the requesting user ID
    const requestingUserId = req.userId;
    
    // Check if the user is a member of the league
    const membershipResult = await pool.query(
      'SELECT id FROM league_members WHERE league_id = $1 AND user_id = $2',
      [league_id, user_id]
    );
    
    if (membershipResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'USER_NOT_IN_LEAGUE',
        message: 'User is not a member of this league'
      });
    }
    
    // Check if the requesting user is either:
    // 1. The league organizer, or
    // 2. The user themselves
    if (requestingUserId !== leagueCreator && requestingUserId !== user_id) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You are not authorized to view these notes'
      });
    }
    
    // Get the notes for the league member
    const notesResult = await pool.query(
      'SELECT organiser_notes FROM league_members WHERE league_id = $1 AND user_id = $2',
      [league_id, user_id]
    );
    
    // Return success response with notes
    return res.status(200).json({
      return_code: 'SUCCESS',
      notes: notesResult.rows[0].organiser_notes || ''
    });
    
  } catch (error) {
    console.error('Error in get_notes route:', error);
    
    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
