/*
=======================================================================================================================================
API Route: get_league_info
=======================================================================================================================================
Method: POST
Purpose: Retrieves detailed information about a specific league by its ID. Only accessible to league members or the creator.
=======================================================================================================================================
Request Payload:
{
  "league_id": 1                      // integer, required - The unique ID of the league
}

Success Response:
{
  "return_code": "SUCCESS",
  "league": {
    "id": 1,                          // integer - Unique league ID
    "name": "Premier League 2025",    // string - League name
    "created_by": 123,                // integer - User ID of creator
    "public_code": "1234",            // string - Unique 4-digit code for joining the league
    "active": true,                   // boolean - League active status
    "start_date": "2025-05-01",       // date - Start date (may be null)
    "end_date": "2025-08-31",         // date - End date (may be null)
    "created_at": "2025-04-06T12:00:00.000Z", // timestamp - Creation date
    "is_creator": true,               // boolean - Whether the user created this league
    "points_for_win": 3,              // integer - Points for win
    "points_for_draw": 1,             // integer - Points for draw
    "points_for_win_margin": 1,       // integer - Points for win margin
    "points_for_close_loss": 1,       // integer - Points for close loss
    "win_margin_threshold": 15,       // integer - Win margin threshold
    "play_each_other": 2,             // integer - Number of times each player plays each other
    "win_type": "POINTS"              // string - Type of win calculation (e.g., "POINTS", "GAMES")
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"LEAGUE_NOT_FOUND"
"NOT_AUTHORIZED"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /get_league_info
router.post('/', verifyToken, async (req, res) => {
  try {
    // Get the user ID from the authenticated token
    const userId = req.userId;

    // Get the league_id from the request body
    const { league_id } = req.body;

    // Check if league_id is provided
    if (!league_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League ID is required'
      });
    }

    // First, get the basic league information and check if user is authorized to view it
    // We need to check if the user is either:
    // 1. The creator of the league, or
    // 2. A member of the league
    const leagueResult = await pool.query(`
      SELECT
        l.id,
        l.name,
        l.created_by,
        l.public_code,
        l.active,
        l.start_date,
        l.end_date,
        l.created_at,
        CASE WHEN l.created_by = $1 THEN true ELSE false END as is_creator,
        (
          SELECT COUNT(*) > 0
          FROM league_members lm
          WHERE lm.league_id = l.id AND lm.user_id = $1
        ) as is_member
      FROM
        league l
      WHERE
        l.id = $2
    `, [userId, league_id]);

    // Check if the league exists
    if (leagueResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found'
      });
    }

    // Get the league data from the result
    const leagueData = leagueResult.rows[0];

    // Check if the user is authorized to view this league
    // User must be either the creator or a member
    if (!leagueData.is_creator && !leagueData.is_member) {
      return res.status(403).json({
        return_code: 'NOT_AUTHORIZED',
        message: 'You are not authorized to view this league'
      });
    }

    // Now get the league points information
    const pointsResult = await pool.query(`
      SELECT
        points_for_win,
        points_for_draw,
        points_for_win_margin,
        points_for_close_loss,
        win_margin_threshold,
        play_each_other,
        win_type
      FROM
        league_points
      WHERE
        league_id = $1
    `, [league_id]);

    // Log the query results for debugging
    console.log('League data retrieved:', leagueData);
    console.log('Points data retrieved:', pointsResult.rows[0] || 'No points data found');

    // If no points data exists, we'll create a record with default values
    let pointsData;
    if (pointsResult.rows.length === 0) {
      console.log('No league_points record found, creating default values');

      // Insert default values into league_points table
      const defaultPointsResult = await pool.query(`
        INSERT INTO league_points
        (league_id, points_for_win, points_for_draw, points_for_win_margin,
         points_for_close_loss, win_margin_threshold, play_each_other, win_type)
        VALUES ($1, 3, 1, 0, 0, 0, 1, 'POINTS')
        RETURNING *
      `, [league_id]);

      pointsData = defaultPointsResult.rows[0];
      console.log('Created default points data:', pointsData);
    } else {
      pointsData = pointsResult.rows[0];
    }

    // Note: Authorization checks have been moved up in the code

    // Format the league data for the response
    // Combine data from both queries
    const league = {
      id: leagueData.id,
      name: leagueData.name,
      created_by: leagueData.created_by,
      public_code: leagueData.public_code,
      active: leagueData.active,
      start_date: leagueData.start_date,
      end_date: leagueData.end_date,
      created_at: leagueData.created_at,
      is_creator: leagueData.is_creator,

      // Include all fields from the league_points table
      points_for_win: pointsData.points_for_win,
      points_for_draw: pointsData.points_for_draw,
      points_for_win_margin: pointsData.points_for_win_margin,
      points_for_close_loss: pointsData.points_for_close_loss,
      win_margin_threshold: pointsData.win_margin_threshold,
      play_each_other: pointsData.play_each_other,
      win_type: pointsData.win_type
    };

    // Return success response with league data
    return res.status(200).json({
      return_code: 'SUCCESS',
      league: league
    });

  } catch (error) {
    // Log the error for debugging
    console.error('Error in get_league_info route:', error);

    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
