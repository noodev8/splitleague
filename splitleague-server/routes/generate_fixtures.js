/*
=======================================================================================================================================
API Route: generate_fixtures
=======================================================================================================================================
Method: POST
Purpose: Generates fixtures for a league based on the play_each_other setting.
         Creates entries in the fixture table for all possible player matchups.
=======================================================================================================================================
Request Payload:
{
  "league_id": 1                       // integer, required - ID of the league to generate fixtures for
}

Success Response:
{
  "return_code": "SUCCESS",
  "fixtures_created": 12,              // integer - Number of fixtures created
  "message": "Fixtures generated successfully"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /generate_fixtures
router.post('/', verifyToken, async (req, res) => {
  const client = await pool.connect();

  try {
    // Extract league ID from request body and convert to integer
    const league_id = parseInt(req.body.league_id);

    if (!league_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League ID is required'
      });
    }

    // Get the league details with points settings
    const leagueResult = await client.query(
      `SELECT l.*, lp.play_each_other
       FROM league l
       LEFT JOIN league_points lp ON l.id = lp.league_id
       WHERE l.id = $1`,
      [league_id]
    );

    if (leagueResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found'
      });
    }

    // Check if user is the creator of the league
    const userId = req.userId;

    // Convert both to integers for comparison
    if (parseInt(leagueResult.rows[0].created_by) !== parseInt(userId)) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'Only the league creator can generate fixtures'
      });
    }

    // Get play_each_other value (default to 2 if not set)
    const playEachOther = leagueResult.rows[0].play_each_other || 2;

    // Get all members of the league (including the creator)
    const membersResult = await client.query(
      `SELECT lm.user_id
       FROM league_members lm
       WHERE lm.league_id = $1
       UNION
       SELECT $2 as user_id`,
      [league_id, userId]
    );

    const members = membersResult.rows.map(row => row.user_id);

    // Check if there are enough members to generate fixtures
    if (members.length < 2) {
      return res.status(400).json({
        return_code: 'INSUFFICIENT_MEMBERS',
        message: 'At least 2 members are required to generate fixtures'
      });
    }

    // Check if fixtures already exist for this league
    const existingFixturesResult = await client.query(
      'SELECT COUNT(*) FROM fixture WHERE league_id = $1',
      [league_id]
    );

    if (parseInt(existingFixturesResult.rows[0].count) > 0) {
      return res.status(400).json({
        return_code: 'FIXTURES_ALREADY_EXIST',
        message: 'Fixtures already exist for this league'
      });
    }

    // Begin transaction
    await client.query('BEGIN');

    let fixturesCreated = 0;

    // Generate fixtures for all possible player combinations
    for (let i = 0; i < members.length; i++) {
      for (let j = i + 1; j < members.length; j++) {
        // For each pair, create fixtures based on playEachOther setting
        for (let k = 0; k < playEachOther; k++) {
          // Alternate home and away for each iteration
          // Even iterations: player i is home (player_1_id)
          // Odd iterations: player j is home (player_1_id)
          const isPlayerIHome = k % 2 === 0;
          const player1Id = isPlayerIHome ? members[i] : members[j];
          const player2Id = isPlayerIHome ? members[j] : members[i];

          await client.query(
            `INSERT INTO fixture (
              league_id,
              player_1_id,
              player_2_id,
              played,
              created_at
            ) VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)`,
            [
              league_id,
              player1Id,
              player2Id,
              false
            ]
          );
          fixturesCreated++;
        }
      }
    }

    // Commit the transaction
    await client.query('COMMIT');

    return res.status(201).json({
      return_code: 'SUCCESS',
      fixtures_created: fixturesCreated,
      message: 'Fixtures generated successfully'
    });

  } catch (error) {
    // Rollback the transaction in case of error
    await client.query('ROLLBACK');

    console.error('Error in generate_fixtures route:', error);

    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while generating fixtures'
    });
  } finally {
    client.release();
  }
});

module.exports = router;