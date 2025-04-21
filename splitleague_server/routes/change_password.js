/*
=======================================================================================================================================
Route: change_password.js
=======================================================================================================================================
Purpose: Change a user's password (requires authentication)
=======================================================================================================================================
Request Body:
{
  "current_password": "current_password",  // string, required - The user's current password
  "new_password": "new_password"           // string, required - The new password
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Password changed successfully"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"INVALID_PASSWORD"
"SERVER_ERROR"
"MISSING_FIELDS"
"UNAUTHORIZED"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const bcrypt = require('bcrypt');
const verifyToken = require('../middleware/auth_middleware');
const emailUtils = require('../utils/email_utils');

// POST /change_password
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract current and new password from request body
    const { current_password, new_password } = req.body;
    
    // Check if all required fields are provided
    if (!current_password || !new_password) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Current password and new password are required'
      });
    }
    
    // Get the user ID from the authenticated token
    const userId = req.userId;
    
    // Get the user from the database
    const userResult = await pool.query(
      'SELECT id, name, email, password_hash FROM app_user WHERE id = $1',
      [userId]
    );
    
    // Check if user exists
    if (userResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'UNAUTHORIZED',
        message: 'User not found'
      });
    }
    
    const user = userResult.rows[0];
    
    // Verify current password
    const isPasswordValid = await bcrypt.compare(current_password, user.password_hash);
    
    if (!isPasswordValid) {
      return res.status(401).json({
        return_code: 'INVALID_PASSWORD',
        message: 'Current password is incorrect'
      });
    }
    
    // Hash the new password
    const saltRounds = 10;
    const newPasswordHash = await bcrypt.hash(new_password, saltRounds);
    
    // Update user's password
    await pool.query(
      'UPDATE app_user SET password_hash = $1 WHERE id = $2',
      [newPasswordHash, userId]
    );
    
    // Send password change confirmation email
    await emailUtils.sendPasswordChangeConfirmationEmail(user.email, user.name);
    
    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'Password changed successfully'
    });
  } catch (error) {
    console.error('Error changing password:', error);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while changing password'
    });
  }
});

module.exports = router;
