/*
=======================================================================================================================================
API Route: get_league_table
=======================================================================================================================================
Method: POST
Purpose: Calculates and returns the league table standings based on the league's points rules.
=======================================================================================================================================
Request Payload:
{
  "league_id": 1                       // integer, required - The ID of the league to get standings for
}

Success Response:
{
  "return_code": "SUCCESS",
  "standings": [
    {
      "user_id": 123,                  // integer, the user's ID
      "name": "John Doe",              // string, the user's name
      "nickname": "Johnny",            // string, the user's nickname
      "played": 10,                    // integer, number of games played
      "won": 5,                        // integer, number of games won
      "drawn": 2,                      // integer, number of games drawn (only for WDL leagues)
      "lost": 3,                       // integer, number of games lost
      "points": 17,                    // integer, total points
      "score_for": 25,                 // integer, total score for (only for PTS leagues)
      "score_against": 18,             // integer, total score against (only for PTS leagues)
      "score_diff": 7                  // integer, score difference (only for PTS leagues)
    },
    // More players...
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"LEAGUE_NOT_FOUND"
"NOT_A_MEMBER"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const db = require('../db');
const verifyToken = require('../middleware/auth_middleware');
const { calculateStandings } = require('../utils/standings_utils');

// Apply authentication middleware to this route
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract league_id from request body
    const { league_id } = req.body;

    // Validate required fields
    if (!league_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League ID is required'
      });
    }

    // Get the authenticated user's ID from the token
    const userId = req.userId;

    // Check if the league exists
    const leagueQuery = `
      SELECT l.*, lp.win_type, lp.points_for_win, lp.points_for_draw,
             lp.points_for_win_margin, lp.points_for_close_loss, lp.win_margin_threshold
      FROM league l
      JOIN league_points lp ON l.id = lp.league_id
      WHERE l.id = $1
    `;

    const leagueResult = await db.query(leagueQuery, [league_id]);

    // If league doesn't exist, return error
    if (leagueResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found'
      });
    }

    // Get league details
    const league = leagueResult.rows[0];
    const winType = league.win_type;

    // Check if the user is a member of the league
    const membershipQuery = `
      SELECT * FROM league_members
      WHERE league_id = $1 AND user_id = $2
      UNION
      SELECT * FROM league_members
      WHERE league_id = $1 AND user_id = (SELECT created_by FROM league WHERE id = $1)
    `;

    const membershipResult = await db.query(membershipQuery, [league_id, userId]);

    // If user is not a member or creator, return error
    if (membershipResult.rows.length === 0) {
      return res.status(403).json({
        return_code: 'NOT_A_MEMBER',
        message: 'You must be a member of the league to view the standings'
      });
    }

    // Get all league members
    const membersQuery = `
      SELECT lm.user_id, u.name, u.nickname
      FROM league_members lm
      JOIN app_user u ON lm.user_id = u.id
      WHERE lm.league_id = $1
      UNION
      SELECT u.id as user_id, u.name, u.nickname
      FROM app_user u
      JOIN league l ON u.id = l.created_by
      WHERE l.id = $1
    `;

    const membersResult = await db.query(membersQuery, [league_id]);
    const members = membersResult.rows;

    // Get all fixtures for the league
    const fixturesQuery = `
      SELECT * FROM fixture
      WHERE league_id = $1 AND played = true
    `;

    const fixturesResult = await db.query(fixturesQuery, [league_id]);
    const fixtures = fixturesResult.rows;

    // Work out the table
    //
    // The scoring rules live in utils/standings_utils so that this route and the public
    // read-only league page produce exactly the same table. Do not inline this logic again.
    const standings = calculateStandings(league, members, fixtures);

    // Return the standings
    return res.json({
      return_code: 'SUCCESS',
      standings: standings
    });

  } catch (error) {
    console.error('Error getting league table:', error);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while getting the league table'
    });
  }
});

module.exports = router;
