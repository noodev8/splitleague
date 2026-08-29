/*
=======================================================================================================================================
API Route: update_fixture_score
=======================================================================================================================================
Method: POST
Purpose: Updates the score for a specific fixture based on the league's win_type
=======================================================================================================================================
Request Payload:
{
  "fixture_id": 1,                      // integer - ID of the fixture to update
  "player_1_score": 3,                  // integer - Score for player 1 (required for PTS win_type)
  "player_2_score": 2,                  // integer - Score for player 2 (required for PTS win_type)
  "result": "WIN_1"                     // string - Match result: "WIN_1", "WIN_2", or "DRAW" (required for WIN or WDL win_type)
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
"MISSING_FIELDS"
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
    const { fixture_id, player_1_score, player_2_score, result } = req.body;

    // Validate fixture_id is provided
    if (!fixture_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Fixture ID is required'
      });
    }

    // Get the fixture details and league win_type
    const fixtureResult = await pool.query(
      `SELECT f.*, l.created_by as league_creator, lp.win_type
       FROM fixture f
       JOIN league l ON f.league_id = l.id
       JOIN league_points lp ON f.league_id = lp.league_id
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

    // Get the win_type from the fixture result
    const win_type = fixture.win_type || 'PTS';

    // Validate the request based on win_type
    let p1Score = null;
    let p2Score = null;

    if (win_type === 'PTS') {
      // For PTS win_type, we need actual scores
      if (player_1_score === undefined || player_2_score === undefined) {
        return res.status(400).json({
          return_code: 'MISSING_FIELDS',
          message: 'Player scores are required for points-based leagues'
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

      p1Score = player_1_score;
      p2Score = player_2_score;
    } else if (win_type === 'WIN' || win_type === 'WDL') {
      // For WIN or WDL win_type, we need the result
      if (!result) {
        return res.status(400).json({
          return_code: 'MISSING_FIELDS',
          message: 'Match result is required for win-based leagues'
        });
      }

      // Validate result is one of the allowed values
      if (!['WIN_1', 'WIN_2', 'DRAW'].includes(result)) {
        return res.status(400).json({
          return_code: 'INVALID_SCORE',
          message: 'Result must be WIN_1, WIN_2, or DRAW'
        });
      }

      // For WIN win_type, DRAW is not allowed
      if (win_type === 'WIN' && result === 'DRAW') {
        return res.status(400).json({
          return_code: 'INVALID_SCORE',
          message: 'Draw is not allowed in win-only leagues'
        });
      }

      // Convert result to scores
      if (result === 'WIN_1') {
        p1Score = 1;
        p2Score = 0;
      } else if (result === 'WIN_2') {
        p1Score = 0;
        p2Score = 1;
      } else if (result === 'DRAW') {
        p1Score = 1;
        p2Score = 1;
      }
    }

    // Update the fixture with the scores
    await pool.query(
      `UPDATE fixture
       SET player_1_score = $1,
           player_2_score = $2,
           played = true,
           updated_at = NOW()
       WHERE id = $3`,
      [p1Score, p2Score, fixture_id]
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
