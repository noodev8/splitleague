/*
=======================================================================================================================================
Route: resend_verification.js
=======================================================================================================================================
Purpose: Resend verification email to a user with a new verification token
=======================================================================================================================================
Request Body:
{
  "email": "user@example.com"  // string, required - The email address of the user
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Verification email sent successfully"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"EMAIL_NOT_FOUND"
"ALREADY_VERIFIED"
"SERVER_ERROR"
"MISSING_FIELDS"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const emailUtils = require('../utils/email_utils');

// POST /resend_verification
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
      // Guest placeholder rows (email = 'guest') are not accounts - see login_user.js
      `SELECT id, name, email, email_verified FROM app_user WHERE email = $1 AND LOWER(email) <> 'guest'`,
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
    
    // Check if email is already verified
    if (user.email_verified) {
      return res.status(400).json({
        return_code: 'ALREADY_VERIFIED',
        message: 'Email is already verified'
      });
    }
    
    // Generate new verification token
    const verificationToken = emailUtils.generateToken();
    
    // Set token expiration (24 hours from now)
    const expirationDate = new Date();
    expirationDate.setHours(expirationDate.getHours() + 24);
    
    // Update user with new verification token and expiration
    await pool.query(
      'UPDATE app_user SET verification_token = $1, verification_expires = $2 WHERE id = $3',
      [verificationToken, expirationDate, user.id]
    );
    
    // Send verification email
    const emailResult = await emailUtils.sendVerificationEmail(user.email, user.name, verificationToken);
    
    if (!emailResult.success) {
      return res.status(500).json({
        return_code: 'SERVER_ERROR',
        message: 'Failed to send verification email'
      });
    }
    
    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'Verification email sent successfully'
    });
  } catch (error) {
    console.error('Error resending verification email:', error);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while resending verification email'
    });
  }
});

module.exports = router;
