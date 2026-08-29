/*
=======================================================================================================================================
API Route: admin_stats
=======================================================================================================================================
Method: POST
Purpose: Returns the headline numbers for the admin dashboard - how many users and leagues
         exist, what stage the leagues are at, and whether anybody is actually using the app.
=======================================================================================================================================
Request Payload:
{}                                     // no payload, the admin token is the whole request

Success Response:
{
  "return_code": "SUCCESS",
  "users": {
    "real": 252,                       // integer, accounts people can log into
    "guest": 153,                      // integer, guest placeholder rows
    "verified": 180,                   // integer, real accounts with email_verified true
    "never_in_a_league": 40,           // integer, signed up and never created or joined one
    "new_30d": 7,                      // integer, real accounts created in the last 30 days
    "active_30d": 12                   // integer, real accounts that opened the app recently
  },
  "leagues": {
    "total": 192,                      // integer
    "setup": 133,                      // integer, no fixtures generated yet
    "in_play": 41,                     // integer, fixtures exist, not all played
    "complete": 18,                    // integer, fixtures exist and every one is played
    "archived": 0,                     // integer, active = false
    "organisers": 123,                 // integer, distinct users who have created a league
    "new_30d": 9                       // integer, leagues created in the last 30 days
  },
  "fixtures": {
    "total": 1116,                     // integer
    "played": 700,                     // integer
    "updated_7d": 4,                   // integer, score entered or changed in last 7 days
    "updated_30d": 16,                 // integer
    "updated_90d": 40                  // integer
  },
  "memberships": 398,                  // integer, rows in league_members
  "last_activity": "2026-08-29T20:48:59.127Z",   // string, most recent sign of life, or null
  "monthly": [                         // array, oldest first, last 12 months
    {
      "month": "2026-08",              // string, YYYY-MM
      "users": 7,                      // integer, real accounts created that month
      "guests": 11,                    // integer, guest rows created that month
      "leagues": 9                     // integer, leagues created that month
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

A note on what counts as a "user"
---------------------------------
Guests are rows in app_user with the literal email 'guest'. They are placeholders for people
in a league, not accounts, and counting them as users would inflate every number on this
dashboard by about 60 percent. Every figure here therefore splits them out explicitly rather
than quietly folding them in.

A note on league stage
----------------------
Setup / In play is the app's own state machine and it turns on one fact: whether fixtures
have been generated (see lib/helpers/league_stage.dart on the Flutter side). This route uses
the same rule so the admin tool never disagrees with the app.

"Complete" is an admin-only third state - fixtures exist and all of them are played. The app
has no such concept, but from here it is the difference between a league that finished and
one that stalled, and that is exactly what you want to see when deciding what to clear out.
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyAdmin = require('../middleware/admin_middleware');

// POST /admin_stats
router.post('/', verifyAdmin, async (req, res) => {
  try {
    // ---------------------------------------------------------------------------------
    // User counts
    //
    // The never_in_a_league figure is the interesting one: a real account that has never
    // created a league and never joined one. Those are people who downloaded the app,
    // signed up, and stopped.
    // ---------------------------------------------------------------------------------
    const usersQuery = pool.query(`
      SELECT
        count(*) FILTER (WHERE lower(email) <> 'guest')                    AS real,
        count(*) FILTER (WHERE lower(email) =  'guest')                    AS guest,
        count(*) FILTER (WHERE lower(email) <> 'guest' AND email_verified) AS verified,
        count(*) FILTER (WHERE lower(email) <> 'guest'
                           AND created_at > now() - interval '30 days')    AS new_30d,
        count(*) FILTER (WHERE lower(email) <> 'guest'
                           AND accessed   > now() - interval '30 days')    AS active_30d,
        count(*) FILTER (WHERE lower(email) <> 'guest'
                           AND NOT EXISTS (SELECT 1 FROM league         WHERE created_by = u.id)
                           AND NOT EXISTS (SELECT 1 FROM league_members WHERE user_id    = u.id)
                        )                                                  AS never_in_a_league
      FROM app_user u
    `);

    // ---------------------------------------------------------------------------------
    // League counts, bucketed by stage
    //
    // The lateral join counts each league's fixtures once, and the FILTER clauses then read
    // that one count three different ways. Doing it as three separate subqueries over
    // fixture would walk the table three times for no gain.
    // ---------------------------------------------------------------------------------
    const leaguesQuery = pool.query(`
      SELECT
        count(*)                                                          AS total,
        count(*) FILTER (WHERE f.total = 0)                               AS setup,
        count(*) FILTER (WHERE f.total > 0 AND f.played < f.total)        AS in_play,
        count(*) FILTER (WHERE f.total > 0 AND f.played = f.total)        AS complete,
        count(*) FILTER (WHERE l.active IS NOT TRUE)                      AS archived,
        count(DISTINCT l.created_by)                                      AS organisers,
        count(*) FILTER (WHERE l.created_at > now() - interval '30 days') AS new_30d
      FROM league l
      LEFT JOIN LATERAL (
        SELECT count(*) AS total, count(*) FILTER (WHERE played) AS played
        FROM fixture WHERE league_id = l.id
      ) f ON true
    `);

    // ---------------------------------------------------------------------------------
    // Fixture counts
    //
    // fixture.updated_at is the most reliable signal of real use anywhere in the database.
    // A row only moves when somebody enters or changes a score, which is the one thing
    // people do in this app that is not setup.
    // ---------------------------------------------------------------------------------
    const fixturesQuery = pool.query(`
      SELECT
        count(*)                                                        AS total,
        count(*) FILTER (WHERE played)                                  AS played,
        count(*) FILTER (WHERE updated_at > now() - interval '7 days')  AS updated_7d,
        count(*) FILTER (WHERE updated_at > now() - interval '30 days') AS updated_30d,
        count(*) FILTER (WHERE updated_at > now() - interval '90 days') AS updated_90d
      FROM fixture
    `);

    // Membership count - one number, but it is the join between the other two tables
    const membershipsQuery = pool.query(`SELECT count(*) AS total FROM league_members`);

    // ---------------------------------------------------------------------------------
    // The single most recent sign of life anywhere.
    //
    // Three different things count as activity and they live in three tables, so take the
    // latest of all three. If this timestamp is weeks old, nobody is using the app.
    // ---------------------------------------------------------------------------------
    const lastActivityQuery = pool.query(`
      SELECT GREATEST(
        (SELECT max(updated_at)    FROM fixture),
        (SELECT max(accessed)      FROM app_user),
        (SELECT max(last_accessed) FROM league_members)
      ) AS last_activity
    `);

    // ---------------------------------------------------------------------------------
    // Twelve months of signups and league creation.
    //
    // generate_series produces the months rather than the data, so a month in which
    // nothing happened still comes back as a row of zeros. Without that the chart would
    // silently close the gap and a dead month would look like it never existed.
    // ---------------------------------------------------------------------------------
    const monthlyQuery = pool.query(`
      WITH months AS (
        SELECT generate_series(
          date_trunc('month', now()) - interval '11 months',
          date_trunc('month', now()),
          interval '1 month'
        ) AS m
      )
      SELECT
        to_char(months.m, 'YYYY-MM') AS month,
        (SELECT count(*) FROM app_user
          WHERE lower(email) <> 'guest'
            AND date_trunc('month', created_at) = months.m) AS users,
        (SELECT count(*) FROM app_user
          WHERE lower(email) =  'guest'
            AND date_trunc('month', created_at) = months.m) AS guests,
        (SELECT count(*) FROM league
          WHERE date_trunc('month', created_at) = months.m) AS leagues
      FROM months
      ORDER BY months.m
    `);

    // Fire all six at once. They do not depend on each other, and the pool has room.
    const [users, leagues, fixtures, memberships, lastActivity, monthly] = await Promise.all([
      usersQuery, leaguesQuery, fixturesQuery, membershipsQuery, lastActivityQuery, monthlyQuery
    ]);

    // Postgres returns count() as bigint, and node-postgres hands bigint back as a *string*
    // so that large values cannot silently lose precision in a JavaScript number. Every
    // count here is comfortably small, so convert them to real numbers - otherwise the
    // dashboard ends up doing string arithmetic and rendering "252153" for a total.
    const toNumbers = (row) => {
      const out = {};
      for (const key of Object.keys(row)) out[key] = Number(row[key]);
      return out;
    };

    // The monthly rows are mixed - month is a string and must stay one, the rest are counts
    const monthlyRows = monthly.rows.map((row) => ({
      month: row.month,
      users: Number(row.users),
      guests: Number(row.guests),
      leagues: Number(row.leagues)
    }));

    return res.status(200).json({
      return_code: 'SUCCESS',
      users: toNumbers(users.rows[0]),
      leagues: toNumbers(leagues.rows[0]),
      fixtures: toNumbers(fixtures.rows[0]),
      memberships: Number(memberships.rows[0].total),
      last_activity: lastActivity.rows[0].last_activity,
      monthly: monthlyRows
    });
  } catch (error) {
    console.error('Error in admin_stats route:', error);

    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
