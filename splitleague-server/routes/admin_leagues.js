/*
=======================================================================================================================================
API Route: admin_leagues
=======================================================================================================================================
Method: POST
Purpose: Returns every league with its organiser, member counts, fixture progress, stage and
         last sign of activity. This is the data behind the admin Leagues table.
=======================================================================================================================================
Request Payload:
{}                                     // no payload - every league is returned

Success Response:
{
  "return_code": "SUCCESS",
  "leagues": [
    {
      "id": 42,                        // integer, league id
      "name": "Thursday Squash",       // string, league name
      "public_code": "AB12CD",         // string, the short join code typed into the app, may be null
      "share_slug": "cc3q0nr55g",      // string, the slug in the public /l/<slug> link
      "allow_code_share": true,        // boolean, whether the code may be shared onward
      "active": true,                  // boolean, false means archived from the admin tool
      "created_at": "2026-03-04T...",  // string, when the league was created
      "organiser_id": 7,               // integer, app_user.id of the creator, may be null
      "organiser_name": "Andreas",     // string, may be null if the creator row is gone
      "organiser_email": "a@b.com",    // string, may be null
      "members_total": 6,              // integer, rows in league_members
      "members_real": 4,               // integer, members that are real accounts
      "members_guest": 2,              // integer, members that are guest placeholders
      "fixtures_total": 15,            // integer
      "fixtures_played": 9,            // integer
      "stage": "in_play",              // string, "setup" | "in_play" | "complete"
      "last_activity": "2026-08-01T...", // string, latest fixture edit or member visit, or null
      "days_idle": 28                  // integer, days since last_activity, null if never active
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

Why this returns everything at once
-----------------------------------
There are 192 leagues in production and the row above is small. Sending the lot is a single
round trip of well under a megabyte, and it lets the admin table sort, filter and search
instantly in the browser with no paging, no query string state and no second endpoint.

If the league count ever reaches the low thousands this should grow a LIMIT and an OFFSET.
It is nowhere near that, and building paging now would be solving a problem that does not
exist at the cost of a worse tool today.

What "last activity" means
--------------------------
Two things count, and they answer different questions:

  fixture.updated_at         somebody entered or changed a score - the league is being played
  league_members.last_accessed  somebody opened the league - it is at least being looked at

A league that is still in setup has no fixtures at all, so without the second signal every
one of the 133 setup leagues would look equally dead. Taking the later of the two separates
"created last week and being worked on" from "abandoned in March".

league.created_at is deliberately NOT folded in. If it were, every league would look active
on the day it was made and days_idle could never exceed the league's own age - which is the
one number that makes a redundant league obvious.
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyAdmin = require('../middleware/admin_middleware');

// POST /admin_leagues
router.post('/', verifyAdmin, async (req, res) => {
  try {
    // One query, two lateral joins.
    //
    // The laterals run once per league and each one scans that league's rows only, which is
    // what you want here - the alternative is grouping the whole fixture and league_members
    // tables and joining the aggregates back, which reads far more for the same answer.
    const result = await pool.query(`
      SELECT
        l.id,
        l.name,
        l.public_code,
        l.share_slug,
        l.allow_code_share,
        l.active,
        l.created_at,

        -- The organiser. LEFT JOIN because created_by is nullable and the creator's account
        -- may since have been deleted; an orphaned league still has to appear in this list.
        l.created_by                                        AS organiser_id,
        organiser.name                                      AS organiser_name,
        organiser.email                                     AS organiser_email,

        -- Member counts, split the same way the rest of the tool splits them
        m.total                                             AS members_total,
        m.real                                              AS members_real,
        m.guest                                             AS members_guest,

        -- Fixture progress
        f.total                                             AS fixtures_total,
        f.played                                            AS fixtures_played,

        -- Stage, decided by the app's own rule: no fixtures means still setting up.
        -- "complete" is the admin-only extra state - every fixture has been played.
        CASE
          WHEN f.total = 0                THEN 'setup'
          WHEN f.played = f.total         THEN 'complete'
          ELSE                                 'in_play'
        END                                                 AS stage,

        -- The later of the two activity signals. GREATEST ignores nulls, so a league with
        -- fixtures but no visits still reports the fixture date, and one with neither
        -- correctly reports null rather than pretending to a date.
        GREATEST(f.last_updated, m.last_seen)               AS last_activity,

        -- Whole days since that moment, for the "how dead is this" column
        CASE
          WHEN GREATEST(f.last_updated, m.last_seen) IS NULL THEN NULL
          ELSE floor(
            EXTRACT(EPOCH FROM (now() - GREATEST(f.last_updated, m.last_seen))) / 86400
          )
        END                                                 AS days_idle

      FROM league l

      LEFT JOIN app_user organiser
        ON organiser.id = l.created_by

      LEFT JOIN LATERAL (
        SELECT
          count(*)                                              AS total,
          count(*) FILTER (WHERE lower(u.email) <> 'guest')      AS real,
          count(*) FILTER (WHERE lower(u.email) =  'guest')      AS guest,
          max(lm.last_accessed)                                  AS last_seen
        FROM league_members lm
        LEFT JOIN app_user u ON u.id = lm.user_id
        WHERE lm.league_id = l.id
      ) m ON true

      LEFT JOIN LATERAL (
        SELECT
          count(*)                          AS total,
          count(*) FILTER (WHERE played)    AS played,
          max(updated_at)                   AS last_updated
        FROM fixture
        WHERE league_id = l.id
      ) f ON true

      ORDER BY l.created_at DESC NULLS LAST
    `);

    // Convert the bigint counts from strings to numbers - see the note in admin_stats.js
    const leagues = result.rows.map((row) => ({
      id: row.id,
      name: row.name,
      public_code: row.public_code,
      share_slug: row.share_slug,
      allow_code_share: row.allow_code_share,
      active: row.active,
      created_at: row.created_at,
      organiser_id: row.organiser_id,
      organiser_name: row.organiser_name,
      organiser_email: row.organiser_email,
      members_total: Number(row.members_total),
      members_real: Number(row.members_real),
      members_guest: Number(row.members_guest),
      fixtures_total: Number(row.fixtures_total),
      fixtures_played: Number(row.fixtures_played),
      stage: row.stage,
      last_activity: row.last_activity,
      days_idle: row.days_idle === null ? null : Number(row.days_idle)
    }));

    return res.status(200).json({
      return_code: 'SUCCESS',
      leagues: leagues
    });
  } catch (error) {
    console.error('Error in admin_leagues route:', error);

    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
