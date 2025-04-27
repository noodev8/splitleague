/*
=======================================================================================================================================
API Route: get_league_fixtures
=======================================================================================================================================
Method: POST
Purpose: Retrieves all fixtures for a specific league
=======================================================================================================================================
Request Payload:
{
  "league_id": 1                        // integer - ID of the league to get fixtures for
}

Success Response:
{
  "return_code": "SUCCESS",
  "fixtures": [
    {
      "id": 1,                          // integer - Unique fixture ID
      "league_id": 1,                   // integer - League ID
      "player_1_id": 2,                 // integer - Player 1 ID
      "player_2_id": 3,                 // integer - Player 2 ID
      "player_1_name": "John Doe",      // string - Player 1 name
      "player_2_name": "Jane Smith",    // string - Player 2 name
      "scheduled_date": null,           // date - Scheduled date (null if not scheduled)
      "played": false,                  // boolean - Whether the fixture has been played
      "player_1_score": null,           // integer - Player 1 score (null if not played)
      "player_2_score": null,           // integer - Player 2 score (null if not played)
      "created_at": "2025-04-10T12:00:00.000Z", // timestamp - Creation date
      "win_type": "PTS",                // string - League win type ("PTS", "WIN", or "WDL")
      "is_creator": true                // boolean - Whether the current user is the league creator
    }
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"
"LEAGUE_NOT_FOUND"
"NO_FIXTURES_FOUND"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /get_league_fixtures
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract league ID from request body and convert to integer
    const league_id = parseInt(req.body.league_id);

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

    // Get all fixtures for the league with player names and league settings
    const fixturesResult = await pool.query(
      `SELECT
        f.*,
        p1.name as player_1_name,
        p1.nickname as player_1_nickname,
        p2.name as player_2_name,
        p2.nickname as player_2_nickname,
        COALESCE(lp.win_type, 'PTS') as win_type,
        lp.win_margin_threshold,
        lp.points_for_win_margin,
        lp.points_for_close_loss,
        CASE WHEN l.created_by = $2 THEN true ELSE false END as is_creator
       FROM
        fixture f
       JOIN
        app_user p1 ON f.player_1_id = p1.id
       JOIN
        app_user p2 ON f.player_2_id = p2.id
       LEFT JOIN
        league_points lp ON f.league_id = lp.league_id
       JOIN
        league l ON f.league_id = l.id
       WHERE
        f.league_id = $1
       ORDER BY
        f.scheduled_date NULLS FIRST,
        f.id ASC`,
      [league_id, userId]
    );

    if (fixturesResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'NO_FIXTURES_FOUND',
        message: 'No fixtures found for this league'
      });
    }

    // Debug log to check if is_creator flag is being set
    console.log('User ID:', userId);
    console.log('First fixture is_creator:', fixturesResult.rows[0].is_creator);

    // Return success response with fixtures data
    return res.status(200).json({
      return_code: 'SUCCESS',
      fixtures: fixturesResult.rows
    });
  } catch (error) {
    console.error('Error in get_league_fixtures route:', error);

    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
