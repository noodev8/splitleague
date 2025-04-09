/*
=======================================================================================================================================
API Route: get_user_leagues
=======================================================================================================================================
Method: POST
Purpose: Retrieves all leagues that the authenticated user is a member of, including leagues they created.
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
      "id": 1,                            // integer - Unique league ID
      "name": "Premier League 2025",      // string - League name
      "created_by": 123,                  // integer - User ID of creator
      "public_code": "1234",              // string - Unique 4-digit code for joining the league
      "active": true,                     // boolean - League active status
      "start_date": "2025-05-01",         // date - Start date (may be null)
      "end_date": "2025-08-31",           // date - End date (may be null)
      "created_at": "2025-04-06T12:00:00.000Z", // timestamp - Creation date
      "is_creator": true,                 // boolean - Whether the user created this league
      "joined_at": "2025-04-06T12:00:00.000Z", // timestamp - When the user joined the league
      "player_count": 10,                 // integer - Number of players in the league
      "points": {
        "points_for_win": 3,              // integer - Points for win
        "points_for_draw": 1,             // integer - Points for draw
        "points_for_win_margin": 1,       // integer - Points for win margin
        "points_for_close_loss": 1,       // integer - Points for close loss
        "win_margin_threshold": 15        // integer - Win margin threshold
      }
    }
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /get_user_leagues
router.post('/', verifyToken, async (req, res) => {
  try {
    // Get the user ID from the authenticated token
    const userId = req.userId;
    
    // Query to get all leagues the user is a member of (including leagues they created)
    const result = await pool.query(`
      SELECT 
        l.*,
        CASE WHEN l.created_by = $1 THEN true ELSE false END as is_creator,
        lm.joined_at,
        lp.*,
        (
          SELECT COUNT(*) 
          FROM league_members lm2 
          WHERE lm2.league_id = l.id
        ) + 1 as player_count  -- Add 1 to include the creator
      FROM league l
      LEFT JOIN league_members lm ON l.id = lm.league_id AND lm.user_id = $1
      LEFT JOIN league_points lp ON l.id = lp.league_id
      WHERE l.created_by = $1 OR lm.user_id = $1
    `, [userId]);
    
    // Process the results to format them properly
    const leagues = [];
    const processedLeagueIds = new Set();
    
    for (const row of result.rows) {
      // Skip if we've already processed this league
      if (processedLeagueIds.has(row.id)) {
        continue;
      }
      
      // Mark this league as processed
      processedLeagueIds.add(row.id);
      
      // Format the league data
      const league = {
        id: row.id,
        name: row.name,
        created_by: row.created_by,
        public_code: row.public_code,
        active: row.active,
        start_date: row.start_date,
        end_date: row.end_date,
        created_at: row.created_at,
        is_creator: row.is_creator,
        joined_at: row.joined_at,
        player_count: parseInt(row.player_count),  // Add player count to response
        points: {
          points_for_win: row.points_for_win,
          points_for_draw: row.points_for_draw,
          points_for_win_margin: row.points_for_win_margin,
          points_for_close_loss: row.points_for_close_loss,
          win_margin_threshold: row.win_margin_threshold
        }
      };
      
      leagues.push(league);
    }
    
    // Return success response with leagues data
    return res.status(200).json({
      return_code: 'SUCCESS',
      leagues: leagues
    });
  } catch (error) {
    console.error('Error in get_user_leagues route:', error);
    
    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
