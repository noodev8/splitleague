/*
=======================================================================================================================================
API Route: copy_league
=======================================================================================================================================
Method: POST
Purpose: Creates a copy of an existing league with its details, points system, and players.
         Only the league creator (organizer) can copy a league.
         The new league will have the same name with "- copy" appended, and no fixtures.
=======================================================================================================================================
Request Payload:
{
  "league_id": 1                     // integer, required - ID of the league to copy
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "League copied successfully",
  "new_league": {                    // The newly created league
    "id": 2,
    "name": "Original League - copy",
    // ... other league properties
  }
}

Error Responses:
{
  "return_code": "MISSING_FIELDS",
  "message": "League ID is required"
}
{
  "return_code": "LEAGUE_NOT_FOUND",
  "message": "League not found"
}
{
  "return_code": "UNAUTHORIZED",
  "message": "Only the league creator can copy a league"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /copy_league
router.post('/', verifyToken, async (req, res) => {
  // Get a client from the pool for transaction
  const client = await pool.connect();
  
  try {
    // Extract league ID from request body
    const { league_id } = req.body;

    // Check if league_id is provided
    if (!league_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League ID is required'
      });
    }

    // Get the user ID from the authenticated token
    const userId = req.userId;

    // Begin transaction
    await client.query('BEGIN');

    // Check if the league exists and if the user is the creator
    const leagueResult = await client.query(
      'SELECT * FROM league WHERE id = $1',
      [league_id]
    );

    if (leagueResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found'
      });
    }

    const originalLeague = leagueResult.rows[0];

    // Check if the user is the creator of the league
    if (originalLeague.created_by !== userId) {
      await client.query('ROLLBACK');
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'Only the league creator can copy a league'
      });
    }

    // Create a new league name with "- copy" appended
    // If the name would exceed 30 characters, truncate it
    let newLeagueName = originalLeague.name;
    const suffix = " - copy";
    
    if (newLeagueName.length + suffix.length > 30) {
      // Truncate the name to fit the suffix
      newLeagueName = newLeagueName.substring(0, 30 - suffix.length);
    }
    
    newLeagueName += suffix;

    // Generate a unique 4-digit code for the league
    let publicCode;
    let codeExists = true;
    
    while (codeExists) {
      // Generate a random 4-digit code
      publicCode = Math.floor(1000 + Math.random() * 9000).toString();
      
      // Check if the code already exists
      const codeCheckResult = await client.query(
        'SELECT COUNT(*) FROM league WHERE public_code = $1',
        [publicCode]
      );
      
      codeExists = parseInt(codeCheckResult.rows[0].count) > 0;
    }

    // Insert the new league
    const newLeagueResult = await client.query(
      `INSERT INTO league (
        name,
        created_by,
        created_at,
        public_code,
        active,
        allow_code_share
      ) VALUES ($1, $2, CURRENT_TIMESTAMP, $3, $4, $5)
      RETURNING *`,
      [
        newLeagueName,
        userId,
        publicCode,
        true, // active
        originalLeague.allow_code_share
      ]
    );

    const newLeague = newLeagueResult.rows[0];

    // Get the league points settings
    const pointsResult = await client.query(
      'SELECT * FROM league_points WHERE league_id = $1',
      [league_id]
    );

    if (pointsResult.rows.length > 0) {
      const pointsData = pointsResult.rows[0];
      
      // Copy the points settings to the new league
      await client.query(
        `INSERT INTO league_points (
          league_id,
          points_for_win,
          points_for_draw,
          points_for_win_margin,
          points_for_close_loss,
          win_margin_threshold,
          play_each_other,
          win_type
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
        [
          newLeague.id,
          pointsData.points_for_win,
          pointsData.points_for_draw,
          pointsData.points_for_win_margin,
          pointsData.points_for_close_loss,
          pointsData.win_margin_threshold,
          pointsData.play_each_other,
          pointsData.win_type
        ]
      );
    }

    // Get the league members
    const membersResult = await client.query(
      'SELECT * FROM league_members WHERE league_id = $1',
      [league_id]
    );

    // Add the creator as a member of the new league
    await client.query(
      `INSERT INTO league_members (
        league_id,
        user_id,
        active,
        joined_at,
        last_accessed
      ) VALUES ($1, $2, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
      [newLeague.id, userId]
    );

    // Copy all other members to the new league
    for (const member of membersResult.rows) {
      // Skip the creator as they've already been added
      if (member.user_id === userId) continue;
      
      await client.query(
        `INSERT INTO league_members (
          league_id,
          user_id,
          active,
          joined_at,
          last_accessed
        ) VALUES ($1, $2, $3, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
        [newLeague.id, member.user_id, member.active]
      );
    }

    // Commit the transaction
    await client.query('COMMIT');

    // Get the complete league info to return
    const completeLeagueResult = await client.query(`
      SELECT
        l.*,
        CASE WHEN l.created_by = $1 THEN true ELSE false END as is_creator,
        (
          SELECT u.nickname
          FROM app_user u
          WHERE u.id = l.created_by
        ) as created_by_nickname
      FROM
        league l
      WHERE
        l.id = $2
    `, [userId, newLeague.id]);

    const completeLeague = completeLeagueResult.rows[0];

    // Get the points data for the new league
    const newPointsResult = await client.query(
      'SELECT * FROM league_points WHERE league_id = $1',
      [newLeague.id]
    );

    const newPointsData = newPointsResult.rows[0] || {};

    // Combine the league and points data
    const responseLeague = {
      ...completeLeague,
      ...newPointsData
    };

    // Return success response
    return res.status(201).json({
      return_code: 'SUCCESS',
      message: 'League copied successfully',
      new_league: responseLeague
    });
  } catch (error) {
    // Rollback the transaction in case of error
    await client.query('ROLLBACK');
    
    console.error('Error copying league:', error);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while copying the league'
    });
  } finally {
    // Release the client back to the pool
    client.release();
  }
});

module.exports = router;
