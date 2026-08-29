/*
=======================================================================================================================================
API Route: admin_users
=======================================================================================================================================
Method: POST
Purpose: Returns every row in app_user - real accounts and guest placeholders alike - with
         how many leagues each one runs and belongs to, and when they were last seen.
=======================================================================================================================================
Request Payload:
{}                                     // no payload - everybody is returned

Success Response:
{
  "return_code": "SUCCESS",
  "users": [
    {
      "id": 7,                         // integer
      "name": "Andreas",               // string
      "nickname": "Andy",              // string, may be null
      "email": "a@b.com",              // string, literally "guest" for a guest row
      "is_guest": false,               // boolean
      "email_verified": true,          // boolean, may be null
      "created_at": "2026-01-12T...",  // string, may be null
      "accessed": "2026-08-20T...",    // string, last time they opened the app, may be null
      "leagues_created": 3,            // integer, leagues where they are created_by
      "leagues_joined": 5,             // integer, rows in league_members
      "last_activity": "2026-08-20T...", // string, latest of accessed / visits / scores, or null
      "days_idle": 9                   // integer, days since last_activity, null if never seen
    }
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"
"FORBIDDEN"
"SERVER_ERROR"
=======================================================================================================================================

Guests are included on purpose
------------------------------
A guest is a row in app_user with the literal email 'guest' and a nickname like
"guest_Dave (g)". They are not accounts and must never log in, but they are people in a
league, and leaving them out of this list would make the user page disagree with the member
lists on every league page. The is_guest flag is there so the page can separate them, which
is the right place to make that decision.

Why leagues_created matters
---------------------------
It is the single most useful column here. It splits everyone who has signed up into the
people who actually organise something and the people who downloaded the app and stopped.
In production today 123 of 252 real accounts have created a league; the other half have not.
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyAdmin = require('../middleware/admin_middleware');

// POST /admin_users
router.post('/', verifyAdmin, async (req, res) => {
  try {
    // One row per user, with three lateral counts hanging off it.
    //
    // password_hash and the verification token columns are deliberately not selected. There
    // is no screen that needs them and no reason to move a password hash across the wire.
    const result = await pool.query(`
      SELECT
        u.id,
        u.name,
        u.nickname,
        u.email,
        (lower(u.email) = 'guest')                  AS is_guest,
        u.email_verified,
        u.created_at,
        u.accessed,

        created.total                               AS leagues_created,
        joined.total                                AS leagues_joined,

        -- Three separate things say "this person was here", and the latest of them wins:
        --   accessed       they opened the app
        --   last_seen      they opened a specific league
        --   last_scored    they entered or changed a score in a fixture they play in
        -- A user who only ever enters scores would otherwise look inactive.
        GREATEST(u.accessed, joined.last_seen, played.last_scored) AS last_activity,

        CASE
          WHEN GREATEST(u.accessed, joined.last_seen, played.last_scored) IS NULL THEN NULL
          ELSE floor(
            EXTRACT(EPOCH FROM (
              now() - GREATEST(u.accessed, joined.last_seen, played.last_scored)
            )) / 86400
          )
        END                                         AS days_idle

      FROM app_user u

      LEFT JOIN LATERAL (
        SELECT count(*) AS total FROM league WHERE created_by = u.id
      ) created ON true

      LEFT JOIN LATERAL (
        SELECT count(*) AS total, max(last_accessed) AS last_seen
        FROM league_members WHERE user_id = u.id
      ) joined ON true

      LEFT JOIN LATERAL (
        SELECT max(updated_at) AS last_scored
        FROM fixture
        WHERE player_1_id = u.id OR player_2_id = u.id
      ) played ON true

      ORDER BY u.created_at DESC NULLS LAST
    `);

    // bigint counts arrive as strings - see the note in admin_stats.js
    const users = result.rows.map((row) => ({
      ...row,
      leagues_created: Number(row.leagues_created),
      leagues_joined: Number(row.leagues_joined),
      days_idle: row.days_idle === null ? null : Number(row.days_idle)
    }));

    return res.status(200).json({
      return_code: 'SUCCESS',
      users: users
    });
  } catch (error) {
    console.error('Error in admin_users route:', error);

    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
