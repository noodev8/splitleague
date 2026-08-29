/*
=======================================================================================================================================
API Route: admin_league_action
=======================================================================================================================================
Method: POST
Purpose: Archives, restores or permanently deletes one or more leagues from the admin tool.
         This is the only admin route that writes to the database.
=======================================================================================================================================
Request Payload:
{
  "action": "archive",                 // string, required - "archive" | "restore" | "delete"
  "league_ids": [42, 43],              // array of integers, required (or use league_id)
  "league_id": 42,                     // integer, optional shorthand for a single league
  "confirm": true                      // boolean, required for "delete" only
}

Success Response:
{
  "return_code": "SUCCESS",
  "action": "delete",                  // string, the action performed
  "affected": [                        // array, one entry per league acted on
    {
      "id": 42,                        // integer
      "name": "Thursday Squash",       // string, captured before deletion
      "fixtures_deleted": 15,          // integer, delete only
      "members_deleted": 6,            // integer, delete only
      "guests_deleted": 2              // integer, delete only - see the note below
    }
  ],
  "not_found": [99]                    // array of integers, ids that did not exist
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_ACTION"
"NOT_CONFIRMED"
"NOTHING_TO_DO"
"UNAUTHORIZED"
"FORBIDDEN"
"SERVER_ERROR"
=======================================================================================================================================

Archive versus delete
---------------------
Archiving sets league.active = false. Nothing is destroyed and it can be undone with
"restore". Reach for this first - it is the reversible option, and for a league that turns
out to have been someone's live season it is the difference between an apology and a
disaster.

Deleting removes the league and everything hanging off it, permanently, with no undo. It
requires confirm: true in the payload as well as whatever the UI asks, because this endpoint
sits on the public API and a mistyped curl should not be able to destroy a season.

Note that nothing in the Flutter app currently reads league.active - it is written by this
route and read by the admin tool. An archived league therefore still appears in the app for
now. Treat archiving as "marked for clearing", not as "hidden from users". Making the app
honour it means adding "AND l.active" to get_user_leagues.js and is a separate change.

What deleting a league takes with it
------------------------------------
In order, inside one transaction:

  fixture          every fixture in the league
  league_points    the scoring configuration, one row
  league_members   every membership
  guest users      app_user rows for guests whose ONLY membership was this league
  league           the league itself

That fourth step needs explaining. Guests are rows in app_user that exist purely as
placeholders for people in a league. Delete the league and leave them behind and they become
permanently unreachable rows that no screen can ever show - the 153 guest rows in production
would only ever grow. So a guest is removed with the league, but only when this was the last
league they belonged to; a guest who somehow appears in two leagues is left alone.

Real accounts are never touched. Deleting a league must never delete a person who can log in,
however few leagues they have left afterwards.
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyAdmin = require('../middleware/admin_middleware');

// The actions this route will perform. Anything else is rejected.
const VALID_ACTIONS = ['archive', 'restore', 'delete'];

// POST /admin_league_action
router.post('/', verifyAdmin, async (req, res) => {
  // A client is taken from the pool rather than using pool.query directly, because a delete
  // spans five statements that must all succeed or all fail together.
  const client = await pool.connect();

  try {
    const { action, league_ids, league_id, confirm } = req.body;

    // The action has to be one we know about
    if (!action || !VALID_ACTIONS.includes(action)) {
      return res.status(400).json({
        return_code: 'INVALID_ACTION',
        message: 'action must be one of: ' + VALID_ACTIONS.join(', ')
      });
    }

    // Accept either a list or a single id, and normalise to a list of clean integers.
    // Anything that is not a number is dropped here rather than reaching the query.
    const rawIds = Array.isArray(league_ids)
      ? league_ids
      : (league_id !== undefined && league_id !== null ? [league_id] : []);

    const ids = rawIds
      .map((value) => Number(value))
      .filter((value) => Number.isInteger(value) && value > 0);

    if (ids.length === 0) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'league_ids (or league_id) is required'
      });
    }

    // Deleting needs the extra explicit confirmation
    if (action === 'delete' && confirm !== true) {
      return res.status(400).json({
        return_code: 'NOT_CONFIRMED',
        message: 'delete requires confirm: true'
      });
    }

    await client.query('BEGIN');

    // Which of the requested ids actually exist. Names are captured now because after a
    // delete there is nothing left to report back with.
    const existing = await client.query(
      `SELECT id, name FROM league WHERE id = ANY($1::int[])`,
      [ids]
    );

    const foundIds = existing.rows.map((row) => row.id);
    const notFound = ids.filter((id) => !foundIds.includes(id));

    // Every id was bogus - nothing to do, and it is worth saying so plainly
    if (foundIds.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        return_code: 'NOTHING_TO_DO',
        message: 'None of those leagues exist',
        not_found: notFound
      });
    }

    const affected = [];

    // -----------------------------------------------------------------------------------
    // Archive and restore are the same statement with a different value, and both are just
    // a flag - no rows go anywhere.
    // -----------------------------------------------------------------------------------
    if (action === 'archive' || action === 'restore') {
      await client.query(
        `UPDATE league SET active = $2 WHERE id = ANY($1::int[])`,
        [foundIds, action === 'restore']
      );

      for (const row of existing.rows) {
        affected.push({ id: row.id, name: row.name });
      }
    }

    // -----------------------------------------------------------------------------------
    // Delete. Children first, parent last, so no foreign key is ever left dangling
    // mid-transaction.
    // -----------------------------------------------------------------------------------
    if (action === 'delete') {
      for (const row of existing.rows) {
        // The fixtures
        const fixtures = await client.query(
          `DELETE FROM fixture WHERE league_id = $1`, [row.id]
        );

        // The scoring configuration
        await client.query(
          `DELETE FROM league_points WHERE league_id = $1`, [row.id]
        );

        // Work out which guests are about to be stranded, BEFORE the memberships go.
        //
        // The condition is the whole point: a guest qualifies only if this league is the
        // single league they belong to. The NOT EXISTS checks for a membership of any
        // *other* league, so a guest who appears twice survives.
        const strandedGuests = await client.query(`
          SELECT u.id
          FROM league_members lm
          JOIN app_user u ON u.id = lm.user_id
          WHERE lm.league_id = $1
            AND lower(u.email) = 'guest'
            AND NOT EXISTS (
              SELECT 1 FROM league_members other
              WHERE other.user_id = u.id AND other.league_id <> $1
            )
        `, [row.id]);

        const guestIds = strandedGuests.rows.map((guest) => guest.id);

        // The memberships
        const members = await client.query(
          `DELETE FROM league_members WHERE league_id = $1`, [row.id]
        );

        // The stranded guests themselves. Guarded on the guest email a second time - this
        // statement deletes from app_user, and it should be impossible to read it and
        // wonder whether a real account could slip through.
        if (guestIds.length > 0) {
          await client.query(
            `DELETE FROM app_user WHERE id = ANY($1::int[]) AND lower(email) = 'guest'`,
            [guestIds]
          );
        }

        // And finally the league
        await client.query(`DELETE FROM league WHERE id = $1`, [row.id]);

        affected.push({
          id: row.id,
          name: row.name,
          fixtures_deleted: fixtures.rowCount,
          members_deleted: members.rowCount,
          guests_deleted: guestIds.length
        });
      }
    }

    await client.query('COMMIT');

    // Leave a trace in the server log. There is no admin audit table, and a destructive
    // action with no record of who did it or what it took is not something to ship.
    console.log(
      `[admin] ${req.adminEmail} performed "${action}" on league(s) ` +
      `${foundIds.join(', ')} - ${JSON.stringify(affected)}`
    );

    return res.status(200).json({
      return_code: 'SUCCESS',
      action: action,
      affected: affected,
      not_found: notFound
    });
  } catch (error) {
    // Any failure anywhere puts every table back as it was
    await client.query('ROLLBACK').catch(() => {});

    console.error('Error in admin_league_action route:', error);

    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  } finally {
    // The client must go back to the pool whatever happened, or the pool leaks connections
    client.release();
  }
});

module.exports = router;
