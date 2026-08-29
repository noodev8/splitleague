/*
=======================================================================================================================================
API Route: admin_user_detail
=======================================================================================================================================
Method: POST
Purpose: Returns one user, the leagues they organise, the leagues they belong to, and their
         playing record. This is the data behind the admin user detail page.
=======================================================================================================================================
Request Payload:
{
  "user_id": 7                         // integer, required
}

Success Response:
{
  "return_code": "SUCCESS",
  "user": {
    "id": 7,                           // integer
    "name": "Andreas",                 // string
    "nickname": "Andy",                // string, may be null
    "email": "a@b.com",                // string, "guest" for a guest row
    "is_guest": false,                 // boolean
    "email_verified": true,            // boolean, may be null
    "created_at": "2026-01-12T...",    // string, may be null
    "accessed": "2026-08-20T..."       // string, may be null
  },
  "leagues": [                         // every league they organise or belong to
    {
      "id": 42,                        // integer
      "name": "Thursday Squash",       // string
      "created_at": "2026-03-04T...",  // string
      "is_organiser": true,            // boolean, they created this league
      "is_member": true,               // boolean, they have a league_members row
      "member_active": true,           // boolean, false means they hid it, null if not a member
      "joined_at": "2026-03-04T...",   // string, may be null
      "last_accessed": "2026-08-01T...", // string, may be null
      "stage": "in_play",              // string, "setup" | "in_play" | "complete"
      "members_total": 6,              // integer
      "fixtures_total": 15,            // integer
      "fixtures_played": 9             // integer
    }
  ],
  "record": {                          // their own playing record across all leagues
    "fixtures": 24,                    // integer, fixtures they appear in
    "played": 18,                      // integer, of those, marked played
    "last_scored": "2026-08-01T..."    // string, last time one of their fixtures moved, or null
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

Why organised and joined leagues come back in one list
------------------------------------------------------
They overlap almost completely - creating a league normally also makes you a member of it -
so returning two lists would show most leagues twice and invite the reader to double count.
One list with is_organiser and is_member flags says the same thing without the ambiguity,
and it also surfaces the odd case worth seeing: a league somebody created but is not a
member of.
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyAdmin = require('../middleware/admin_middleware');

// POST /admin_user_detail
router.post('/', verifyAdmin, async (req, res) => {
  try {
    const { user_id } = req.body;

    // Required, and must be a number
    if (user_id === undefined || user_id === null || isNaN(Number(user_id))) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'user_id is required'
      });
    }

    const userId = Number(user_id);

    // The user themselves. No password_hash, no verification token.
    const userQuery = pool.query(`
      SELECT id, name, nickname, email,
             (lower(email) = 'guest') AS is_guest,
             email_verified, created_at, accessed
      FROM app_user
      WHERE id = $1
    `, [userId]);

    // ---------------------------------------------------------------------------------
    // Every league they touch, whether as organiser or member.
    //
    // The FULL OUTER-ish behaviour is got with a plain WHERE across both relationships:
    // start from league, left join their membership row, and keep the row if either they
    // created it or that membership exists.
    // ---------------------------------------------------------------------------------
    const leaguesQuery = pool.query(`
      SELECT
        l.id,
        l.name,
        l.created_at,
        (l.created_by = $1)                     AS is_organiser,
        (lm.id IS NOT NULL)                     AS is_member,
        lm.active                               AS member_active,
        lm.joined_at,
        lm.last_accessed,
        CASE
          WHEN f.total = 0        THEN 'setup'
          WHEN f.played = f.total THEN 'complete'
          ELSE                         'in_play'
        END                                     AS stage,
        m.total                                 AS members_total,
        f.total                                 AS fixtures_total,
        f.played                                AS fixtures_played
      FROM league l
      LEFT JOIN league_members lm
        ON lm.league_id = l.id AND lm.user_id = $1
      LEFT JOIN LATERAL (
        SELECT count(*) AS total FROM league_members WHERE league_id = l.id
      ) m ON true
      LEFT JOIN LATERAL (
        SELECT count(*) AS total, count(*) FILTER (WHERE played) AS played
        FROM fixture WHERE league_id = l.id
      ) f ON true
      WHERE l.created_by = $1 OR lm.id IS NOT NULL
      ORDER BY l.created_at DESC NULLS LAST
    `, [userId]);

    // Their playing record. A player sits in either fixture column, so check both.
    const recordQuery = pool.query(`
      SELECT
        count(*)                        AS fixtures,
        count(*) FILTER (WHERE played)  AS played,
        max(updated_at)                 AS last_scored
      FROM fixture
      WHERE player_1_id = $1 OR player_2_id = $1
    `, [userId]);

    const [user, leagues, record] = await Promise.all([userQuery, leaguesQuery, recordQuery]);

    if (user.rows.length === 0) {
      return res.status(404).json({
        return_code: 'NOT_FOUND',
        message: 'User not found'
      });
    }

    return res.status(200).json({
      return_code: 'SUCCESS',
      user: user.rows[0],
      leagues: leagues.rows.map((row) => ({
        ...row,
        members_total: Number(row.members_total),
        fixtures_total: Number(row.fixtures_total),
        fixtures_played: Number(row.fixtures_played)
      })),
      record: {
        fixtures: Number(record.rows[0].fixtures),
        played: Number(record.rows[0].played),
        last_scored: record.rows[0].last_scored
      }
    });
  } catch (error) {
    console.error('Error in admin_user_detail route:', error);

    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
