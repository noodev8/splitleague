/*
=======================================================================================================================================
One-off data cleanup: orphaned guest rows
=======================================================================================================================================
Deletes guest app_user rows that belong to no league and are referenced by no fixture.

These accumulated because remove_player_from_league.js used to delete only the
league_members row, leaving the guest's app_user row behind forever. That route now
cleans up after itself, so this script is a one-time catch-up for the rows that built up
before the fix - it is not something to keep around or schedule.

Run from splitleague-server/ so it resolves pg and dotenv:

    node orphan_cleanup.js

It writes every row it is about to delete to a timestamped JSON file first, runs inside a
transaction, and re-checks the result before committing. Safe to run twice: the second run
finds nothing and deletes nothing.
=======================================================================================================================================
*/

require('dotenv').config();
const fs = require('fs');
const pool = require('./db');

// A guest is identified by the literal email 'guest'.
//
// The two NOT EXISTS clauses are the same pair of conditions the route now checks before
// it deletes a guest: in no league, and referenced by no fixture. The fixture check
// matters because this database has no foreign keys on app_user - nothing at the storage
// layer would stop us cutting a row out from under a fixture that still points at it.
const SELECT_ORPHANS = `
  SELECT u.*
  FROM app_user u
  WHERE lower(u.email) = 'guest'
    AND NOT EXISTS (SELECT 1 FROM league_members lm WHERE lm.user_id = u.id)
    AND NOT EXISTS (SELECT 1 FROM fixture f WHERE f.player_1_id = u.id OR f.player_2_id = u.id)
  ORDER BY u.id`;

(async () => {
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Read the rows first, so the backup file is exactly what we delete
    const orphans = (await client.query(SELECT_ORPHANS)).rows;

    if (orphans.length === 0) {
      await client.query('ROLLBACK');
      console.log('No orphaned guest rows found - nothing to do.');
      process.exit(0);
    }

    const backup = `orphan_guests_backup_${new Date().toISOString().slice(0, 10)}.json`;
    fs.writeFileSync(backup, JSON.stringify(orphans, null, 2));
    console.log(`Backed up ${orphans.length} rows to ${backup}`);

    // Delete exactly the ids we just backed up - not a re-run of the WHERE clause
    const ids = orphans.map(r => r.id);
    const del = await client.query('DELETE FROM app_user WHERE id = ANY($1::int[])', [ids]);
    console.log(`Deleted ${del.rowCount} orphaned guest rows`);

    // Re-check inside the transaction, before committing, so a surprise rolls back
    const left = (await client.query(SELECT_ORPHANS)).rows.length;

    if (left !== 0) {
      throw new Error(`expected 0 orphans remaining, found ${left}`);
    }

    await client.query('COMMIT');
    console.log('Committed.');

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Rolled back, nothing was changed:', error.message);
    process.exitCode = 1;

  } finally {
    client.release();
    process.exit(process.exitCode || 0);
  }
})();
