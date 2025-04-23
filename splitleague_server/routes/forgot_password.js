/*
=======================================================================================================================================
Route: forgot_password.js
=======================================================================================================================================
Purpose: Generate a verification token for password reset and send a reset email to the user
=======================================================================================================================================
Request Body:
{
  "email": "user@example.com"  // string, required - The email address of the user
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Password reset email sent successfully"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"EMAIL_NOT_FOUND"
"SERVER_ERROR"
"MISSING_FIELDS"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const emailUtils = require('../utils/email_utils');

// POST /forgot_password
router.post('/', async (req, res) => {
  try {
    // Extract email from request body
    const { email } = req.body;

    // Check if email is provided
    if (!email) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Email is required'
      });
    }

    // Find user with this email
    const userResult = await pool.query(
      'SELECT id, name, email FROM app_user WHERE email = $1',
      [email]
    );

    // Check if user exists
    if (userResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'EMAIL_NOT_FOUND',
        message: 'No user found with this email address'
      });
    }

    const user = userResult.rows[0];

    // Generate verification token for password reset
    const verificationToken = emailUtils.generateToken();

    // Set token expiration (1 hour from now)
    const expirationDate = new Date();
    expirationDate.setHours(expirationDate.getHours() + 1);

    // Update user with verification token and expiration
    await pool.query(
      'UPDATE app_user SET verification_token = $1, verification_expires = $2 WHERE id = $3',
      [verificationToken, expirationDate, user.id]
    );

    // Send password reset email
    const emailResult = await emailUtils.sendPasswordResetEmail(user.email, user.name, verificationToken);

    if (!emailResult.success) {
      console.error('Failed to send password reset email:', emailResult.error);
      return res.status(500).json({
        return_code: 'SERVER_ERROR',
        message: 'Failed to send password reset email'
      });
    }

    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'Password reset email sent successfully'
    });
  } catch (error) {
    console.error('Error sending password reset email:', error);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while sending password reset email'
    });
  }
});

module.exports = router;
