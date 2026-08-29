/*
=======================================================================================================================================
Route: reset_password.js
=======================================================================================================================================
Purpose: Reset a user's password using a verification token
=======================================================================================================================================
Request Body:
{
  "token": "verification_token_string",  // string, required - The verification token sent to the user's email
  "new_password": "new_password"   // string, required - The new password
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Password reset successfully"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"INVALID_TOKEN"
"TOKEN_EXPIRED"
"SERVER_ERROR"
"MISSING_FIELDS"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const bcrypt = require('bcrypt');
const emailUtils = require('../utils/email_utils');

// POST /reset_password
router.post('/', async (req, res) => {
  try {
    // Extract token and new password from request body
    const { token, new_password } = req.body;

    // Check if all required fields are provided
    if (!token || !new_password) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Reset token and new password are required'
      });
    }

    // Find user with this verification token
    const userResult = await pool.query(
      'SELECT id, name, email, verification_expires FROM app_user WHERE verification_token = $1',
      [token]
    );

    // Check if user exists with this token
    if (userResult.rows.length === 0) {
      return res.status(400).json({
        return_code: 'INVALID_TOKEN',
        message: 'Invalid verification token'
      });
    }

    const user = userResult.rows[0];

    // Check if token has expired
    const now = new Date();
    const tokenExpires = new Date(user.verification_expires);

    if (now > tokenExpires) {
      return res.status(400).json({
        return_code: 'TOKEN_EXPIRED',
        message: 'Verification token has expired'
      });
    }

    // Hash the new password
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(new_password, saltRounds);

    // Update user's password and clear verification token
    await pool.query(
      'UPDATE app_user SET password_hash = $1, verification_token = NULL, verification_expires = NULL WHERE id = $2',
      [passwordHash, user.id]
    );

    // Send password change confirmation email
    await emailUtils.sendPasswordChangeConfirmationEmail(user.email, user.name);

    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'Password reset successfully'
    });
  } catch (error) {
    console.error('Error resetting password:', error);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while resetting password'
    });
  }
});

module.exports = router;
