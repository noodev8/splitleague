/*
=======================================================================================================================================
API Route: admin_cleanup
=======================================================================================================================================
Method: POST
Purpose: Finds leagues that look redundant and says, for each one, exactly why. This is the
         data behind the admin Cleanup page - the shortlist of things that could be cleared.
=======================================================================================================================================
Request Payload:
{
  "idle_days": 90,                     // integer, optional, default 90 - staleness threshold
  "min_age_days": 30                   // integer, optional, default 30 - ignore new leagues
}

Success Response:
{
  "return_code": "SUCCESS",
  "thresholds": {
    "idle_days": 90,                   // integer, the threshold actually used
    "min_age_days": 30                 // integer, the threshold actually used
  },
  "summary": {
    "candidates": 96,                  // integer, leagues matching at least one reason
    "empty": 71,                       // integer, never got off the ground
    "abandoned_setup": 12,             // integer, players added, fixtures never generated
    "stalled": 8,                      // integer, fixtures generated, no score ever entered
    "dormant": 5,                      // integer, was played, then went quiet
    "duplicate": 4,                    // integer, same name and organiser as another league
    "orphaned": 0                      // integer, the organiser's account no longer exists
  },
  "leagues": [
    {
      "id": 42,                        // integer
      "name": "Thursday Squash",       // string
      "organiser_id": 7,               // integer, may be null
      "organiser_name": "Andreas",     // string, may be null
      "created_at": "2026-03-04T...",  // string
      "age_days": 178,                 // integer, how old the league is
      "members_total": 1,              // integer
      "members_real": 1,               // integer
      "members_guest": 0,              // integer
      "fixtures_total": 0,             // integer
      "fixtures_played": 0,            // integer
      "stage": "setup",                // string, "setup" | "in_play" | "complete"
      "active": true,                  // boolean, false means already archived
      "last_activity": null,           // string, may be null
      "days_idle": null,               // integer, may be null
      "reasons": ["empty"],            // array of strings, every reason that applies
      "primary_reason": "empty"        // string, the strongest reason, for grouping
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

The reasons, and what each one actually means
---------------------------------------------
  empty            No fixtures and one member or fewer. Somebody tapped "create league" and
                   never came back. In production this is the biggest bucket by a distance -
                   88 of 192 leagues have one member or none. Safe to clear.

  abandoned_setup  Players were added but fixtures were never generated, and nobody has
                   opened it for idle_days. A real attempt that died before it started.

  stalled          Fixtures exist and not one score has ever been entered, and it has been
                   quiet for idle_days. The league started and then nothing happened.

  dormant          Fixtures were played, then it went quiet for twice idle_days. This is a
                   finished or abandoned season, and it is the one bucket where the data is
                   worth something to the people in it - be slower to delete these.

  duplicate        Another league has the same name and the same organiser. Usually the
                   result of copy_league, or of somebody tapping create twice.

  orphaned         created_by points at an account that no longer exists. Nobody can
                   administer this league from the app, ever.

Every league that matches at least one reason is returned, with all of its reasons. A league
in the "dormant" bucket may also be a duplicate, and you want to see both before deciding.

Nothing here deletes anything. This route only reports - admin_league_action.js is what acts.

Why new leagues are excluded
----------------------------
min_age_days keeps leagues younger than 30 days out of the list entirely. A league created
yesterday with no fixtures and one member is not redundant, it is a league created yesterday.
Without that floor the cleanup page would flag every new signup as garbage.
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyAdmin = require('../middleware/admin_middleware');

// POST /admin_cleanup
router.post('/', verifyAdmin, async (req, res) => {
  try {
    // Thresholds. The client may tune them, but bad or missing values fall back to the
    // defaults rather than erroring - this is a report, it should always render something.
    const idleDays = Number(req.body.idle_days) > 0 ? Number(req.body.idle_days) : 90;
    const minAgeDays = Number(req.body.min_age_days) >= 0 ? Number(req.body.min_age_days) : 30;

    // ---------------------------------------------------------------------------------
    // Gather every league with the facts each reason depends on, then let JavaScript apply
    // the rules.
    //
    // The rules could all be written as SQL predicates, but they would then be a wall of
    // CASE expressions that nobody can read six months from now, and the thresholds appear
    // in several of them. 192 rows is nothing to iterate over in Node, and the rules stay
    // legible as plain if statements below.
    //
    // The intervals are built with make_interval from a parameter rather than pasted into
    // the SQL string - a number is still a value, and values go in as parameters.
    // ---------------------------------------------------------------------------------
    const result = await pool.query(`
      SELECT
        l.id,
        l.name,
        l.active,
        l.created_at,
        l.created_by                              AS organiser_id,
        organiser.name                            AS organiser_name,

        -- Does the creator's account still exist? created_by being null counts as orphaned
        -- too - the league has no owner either way.
        (l.created_by IS NULL OR organiser.id IS NULL) AS is_orphaned,

        floor(EXTRACT(EPOCH FROM (now() - l.created_at)) / 86400) AS age_days,

        m.total                                   AS members_total,
        m.real                                    AS members_real,
        m.guest                                   AS members_guest,

        f.total                                   AS fixtures_total,
        f.played                                  AS fixtures_played,

        CASE
          WHEN f.total = 0        THEN 'setup'
          WHEN f.played = f.total THEN 'complete'
          ELSE                         'in_play'
        END                                       AS stage,

        GREATEST(f.last_updated, m.last_seen)     AS last_activity,

        CASE
          WHEN GREATEST(f.last_updated, m.last_seen) IS NULL THEN NULL
          ELSE floor(
            EXTRACT(EPOCH FROM (now() - GREATEST(f.last_updated, m.last_seen))) / 86400
          )
        END                                       AS days_idle,

        -- Is there another league with the same name under the same organiser? Names are
        -- compared case- and space-insensitively, because "Thursday Squash" and
        -- "thursday squash " are the same league to the person who made both.
        EXISTS (
          SELECT 1 FROM league other
          WHERE other.id <> l.id
            AND other.created_by = l.created_by
            AND l.created_by IS NOT NULL
            AND lower(btrim(other.name)) = lower(btrim(l.name))
        )                                         AS is_duplicate

      FROM league l
      LEFT JOIN app_user organiser ON organiser.id = l.created_by
      LEFT JOIN LATERAL (
        SELECT count(*) AS total,
               count(*) FILTER (WHERE lower(u.email) <> 'guest') AS real,
               count(*) FILTER (WHERE lower(u.email) =  'guest') AS guest,
               max(lm.last_accessed) AS last_seen
        FROM league_members lm
        LEFT JOIN app_user u ON u.id = lm.user_id
        WHERE lm.league_id = l.id
      ) m ON true
      LEFT JOIN LATERAL (
        SELECT count(*) AS total, count(*) FILTER (WHERE played) AS played,
               max(updated_at) AS last_updated
        FROM fixture WHERE league_id = l.id
      ) f ON true

      -- Anything younger than the floor is not a candidate, whatever else is true of it
      WHERE l.created_at < now() - make_interval(days => $1)

      ORDER BY l.created_at ASC
    `, [minAgeDays]);

    // ---------------------------------------------------------------------------------
    // Apply the rules.
    //
    // A league collects every reason that fits. primary_reason is the first match in the
    // order below, which runs from "certainly junk" to "was real once" - so a dormant
    // league that is also a duplicate is grouped as dormant, and gets the more careful
    // treatment the stronger claim deserves.
    // ---------------------------------------------------------------------------------
    const candidates = [];
    const summary = {
      candidates: 0, empty: 0, abandoned_setup: 0,
      stalled: 0, dormant: 0, duplicate: 0, orphaned: 0
    };

    for (const row of result.rows) {
      const membersTotal   = Number(row.members_total);
      const fixturesTotal  = Number(row.fixtures_total);
      const fixturesPlayed = Number(row.fixtures_played);
      const daysIdle       = row.days_idle === null ? null : Number(row.days_idle);

      // "Quiet" means either it has been idle past the threshold, or it has never shown a
      // single sign of activity at all. A null last_activity is the strongest quiet there is,
      // and treating null as "not idle" would hide the very worst cases.
      const quiet      = (days) => daysIdle === null || daysIdle >= days;
      const reasons    = [];

      // Never got off the ground: nothing generated, nobody in it but the creator
      if (fixturesTotal === 0 && membersTotal <= 1) {
        reasons.push('empty');
      }

      // Players were added, fixtures never were, and it has gone quiet
      if (fixturesTotal === 0 && membersTotal > 1 && quiet(idleDays)) {
        reasons.push('abandoned_setup');
      }

      // Fixtures exist, not one score has ever been entered, and it has gone quiet
      if (fixturesTotal > 0 && fixturesPlayed === 0 && quiet(idleDays)) {
        reasons.push('stalled');
      }

      // It was genuinely played, then stopped. Twice the threshold, because there is real
      // data in here and a season can sit between rounds for months.
      if (fixturesPlayed > 0 && quiet(idleDays * 2)) {
        reasons.push('dormant');
      }

      // Same name, same organiser, different league
      if (row.is_duplicate) {
        reasons.push('duplicate');
      }

      // Nobody owns it
      if (row.is_orphaned) {
        reasons.push('orphaned');
      }

      // No reason applies - this league is fine, leave it alone
      if (reasons.length === 0) continue;

      // Strongest-claim-first ordering for the grouping label
      const order = ['dormant', 'stalled', 'abandoned_setup', 'empty', 'orphaned', 'duplicate'];
      const primary = order.find((reason) => reasons.includes(reason));

      for (const reason of reasons) summary[reason] += 1;
      summary.candidates += 1;

      candidates.push({
        id: row.id,
        name: row.name,
        organiser_id: row.organiser_id,
        organiser_name: row.organiser_name,
        created_at: row.created_at,
        age_days: Number(row.age_days),
        members_total: membersTotal,
        members_real: Number(row.members_real),
        members_guest: Number(row.members_guest),
        fixtures_total: fixturesTotal,
        fixtures_played: fixturesPlayed,
        stage: row.stage,
        active: row.active,
        last_activity: row.last_activity,
        days_idle: daysIdle,
        reasons: reasons,
        primary_reason: primary
      });
    }

    return res.status(200).json({
      return_code: 'SUCCESS',
      thresholds: { idle_days: idleDays, min_age_days: minAgeDays },
      summary: summary,
      leagues: candidates
    });
  } catch (error) {
    console.error('Error in admin_cleanup route:', error);

    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
