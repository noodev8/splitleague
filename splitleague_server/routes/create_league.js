/*
=======================================================================================================================================
API Route: create_league
=======================================================================================================================================
Method: POST
Purpose: Creates a new league with the provided details. The authenticated user becomes the creator of the league.
         Generates a unique 4-digit public code for the league and marks it as active.
=======================================================================================================================================
Request Payload:
{
  "name": "Premier League 2025",        // string, required - Name of the league
  "points_for_win": 3,                  // integer, optional - Points awarded for a win (default: 3)
  "points_for_draw": 1,                 // integer, optional - Points awarded for a draw (default: 1)
  "points_for_win_margin": 1,           // integer, optional - Extra points for winning by a margin (default: 1)
  "points_for_close_loss": 1,           // integer, optional - Points for losing by a small margin (default: 1)
  "win_margin_threshold": 15,           // integer, optional - Threshold for win margin points (default: 15)
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
    "points_for_win": 3,                // integer - Points for win
    "points_for_draw": 1,               // integer - Points for draw
    "points_for_win_margin": 1,         // integer - Points for win margin
    "points_for_close_loss": 1,         // integer - Points for close loss
    "win_margin_threshold": 15,         // integer - Win margin threshold
    "start_date": "2025-05-01",         // date - Start date
    "end_date": "2025-08-31",           // date - End date
    "created_at": "2025-04-06T12:00:00.000Z" // timestamp - Creation date
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"UNAUTHORIZED"
"SERVER_ERROR"
"CODE_GENERATION_FAILED"
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
  try {
    // Extract league details from request body
    const {
      name,
      points_for_win,
      points_for_draw,
      points_for_win_margin,
      points_for_close_loss,
      win_margin_threshold,
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

    // Insert the new league into the database with public_code and active=true
    const insertResult = await pool.query(
      `INSERT INTO league (
        name,
        created_by,
        public_code,
        active,
        points_for_win,
        points_for_draw,
        points_for_win_margin,
        points_for_close_loss,
        win_margin_threshold,
        start_date,
        end_date
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      RETURNING *`,
      [
        name,
        userId,
        publicCode,
        true, // Set active to true
        points_for_win || 3,
        points_for_draw || 1,
        points_for_win_margin || 1,
        points_for_close_loss || 1,
        win_margin_threshold || 15,
        start_date || null,
        end_date || null
      ]
    );

    // Get the newly created league
    const league = insertResult.rows[0];

    // Return success response with league data
    return res.status(201).json({
      return_code: 'SUCCESS',
      league: league
    });
  } catch (error) {
    console.error('Error in create_league route:', error);

    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
