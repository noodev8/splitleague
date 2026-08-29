/*
=======================================================================================================================================
API Route: reset_league_fixtures
=======================================================================================================================================
Method: POST
Purpose: Deletes all fixtures for a league, effectively resetting the league to its initial state where players can be managed
         before generating new fixtures. Only the league creator (organizer) can reset fixtures.
=======================================================================================================================================
Request Payload:
{
  "league_id": 1                     // integer, required - ID of the league to reset fixtures for
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "League has been reset successfully",
  "fixtures_deleted": 10,            // integer - Number of fixtures that were deleted
  "new_public_code": "1234"          // string - New 4-digit public code for the league
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
  "message": "Only the league creator can reset the league"
}
{
  "return_code": "NO_FIXTURES",
  "message": "No fixtures found for this league"
}
{
  "return_code": "CODE_GENERATION_FAILED",
  "message": "Failed to generate a new unique code for the league"
}
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// Function to generate a random 4-digit code
const generateRandomCode = () => {
  return Math.floor(1000 + Math.random() * 9000).toString();
};

// Function to check if a code is already in use by an active league
const isCodeUnique = async (code) => {
  const result = await pool.query(
    'SELECT id FROM league WHERE public_code = $1 AND active = true',
    [code]
  );
  return result.rows.length === 0;
};

// Function to generate a unique code that's not already in use
const generateUniqueCode = async () => {
  // Maximum number of attempts to generate a unique code
  const maxAttempts = 10;
  let attempts = 0;
  let code;
  let isUnique = false;

  while (!isUnique && attempts < maxAttempts) {
    code = generateRandomCode();
    isUnique = await isCodeUnique(code);
    attempts++;
  }

  if (!isUnique) {
    throw new Error('Failed to generate a unique code after multiple attempts');
  }

  return code;
};

// POST /reset_league_fixtures
router.post('/', verifyToken, async (req, res) => {
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
        message: 'Only the league creator can reset the league'
      });
    }

    // Check if there are any fixtures for this league
    const fixturesCountResult = await pool.query(
      'SELECT COUNT(*) FROM fixture WHERE league_id = $1',
      [league_id]
    );

    const fixturesCount = parseInt(fixturesCountResult.rows[0].count);
    if (fixturesCount === 0) {
      return res.status(404).json({
        return_code: 'NO_FIXTURES',
        message: 'No fixtures found for this league'
      });
    }

    // Generate a new unique public code for security
    let newPublicCode;
    try {
      newPublicCode = await generateUniqueCode();
    } catch (error) {
      return res.status(500).json({
        return_code: 'CODE_GENERATION_FAILED',
        message: 'Failed to generate a new unique code for the league'
      });
    }

    // Delete all fixtures for this league
    const deleteResult = await pool.query(
      'DELETE FROM fixture WHERE league_id = $1 RETURNING id',
      [league_id]
    );

    const fixturesDeleted = deleteResult.rows.length;

    // Update the league with the new public code
    await pool.query(
      'UPDATE league SET public_code = $1 WHERE id = $2',
      [newPublicCode, league_id]
    );

    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'League has been reset successfully',
      fixtures_deleted: fixturesDeleted,
      new_public_code: newPublicCode
    });
  } catch (error) {
    console.error('Error resetting league fixtures:', error);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while resetting the league'
    });
  }
});

module.exports = router;
