/*
=======================================================================================================================================
Route: verify_email.js
=======================================================================================================================================
Purpose: Verify a user's email address using the verification token
=======================================================================================================================================
Request Body:
{
  "token": "verification_token_string"  // string, required - The verification token sent to the user's email
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Email verified successfully"
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
const emailUtils = require('../utils/email_utils');

// POST /verify_email
router.post('/', async (req, res) => {
  try {
    // Extract token from request body
    const { token } = req.body;
    
    // Check if token is provided
    if (!token) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Verification token is required'
      });
    }
    
    // Find user with this verification token
    const userResult = await pool.query(
      'SELECT id, name, email, email_verified, verification_expires FROM app_user WHERE verification_token = $1',
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
    
    // Check if email is already verified
    if (user.email_verified) {
      return res.status(200).json({
        return_code: 'SUCCESS',
        message: 'Email is already verified'
      });
    }
    
    // Check if token has expired
    const now = new Date();
    const tokenExpires = new Date(user.verification_expires);
    
    if (now > tokenExpires) {
      return res.status(400).json({
        return_code: 'TOKEN_EXPIRED',
        message: 'Verification token has expired'
      });
    }
    
    // Update user's email_verified status and clear verification token
    await pool.query(
      'UPDATE app_user SET email_verified = true, verification_token = NULL, verification_expires = NULL WHERE id = $1',
      [user.id]
    );
    
    // Send verification success email
    await emailUtils.sendVerificationSuccessEmail(user.email, user.name);
    
    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'Email verified successfully'
    });
  } catch (error) {
    console.error('Error verifying email:', error);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while verifying email'
    });
  }
});

module.exports = router;
