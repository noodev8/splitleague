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
      "id": 1,                            // integer - Database row ID
      "league_id": 1,                     // integer - League ID (matches id)
      "name": "Premier League 2025",      // string - League name
      "created_by": 123,                  // integer - User ID of creator
      "public_code": "1234",              // string - Unique 4-digit code for joining the league
      "share_slug": "7jwpbsz5ym",         // string - Permanent identifier for the shared link /l/<slug>
      "active": true,                     // boolean - League active status
      "start_date": "2025-05-01",         // date - Start date (may be null)
      "end_date": "2025-08-31",           // date - End date (may be null)
      "created_at": "2025-04-06T12:00:00.000Z", // timestamp - Creation date
      "is_creator": true,                 // boolean - Whether the user created this league
      "joined_at": "2025-04-06T12:00:00.000Z", // timestamp - When the user joined the league
      "last_accessed": "2025-04-10T15:30:00.000Z", // timestamp - When the user last accessed the league
      "player_count": 10,                 // integer - Number of players in the league
      "has_fixtures": false,              // boolean - true once fixtures have been generated.
                                          //           This is the league's stage: false = still
                                          //           setting up, true = in play. The app reads
                                          //           it to label the league and to decide which
                                          //           screen to open, so it must always be sent.
      "unplayed_count": 3,                // integer - fixtures in this league with no result yet.
                                          //           Always 0 while has_fixtures is false. The
                                          //           dashboard turns this into the line under the
                                          //           league name - "3 results to enter" - which is
                                          //           what makes the list read as a to-do rather
                                          //           than a list of names. An older app that does
                                          //           not know the field simply shows the player
                                          //           count instead, so this is safe to deploy on
                                          //           its own.
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

    // Query to get all leagues the user is a member of (including leagues they created but haven't hidden)
    const result = await pool.query(`
      SELECT
        l.id as league_id,  -- Explicitly name this as league_id
        l.*,
        CASE WHEN l.created_by = $1 THEN true ELSE false END as is_creator,
        lm.joined_at,
        lm.last_accessed,
        lm.active,
        lp.*,
        (
          SELECT COUNT(*)
          FROM league_members lm2
          WHERE lm2.league_id = l.id AND lm2.active = true
        ) as player_count,
        -- The league's stage in one boolean. A league with no fixtures is still being set
        -- up; the moment fixtures exist it is in play. EXISTS rather than a count because
        -- we only ever ask the yes/no question.
        (
          SELECT EXISTS (
            SELECT 1 FROM fixture f WHERE f.league_id = l.id
          )
        ) as has_fixtures,
        -- How many games in this league still have no result.
        --
        -- This is the one number that tells a user whether a league wants anything from
        -- them right now, so it is what the dashboard card says underneath the name.
        -- Counted here rather than derived in the app because the app would otherwise
        -- have to fetch every fixture of every league just to draw the list.
        (
          SELECT COUNT(*)
          FROM fixture f
          WHERE f.league_id = l.id AND COALESCE(f.played, false) = false
        ) as unplayed_count
      FROM league l
      LEFT JOIN league_members lm ON l.id = lm.league_id AND lm.user_id = $1
      LEFT JOIN league_points lp ON l.id = lp.league_id
      WHERE (l.created_by = $1 AND NOT EXISTS (
              SELECT 1 FROM league_members
              WHERE league_id = l.id AND user_id = $1 AND active = false
            ))
            OR (lm.user_id = $1 AND lm.active = true)
    `, [userId]);

    // Process the results to format them properly
    const leagues = [];
    const processedLeagueIds = new Set();

    for (const row of result.rows) {
      // Skip if we've already processed this league
      if (processedLeagueIds.has(row.league_id)) {
        continue;
      }

      // Mark this league as processed
      processedLeagueIds.add(row.league_id);

      // Format the league data
      const league = {
        id: row.id,
        league_id: row.league_id,  // This will now be different from id
        name: row.name,
        created_by: row.created_by,
        public_code: row.public_code,
        // The permanent identifier for this league's shared link, /l/<slug>. The app builds
        // every share message from this, so it has to travel with the league everywhere.
        share_slug: row.share_slug,
        active: row.active,

        created_at: row.created_at,
        is_creator: row.is_creator,
        joined_at: row.joined_at,
        last_accessed: row.last_accessed,
        player_count: parseInt(row.player_count),
        has_fixtures: row.has_fixtures,
        unplayed_count: parseInt(row.unplayed_count),
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
