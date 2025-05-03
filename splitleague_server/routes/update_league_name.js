/*
=======================================================================================================================================
API Route: update_league_name
=======================================================================================================================================
Method: POST
Purpose: Updates the name of a league. Only the league creator (organizer) can update the league name.
=======================================================================================================================================
Request Payload:
{
  "league_id": 1,                     // integer, required - ID of the league to update
  "name": "New League Name"           // string, required - New name for the league (max 30 characters)
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "League name updated successfully",
  "league": {
    "id": 1,
    "name": "New League Name",
    // ... other league properties
  }
}

Error Responses:
{
  "return_code": "MISSING_FIELDS",
  "message": "League ID and name are required"
}
{
  "return_code": "LEAGUE_NOT_FOUND",
  "message": "League not found"
}
{
  "return_code": "UNAUTHORIZED",
  "message": "Only the league creator can update the league name"
}
{
  "return_code": "INVALID_NAME",
  "message": "League name must be 30 characters or less"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /update_league_name
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract league ID and new name from request body
    const { league_id, name } = req.body;

    // Check if required fields are provided
    if (!league_id || !name) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League ID and name are required'
      });
    }

    // Check if league name is within the allowed length (30 characters)
    if (name.length > 30) {
      return res.status(400).json({
        return_code: 'INVALID_NAME',
        message: 'League name must be 30 characters or less'
      });
    }

    // Get the user ID from the authenticated token
    const userId = req.userId;

    // Check if the league exists and if the user is the creator
    const leagueResult = await pool.query(
      'SELECT * FROM league WHERE id = $1',
      [league_id]
    );

    if (leagueResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found'
      });
    }

    const league = leagueResult.rows[0];

    // Check if the user is the creator of the league
    if (league.created_by !== userId) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'Only the league creator can update the league name'
      });
    }

    // Update the league name
    await pool.query(
      'UPDATE league SET name = $1 WHERE id = $2',
      [name, league_id]
    );

    // Get the updated league information
    const updatedLeagueResult = await pool.query(`
      SELECT
        l.id,
        l.name,
        l.created_by,
        l.public_code,
        l.active,
        l.start_date,
        l.end_date,
        l.created_at,
        l.allow_code_share,
        CASE WHEN l.created_by = $1 THEN true ELSE false END as is_creator,
        (
          SELECT COUNT(*) > 0
          FROM league_members lm
          WHERE lm.league_id = l.id AND lm.user_id = $1
        ) as is_member,
        (
          SELECT u.nickname
          FROM app_user u
          WHERE u.id = l.created_by
        ) as created_by_nickname
      FROM
        league l
      WHERE
        l.id = $2
    `, [userId, league_id]);

    // Get the league points information
    const pointsResult = await pool.query(
      'SELECT * FROM league_points WHERE league_id = $1',
      [league_id]
    );

    // Combine league and points data
    const updatedLeague = {
      ...updatedLeagueResult.rows[0],
      ...pointsResult.rows[0]
    };

    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'League name updated successfully',
      league: updatedLeague
    });
  } catch (error) {
    console.error('Error updating league name:', error);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while updating the league name'
    });
  }
});

module.exports = router;
