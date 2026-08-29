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

    // Update the accessed timestamp for the user
    //
    // This route runs every single time anyone opens the app, so it is the
    // hottest path we have. It used to query information_schema and conditionally
    // ALTER TABLE on every call to add the 'accessed' column - DDL on the hot path,
    // which is also why 'accessed' is unreliable for older accounts. The column
    // has existed for a long time; the check is gone.
    //
    // RETURNING lets one statement do the work that previously took three: if no
    // row comes back the user in the token no longer exists.
    const updateResult = await pool.query(
      'UPDATE app_user SET accessed = CURRENT_TIMESTAMP WHERE id = $1 RETURNING id',
      [userId]
    );

    // The token is valid but the account is gone
    if (updateResult.rows.length === 0) {
      return res.status(401).json({
        return_code: 'UNAUTHORIZED',
        message: 'User not found'
      });
    }

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
