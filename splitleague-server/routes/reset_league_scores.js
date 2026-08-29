/*
=======================================================================================================================================
API Route: reset_league_scores
=======================================================================================================================================
Method: POST
Purpose: Resets all scores for fixtures in a league. Only the league creator (organizer) can reset scores.
         Sets played to false, both player scores to null, and updates the updated_at timestamp.
=======================================================================================================================================
Request Payload:
{
  "league_id": 1                     // integer, required - ID of the league to reset scores for
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "All scores have been reset successfully",
  "fixtures_reset": 10               // integer - Number of fixtures that were reset
}

Error Responses:
{
  "return_code": "MISSING_FIELDS",
  "message": "League ID is required"
}
{
  "return_code": "LEAGUE_NOT_FOUND",
  "message": "League not found"
}
{
  "return_code": "UNAUTHORIZED",
  "message": "Only the league creator can reset scores"
}
{
  "return_code": "NO_FIXTURES",
  "message": "No fixtures found for this league"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /reset_league_scores
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

    // Check if the league exists and if the user is the creator
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

    const league = leagueResult.rows[0];

    // Check if the user is the creator of the league
    if (league.created_by !== userId) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'Only the league creator can reset scores'
      });
    }

    // Check if there are any fixtures for this league
    const fixturesCountResult = await pool.query(
      'SELECT COUNT(*) FROM fixture WHERE league_id = $1',
      [league_id]
    );

    const fixturesCount = parseInt(fixturesCountResult.rows[0].count);
    if (fixturesCount === 0) {
      return res.status(404).json({
        return_code: 'NO_FIXTURES',
        message: 'No fixtures found for this league'
      });
    }

    // Reset all scores for fixtures in this league
    const resetResult = await pool.query(
      `UPDATE fixture 
       SET player_1_score = NULL, 
           player_2_score = NULL, 
           played = false, 
           updated_at = NOW() 
       WHERE league_id = $1 
       RETURNING id`,
      [league_id]
    );

    const fixturesReset = resetResult.rows.length;

    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'All scores have been reset successfully',
      fixtures_reset: fixturesReset
    });
  } catch (error) {
    console.error('Error resetting league scores:', error);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while resetting league scores'
    });
  }
});

module.exports = router;
