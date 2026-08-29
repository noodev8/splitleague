/*
=======================================================================================================================================
API Route: join_league
=======================================================================================================================================
Method: POST
Purpose: Allows a user to join a league. If the user is already a member, returns success without adding them again.
         Will fail if fixtures have already been generated.

         The league can be identified two ways, and the caller does not have to say which it is holding:

           share_slug   ten characters, e.g. "7jwpbsz5ym" - somebody who followed an invite link.
                        They never saw a code and are never shown one; the link is the whole journey.
           public_code  four digits, e.g. "1234" - somebody typing in a code they were told.

         Nothing here assumes the identifier is four characters long. That assumption is what made the
         join screen a row of four boxes and tied joining to finishing typing.
=======================================================================================================================================
Request Payload:
{
  "league_key": "7jwpbsz5ym"           // string, required - Share slug or 4-digit public code
}

  or, from older installs that predate the share slug:

{
  "public_code": "1234"                // string, required - The 4-digit public code of the league to join
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Successfully joined the league"
}

Already Member Response:
{
  "return_code": "SUCCESS",
  "message": "You are already a member of this league"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_CODE"           // No league has that slug or code, or it is neither shape
"LEAGUE_INACTIVE"
"FIXTURES_EXIST"
"UNAUTHORIZED"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');
const { resolveLeagueKey } = require('../utils/share_slug_utils');

// POST /join_league
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract the league identifier from the request body
    //
    // league_key is what the app sends now. public_code is still read as a fallback so that
    // installs already on people's phones - which know nothing about slugs - keep working
    // after this deploys. The server updates before the app does, and always will.
    const leagueKey = req.body.league_key || req.body.public_code;

    // Check an identifier was provided
    if (!leagueKey) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'A league code or link is required'
      });
    }

    // Get the user ID from the authenticated token
    const userId = req.userId;

    // Work out whether this is a share slug or a 4-digit code
    //
    // Something that is neither shape cannot match a league, so it gets the same answer as a
    // code that matched nothing - there is no reason to tell a caller which of the two it
    // failed to look like.
    const resolved = resolveLeagueKey(leagueKey);

    if (resolved === null) {
      return res.status(404).json({
        return_code: 'INVALID_CODE',
        message: 'League not found with the provided code'
      });
    }

    // Find the league. The column comes from resolveLeagueKey, never from the request.
    const leagueResult = await pool.query(
      `SELECT * FROM league WHERE ${resolved.column} = $1`,
      [resolved.value]
    );

    // Check if league exists
    if (leagueResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'INVALID_CODE',
        message: 'League not found with the provided code'
      });
    }

    // Get the league
    const league = leagueResult.rows[0];

    // Check if league is active
    if (!league.active) {
      return res.status(400).json({
        return_code: 'LEAGUE_INACTIVE',
        message: 'This league is no longer active'
      });
    }

    // Check if user is already a member of the league
    const membershipResult = await pool.query(
      'SELECT * FROM league_members WHERE league_id = $1 AND user_id = $2',
      [league.id, userId]
    );

    // If user is already a member, return success message
    if (membershipResult.rows.length > 0) {
      return res.status(200).json({
        return_code: 'SUCCESS',
        message: 'You are already a member of this league'
      });
    }

    // Check if fixtures have been generated for this league
    const fixturesResult = await pool.query(
      'SELECT COUNT(*) FROM fixture WHERE league_id = $1',
      [league.id]
    );

    // If fixtures exist, return error
    if (parseInt(fixturesResult.rows[0].count) > 0) {
      return res.status(400).json({
        return_code: 'FIXTURES_EXIST',
        message: 'Cannot join this league because fixtures have already been generated'
      });
    }

    // Add user to the league
    await pool.query(
      'INSERT INTO league_members (league_id, user_id, active, joined_at, last_accessed) VALUES ($1, $2, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)',
      [league.id, userId]
    );

    // Return simple success response
    return res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Successfully joined the league'
    });
  } catch (error) {
    console.error('Error in join_league route:', error);

    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
