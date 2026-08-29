/*
=======================================================================================================================================
API Route: get_league_preview
=======================================================================================================================================
Method: POST
Purpose: Looks up the friendly details of a league from its public code, WITHOUT joining it and without
         requiring membership. Used by the join screen so somebody arriving from an invite link sees what
         they are being invited to - the league name, who is running it, and how many players are in -
         rather than a bare 4-digit code they never typed.
=======================================================================================================================================
Request Payload:
{
  "public_code": "1231"                // string, required - The public code of the league
}

Success Response:
{
  "return_code": "SUCCESS",
  "name": "Brookfield League",         // string - League name
  "organiser": "Brookfield",           // string - Nickname of whoever created the league
  "player_count": 1,                   // integer - How many players are in so far
  "has_fixtures": false,               // boolean - true once the league has started
  "is_member": false                   // boolean - true if the caller is already in this league
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"LEAGUE_NOT_FOUND"
"SERVER_ERROR"
=======================================================================================================================================
What this deliberately does NOT expose:

Only the league name, the organiser's chosen nickname, and a count. No emails, no real names, no player
list. That is the same information already on the public web page at /l/<code>, so this adds no new
exposure - it just puts it in front of somebody who followed an invite link into the app.

An inactive league is treated as not found, matching join_league.js.
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /get_league_preview
router.post('/', verifyToken, async (req, res) => {
  try {
    const { public_code } = req.body;

    // Check the code was supplied
    if (!public_code) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Public code is required'
      });
    }

    const userId = req.userId;

    // Fetch the league, who runs it, how many are in, and whether it has started
    //
    // The player count mirrors get_league_members: league_members plus the creator, unioned so the
    // organiser is counted once whether or not they also hold a membership row.
    const result = await pool.query(
      `SELECT
         l.name,
         (
           SELECT u.nickname
           FROM app_user u
           WHERE u.id = l.created_by
         ) AS organiser,
         (
           SELECT COUNT(*)
           FROM (
             SELECT lm.user_id
             FROM league_members lm
             WHERE lm.league_id = l.id
             UNION
             SELECT l.created_by
           ) AS everyone
         ) AS player_count,
         (
           SELECT COUNT(*) > 0
           FROM fixture f
           WHERE f.league_id = l.id
         ) AS has_fixtures,
         (
           SELECT COUNT(*) > 0
           FROM league_members lm
           WHERE lm.league_id = l.id AND lm.user_id = $1
         ) AS is_member
       FROM league l
       WHERE l.public_code = $2
         AND l.active = true`,
      [userId, public_code]
    );

    // No league with that code - same answer as join_league gives
    if (result.rows.length === 0) {
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found with the provided code'
      });
    }

    const league = result.rows[0];

    return res.status(200).json({
      return_code: 'SUCCESS',
      name: league.name,
      organiser: league.organiser,
      player_count: parseInt(league.player_count),
      has_fixtures: league.has_fixtures,
      is_member: league.is_member
    });

  } catch (error) {
    console.error('Error in get_league_preview route:', error);

    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
