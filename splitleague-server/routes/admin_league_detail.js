/*
=======================================================================================================================================
API Route: admin_league_detail
=======================================================================================================================================
Method: POST
Purpose: Returns everything about one league - its organiser, its members, every fixture and
         the scoring configuration. This is the data behind the admin league detail page.
=======================================================================================================================================
Request Payload:
{
  "league_id": 42                      // integer, required
}

Success Response:
{
  "return_code": "SUCCESS",
  "league": {
    "id": 42,                          // integer
    "name": "Thursday Squash",         // string
    "public_code": "AB12CD",           // string, short join code, may be null
    "share_slug": "cc3q0nr55g",        // string, the slug in the public /l/<slug> link
    "allow_code_share": true,          // boolean
    "active": true,                    // boolean
    "created_at": "2026-03-04T...",    // string
    "organiser_id": 7,                 // integer, may be null
    "organiser_name": "Andreas",       // string, may be null
    "organiser_email": "a@b.com",      // string, may be null
    "stage": "in_play",                // string, "setup" | "in_play" | "complete"
    "last_activity": "2026-08-01T..."  // string, may be null
  },
  "members": [
    {
      "user_id": 7,                    // integer, may be null on a broken row
      "name": "Andreas",               // string, may be null
      "nickname": "Andy",              // string, may be null
      "email": "a@b.com",              // string, "guest" for a guest placeholder
      "is_guest": false,               // boolean
      "is_organiser": true,            // boolean, this member created the league
      "joined_at": "2026-03-04T...",   // string, may be null
      "last_accessed": "2026-08-01T...", // string, may be null
      "active": true,                  // boolean, false means they hid the league
      "organiser_notes": "paid",       // string, may be null
      "played": 5,                     // integer, fixtures of theirs marked played
      "fixtures": 8                    // integer, fixtures they appear in
    }
  ],
  "fixtures": [
    {
      "id": 900,                       // integer
      "player_1_id": 7,                // integer, may be null
      "player_1_name": "Andreas",      // string, may be null
      "player_2_id": 9,                // integer, may be null
      "player_2_name": "Dave (g)",     // string, may be null
      "scheduled_date": "2026-03-11",  // string, date only, may be null
      "played": true,                  // boolean
      "player_1_score": 3,             // integer, may be null
      "player_2_score": 1,             // integer, may be null
      "created_at": "2026-03-04T...",  // string, may be null
      "updated_at": "2026-03-12T..."   // string, may be null
    }
  ],
  "points": {                          // scoring config, null if the league has no row
    "points_for_win": 3,               // integer
    "points_for_draw": 1,              // integer
    "points_for_win_margin": 1,        // integer
    "points_for_close_loss": 1,        // integer
    "win_margin_threshold": 2,         // integer
    "play_each_other": 1,              // integer, how many times each pair meets
    "win_type": "sets"                 // string
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"NOT_FOUND"
"UNAUTHORIZED"
"FORBIDDEN"
"SERVER_ERROR"
=======================================================================================================================================

Note on the member list
-----------------------
Guests appear here alongside real accounts, and they should - a guest is a person in the
league, just one without an account. The is_guest flag marks them so the page can show them
differently, which matters when you are deciding whether a league is real: six members of
whom five are guests is one person and a notepad, not a group of six users.
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyAdmin = require('../middleware/admin_middleware');

// POST /admin_league_detail
router.post('/', verifyAdmin, async (req, res) => {
  try {
    // The league to look at
    const { league_id } = req.body;

    // It has to be there, and it has to be a number - anything else is a bad request rather
    // than a missing league
    if (league_id === undefined || league_id === null || isNaN(Number(league_id))) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'league_id is required'
      });
    }

    const leagueId = Number(league_id);

    // ---------------------------------------------------------------------------------
    // The league itself, with its organiser and derived stage.
    //
    // Same stage rule as everywhere else: no fixtures is setup, all played is complete.
    // ---------------------------------------------------------------------------------
    const leagueQuery = pool.query(`
      SELECT
        l.id,
        l.name,
        l.public_code,
        l.share_slug,
        l.allow_code_share,
        l.active,
        l.created_at,
        l.created_by                            AS organiser_id,
        organiser.name                          AS organiser_name,
        organiser.email                         AS organiser_email,
        CASE
          WHEN f.total = 0        THEN 'setup'
          WHEN f.played = f.total THEN 'complete'
          ELSE                         'in_play'
        END                                     AS stage,
        GREATEST(f.last_updated, m.last_seen)   AS last_activity
      FROM league l
      LEFT JOIN app_user organiser ON organiser.id = l.created_by
      LEFT JOIN LATERAL (
        SELECT count(*) AS total, count(*) FILTER (WHERE played) AS played,
               max(updated_at) AS last_updated
        FROM fixture WHERE league_id = l.id
      ) f ON true
      LEFT JOIN LATERAL (
        SELECT max(last_accessed) AS last_seen
        FROM league_members WHERE league_id = l.id
      ) m ON true
      WHERE l.id = $1
    `, [leagueId]);

    // ---------------------------------------------------------------------------------
    // The members.
    //
    // The lateral counts each member's own fixtures. A player can be in either column of
    // the fixture table, so the WHERE checks both - a member who only ever appears as
    // player 2 is still playing.
    // ---------------------------------------------------------------------------------
    const membersQuery = pool.query(`
      SELECT
        lm.user_id,
        u.name,
        u.nickname,
        u.email,
        (lower(u.email) = 'guest')              AS is_guest,
        (l.created_by = lm.user_id)             AS is_organiser,
        lm.joined_at,
        lm.last_accessed,
        lm.active,
        lm.organiser_notes,
        pf.total                                AS fixtures,
        pf.played                               AS played
      FROM league_members lm
      JOIN league l ON l.id = lm.league_id
      LEFT JOIN app_user u ON u.id = lm.user_id
      LEFT JOIN LATERAL (
        SELECT count(*) AS total, count(*) FILTER (WHERE played) AS played
        FROM fixture
        WHERE league_id = lm.league_id
          AND (player_1_id = lm.user_id OR player_2_id = lm.user_id)
      ) pf ON true
      WHERE lm.league_id = $1
      ORDER BY (l.created_by = lm.user_id) DESC, lm.joined_at ASC NULLS LAST
    `, [leagueId]);

    // ---------------------------------------------------------------------------------
    // Every fixture, with both players resolved to names.
    //
    // Two LEFT JOINs onto app_user under different aliases, because the two player columns
    // are two separate references to the same table. LEFT rather than inner so a fixture
    // whose player row has been deleted still shows up instead of silently vanishing.
    // ---------------------------------------------------------------------------------
    const fixturesQuery = pool.query(`
      SELECT
        f.id,
        f.player_1_id,
        p1.name                 AS player_1_name,
        f.player_2_id,
        p2.name                 AS player_2_name,
        f.scheduled_date,
        f.played,
        f.player_1_score,
        f.player_2_score,
        f.created_at,
        f.updated_at
      FROM fixture f
      LEFT JOIN app_user p1 ON p1.id = f.player_1_id
      LEFT JOIN app_user p2 ON p2.id = f.player_2_id
      WHERE f.league_id = $1
      ORDER BY f.scheduled_date ASC NULLS LAST, f.id ASC
    `, [leagueId]);

    // The scoring configuration. One row per league, but not guaranteed to exist.
    const pointsQuery = pool.query(`
      SELECT points_for_win, points_for_draw, points_for_win_margin,
             points_for_close_loss, win_margin_threshold, play_each_other, win_type
      FROM league_points
      WHERE league_id = $1
    `, [leagueId]);

    const [league, members, fixtures, points] = await Promise.all([
      leagueQuery, membersQuery, fixturesQuery, pointsQuery
    ]);

    // A league id that does not exist is a real answer, not an error
    if (league.rows.length === 0) {
      return res.status(404).json({
        return_code: 'NOT_FOUND',
        message: 'League not found'
      });
    }

    return res.status(200).json({
      return_code: 'SUCCESS',
      league: league.rows[0],

      // Turn the per-member bigint counts into numbers
      members: members.rows.map((row) => ({
        ...row,
        fixtures: Number(row.fixtures),
        played: Number(row.played)
      })),

      fixtures: fixtures.rows,

      // null rather than undefined when a league has no scoring row, so the page can test it
      points: points.rows.length > 0 ? points.rows[0] : null
    });
  } catch (error) {
    console.error('Error in admin_league_detail route:', error);

    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
