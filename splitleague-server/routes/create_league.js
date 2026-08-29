/*
=======================================================================================================================================
API Route: create_league
=======================================================================================================================================
Method: POST
Purpose: Creates a new league with the provided details. The authenticated user becomes the creator of the league.
         Generates a unique 4-digit public code for the league and marks it as active.
         Creates entries in both league and league_points tables.
=======================================================================================================================================
Request Payload:
{
  "name": "Premier League 2025",        // string, required - Name of the league
  "win_type": "PTS",                    // string, optional - Type of win calculation: "PTS" (Points), "WIN" (Win only), "WDL" (Win/Draw/Loss) (default: "PTS")
  "points_for_win": 3,                  // integer, optional - Points awarded for a win (default: 3)
  "points_for_draw": 1,                 // integer, optional - Points awarded for a draw (default: 1)
  "points_for_win_margin": 1,           // integer, optional - Extra points for winning by a margin (default: 1)
  "points_for_close_loss": 1,           // integer, optional - Points for losing by a small margin (default: 1)
  "win_margin_threshold": 15,           // integer, optional - Threshold for win margin points (default: 15)
  "play_each_other": 2                  // integer, optional - Number of times each player plays each other (default: 2)
}

Success Response:
{
  "return_code": "SUCCESS",
  "league": {
    "id": 1,                            // integer - Unique league ID
    "name": "Premier League 2025",      // string - League name
    "created_by": 123,                  // integer - User ID of creator
    "public_code": "1234",              // string - Unique 4-digit code for joining the league
    "active": true,                     // boolean - League active status
    "start_date": "2025-05-01",         // date - Start date
    "end_date": "2025-08-31",           // date - End date
    "created_at": "2025-04-06T12:00:00.000Z", // timestamp - Creation date
    "points": {
      "id": 1,                          // integer - Unique points ID
      "league_id": 1,                   // integer - League ID
      "points_for_win": 3,              // integer - Points for win
      "points_for_draw": 1,             // integer - Points for draw
      "points_for_win_margin": 1,       // integer - Points for win margin
      "points_for_close_loss": 1,       // integer - Points for close loss
      "win_margin_threshold": 15,       // integer - Win margin threshold
      "play_each_other": 2,             // integer - Number of times each player plays each other
      "win_type": "PTS"                 // string - Type of win calculation: "PTS", "WIN", or "WDL"
    }
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_NAME"           // When league name exceeds 30 characters
"UNAUTHORIZED"
"SERVER_ERROR"
"CODE_GENERATION_FAILED"
"TRANSACTION_FAILED"
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

// Function to check if a code is already in use by ANY league
//
// This deliberately does not filter on active = true any more. The code is now the
// key for the public league page at /l/<code>, so it has to be unique across every
// league that has ever existed - otherwise that URL is ambiguous. There is also a
// matching unique index on league.public_code in the database, which is the real
// guarantee; this check just lets us pick a free code before we try to insert.
const isCodeUnique = async (code) => {
  const result = await pool.query(
    'SELECT id FROM league WHERE public_code = $1',
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

// POST /create_league
router.post('/', verifyToken, async (req, res) => {
  // Get a client from the pool for transaction
  const client = await pool.connect();

  try {
    // Extract league details from request body
    const {
      name,
      win_type,
      points_for_win,
      points_for_draw,
      points_for_win_margin,
      points_for_close_loss,
      win_margin_threshold,
      play_each_other,
      allow_code_share
    } = req.body;

    // Check if required fields are provided
    if (!name) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League name is required'
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

    // Generate a unique 4-digit code for the league
    let publicCode;
    try {
      publicCode = await generateUniqueCode();
    } catch (error) {
      return res.status(500).json({
        return_code: 'CODE_GENERATION_FAILED',
        message: 'Failed to generate a unique code for the league'
      });
    }

    // Note on the race: two people creating a league at the same moment can both
    // be handed the same free code by the check above. The unique index on
    // league.public_code catches that at insert time - Postgres error 23505 - and
    // the catch block below turns it into CODE_GENERATION_FAILED rather than a
    // 500. Before the index existed this race silently produced two leagues
    // sharing a code.

    // Log the allow_code_share value for debugging
    console.log('Creating league with allow_code_share:', allow_code_share);

    // Begin transaction
    await client.query('BEGIN');

    // Insert the new league into the league table
    const leagueInsertResult = await client.query(
      `INSERT INTO league (
        name,
        created_by,
        public_code,
        active,
        allow_code_share
      ) VALUES ($1, $2, $3, $4, $5)
      RETURNING *`,
      [
        name,
        userId,
        publicCode,
        true, // Set active to true
        allow_code_share !== undefined ? allow_code_share : true // Default to true if not provided
      ]
    );

    // Get the newly created league
    const league = leagueInsertResult.rows[0];

    // Add creator as a member
    await client.query(
      `INSERT INTO league_members (
        league_id,
        user_id,
        active,
        joined_at
      ) VALUES ($1, $2, true, CURRENT_TIMESTAMP)`,
      [league.id, userId]
    );

    // Insert the points settings into the league_points table
    const pointsInsertResult = await client.query(
      `INSERT INTO league_points (
        league_id,
        points_for_win,
        points_for_draw,
        points_for_win_margin,
        points_for_close_loss,
        win_margin_threshold,
        play_each_other,
        win_type
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *`,
      [
        league.id,
        points_for_win,         // Remove || 3
        points_for_draw,        // Remove || 1
        points_for_win_margin,  // Remove || 1
        points_for_close_loss,  // Remove || 1
        win_margin_threshold,   // Remove || 15
        play_each_other,        // Remove || 2
        win_type               // Remove || 'PTS'
      ]
    );

    // Get the points settings
    const points = pointsInsertResult.rows[0];

    // Commit the transaction
    await client.query('COMMIT');

    // Add points to the league object for the response
    league.points = points;

    // Return success response with league data including points
    return res.status(201).json({
      return_code: 'SUCCESS',
      league_id: league.id,  // Add this line to include the league ID
      league: league
    });
  } catch (error) {
    // Rollback the transaction in case of error
    await client.query('ROLLBACK');

    // Postgres error 23505 is a unique violation. The only unique constraint that
    // can realistically fire here is league.public_code - two people creating a
    // league at the same instant and being handed the same free code. Tell the app
    // it was a code problem so the user can simply try again, rather than a 500.
    if (error.code === '23505') {
      console.error('Public code collision while creating league:', error.detail);

      return res.status(500).json({
        return_code: 'CODE_GENERATION_FAILED',
        message: 'Failed to generate a unique code for the league. Please try again'
      });
    }

    console.error('Error in create_league route:', error);

    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  } finally {
    // Release the client back to the pool
    client.release();
  }
});

module.exports = router;
