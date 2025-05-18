/*
=======================================================================================================================================
API Route: update_user_accessed
=======================================================================================================================================
Method: POST
Purpose: Updates the accessed timestamp for a user when they log in or use the app.
=======================================================================================================================================
Request Payload:
{}  // No payload required, user is identified by their JWT token

Success Response:
{
  "return_code": "SUCCESS",
  "message": "User accessed timestamp updated successfully"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /update_user_accessed
router.post('/', verifyToken, async (req, res) => {
  try {
    // Get the user ID from the authenticated token
    const userId = req.userId;

    // Check if the user exists
    const userResult = await pool.query(
      'SELECT id FROM app_user WHERE id = $1',
      [userId]
    );

    if (userResult.rows.length === 0) {
      return res.status(401).json({
        return_code: 'UNAUTHORIZED',
        message: 'User not found'
      });
    }

    // Add accessed column if it doesn't exist
    try {
      await pool.query(`
        DO $$
        BEGIN
          IF NOT EXISTS (
            SELECT 1 
            FROM information_schema.columns 
            WHERE table_name = 'app_user' 
            AND column_name = 'accessed'
          ) THEN
            ALTER TABLE app_user ADD COLUMN accessed TIMESTAMP WITH TIME ZONE;
          END IF;
        END
        $$;
      `);
    } catch (alterError) {
      console.error('Error checking/adding accessed column:', alterError);
      // Continue even if this fails, as the update might still work
    }

    // Update the accessed timestamp for the user
    await pool.query(
      'UPDATE app_user SET accessed = CURRENT_TIMESTAMP WHERE id = $1',
      [userId]
    );

    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'User accessed timestamp updated successfully'
    });
  } catch (error) {
    console.error('Error in update_user_accessed route:', error);

    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
