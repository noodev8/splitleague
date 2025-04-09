/*
=======================================================================================================================================
API Route: update_fixture_score
=======================================================================================================================================
Method: POST
Purpose: Updates the score for a specific fixture
=======================================================================================================================================
Request Payload:
{
  "fixture_id": 1,                      // integer - ID of the fixture to update
  "player_1_score": 3,                  // integer - Score for player 1
  "player_2_score": 2                   // integer - Score for player 2
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Fixture score updated successfully"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"
"FIXTURE_NOT_FOUND"
"INVALID_SCORE"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /update_fixture_score
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract data from request body
    const { fixture_id, player_1_score, player_2_score } = req.body;
    
    // Validate required fields
    if (!fixture_id || player_1_score === undefined || player_2_score === undefined) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Fixture ID and scores are required'
      });
    }
    
    // Validate scores are non-negative integers
    if (player_1_score < 0 || player_2_score < 0 || 
        !Number.isInteger(player_1_score) || !Number.isInteger(player_2_score)) {
      return res.status(400).json({
        return_code: 'INVALID_SCORE',
        message: 'Scores must be non-negative integers'
      });
    }
    
    // Get the fixture details
    const fixtureResult = await pool.query(
      `SELECT f.*, l.created_by as league_creator
       FROM fixture f
       JOIN league l ON f.league_id = l.id
       WHERE f.id = $1`,
      [fixture_id]
    );
    
    if (fixtureResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'FIXTURE_NOT_FOUND',
        message: 'Fixture not found'
      });
    }
    
    const fixture = fixtureResult.rows[0];
    const userId = req.userId;
    
    // Check if user is authorized to update the fixture
    // User must be either the league creator or one of the players
    if (fixture.league_creator != userId && 
        fixture.player_1_id != userId && 
        fixture.player_2_id != userId) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'You are not authorized to update this fixture'
      });
    }
    
    // Update the fixture with the scores
    await pool.query(
      `UPDATE fixture 
       SET player_1_score = $1, 
           player_2_score = $2, 
           played = true, 
           updated_at = NOW()
       WHERE id = $3`,
      [player_1_score, player_2_score, fixture_id]
    );
    
    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'Fixture score updated successfully'
    });
  } catch (error) {
    console.error('Error in update_fixture_score route:', error);
    
    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
