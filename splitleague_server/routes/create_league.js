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
  "play_each_other": 2,                 // integer, optional - Number of times each player plays each other (default: 2)
  "start_date": "2025-05-01",           // date, optional - League start date (YYYY-MM-DD)
  "end_date": "2025-08-31"              // date, optional - League end date (YYYY-MM-DD)
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
      start_date,
      end_date
    } = req.body;

    // Check if required fields are provided
    if (!name) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League name is required'
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

    // Begin transaction
    await client.query('BEGIN');

    // Insert the new league into the league table
    const leagueInsertResult = await client.query(
      `INSERT INTO league (
        name,
        created_by,
        public_code,
        active,
        start_date,
        end_date
      ) VALUES ($1, $2, $3, $4, $5, $6)
      RETURNING *`,
      [
        name,
        userId,
        publicCode,
        true, // Set active to true
        start_date || null,
        end_date || null
      ]
    );

    // Get the newly created league
    const league = leagueInsertResult.rows[0];

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
        points_for_win || 3,
        points_for_draw || 1,
        points_for_win_margin || 1,
        points_for_close_loss || 1,
        win_margin_threshold || 15,
        play_each_other || 2,  // Default to 2 if not provided
        win_type || 'PTS'      // Default to PTS if not provided
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
      league: league
    });
  } catch (error) {
    // Rollback the transaction in case of error
    await client.query('ROLLBACK');

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
