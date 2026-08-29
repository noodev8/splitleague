/*
=======================================================================================================================================
API Route: update_notes
=======================================================================================================================================
Method: POST
Purpose: Allows a league organizer to update notes for a specific league member
=======================================================================================================================================
Request Payload:
{
  "league_id": 1,                     // integer, required - ID of the league
  "user_id": 2,                       // integer, required - ID of the user to update notes for
  "notes": "Player prefers evening games"  // string, required - Notes about the player (max 100 chars)
}

Success Response:
{
  "return_code": "SUCCESS"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"
"MISSING_FIELDS"
"NOTES_TOO_LONG"
"LEAGUE_NOT_FOUND"
"USER_NOT_IN_LEAGUE"
"NOT_ORGANIZER"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /update_notes
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract parameters from request body
    const { league_id, user_id, notes } = req.body;
    
    // Validate required fields
    if (!league_id || !user_id || notes === undefined) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League ID, user ID, and notes are required'
      });
    }
    
    // Validate notes length (max 100 characters)
    if (notes.length > 100) {
      return res.status(400).json({
        return_code: 'NOTES_TOO_LONG',
        message: 'Notes cannot exceed 100 characters'
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
    
    // Check if the requesting user is the league organizer
    const requestingUserId = req.userId;
    
    if (requestingUserId !== leagueCreator) {
      return res.status(403).json({
        return_code: 'NOT_ORGANIZER',
        message: 'Only the league organizer can update member notes'
      });
    }
    
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
    
    // Update the notes for the league member
    await pool.query(
      'UPDATE league_members SET organiser_notes = $1 WHERE league_id = $2 AND user_id = $3',
      [notes, league_id, user_id]
    );
    
    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS'
    });
    
  } catch (error) {
    console.error('Error in update_notes route:', error);
    
    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
