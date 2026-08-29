/*
=======================================================================================================================================
API Route: get_league_preview
=======================================================================================================================================
Method: POST
Purpose: Looks up the friendly details of a league from its share slug or its public code, WITHOUT joining
         it and without requiring membership. Used by the join screen so somebody arriving from an invite
         link sees what they are being invited to - the league name, who is running it, and how many
         players are in - rather than a bare identifier they never typed.

         Accepts either shape, and the caller does not have to say which it is holding:

           share_slug   ten characters, e.g. "7jwpbsz5ym" - from a link. Somebody who arrives this way
                        is never shown a code at all; there is nothing for them to type.
           public_code  four digits - somebody typing in a code they were told.
=======================================================================================================================================
Request Payload:
{
  "league_key": "7jwpbsz5ym"           // string, required - Share slug or 4-digit public code
}

  or, from older installs that predate the share slug:

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
list. That is the same information already on the public web page at /l/<slug>, so this adds no new
exposure - it just puts it in front of somebody who followed an invite link into the app.

An inactive league is treated as not found, matching join_league.js.

The 4-digit public_code is deliberately NOT returned. Somebody who arrived by link never saw a code
and has no use for one - showing it would put an identifier in front of them that they did not
choose and do not need. Once they have joined, the code is on the league's own details screen.
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');
const { resolveLeagueKey } = require('../utils/share_slug_utils');

// POST /get_league_preview
router.post('/', verifyToken, async (req, res) => {
  try {
    // league_key is what the app sends now; public_code is still read as a fallback so that
    // installs already on people's phones keep working after this deploys.
    const leagueKey = req.body.league_key || req.body.public_code;

    // Check an identifier was supplied
    if (!leagueKey) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'A league code or link is required'
      });
    }

    const userId = req.userId;

    // Work out whether this is a share slug or a 4-digit code. Neither shape means no such
    // league, which is the same answer as a code that matched nothing.
    const resolved = resolveLeagueKey(leagueKey);

    if (resolved === null) {
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found with the provided code'
      });
    }

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
       WHERE l.${resolved.column} = $2
         AND l.active = true`,
      [userId, resolved.value]
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
