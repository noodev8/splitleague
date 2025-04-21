/*
=======================================================================================================================================
Route: update_profile.js
=======================================================================================================================================
Purpose: Update user profile information (name and nickname)
=======================================================================================================================================
Request Method: POST
Request Body:
  name - The user's new name
  nickname - The user's new nickname

Success Response:
  return_code: 'SUCCESS'
  message: 'Profile updated successfully'
  user: {
    id: <user_id>,
    name: <name>,
    nickname: <nickname>,
    email: <email>
  }

Error Responses:
  MISSING_FIELDS - Required fields are missing
  UNAUTHORIZED - User is not authenticated
  SERVER_ERROR - Server error occurred
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /update_profile
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract name and nickname from request body
    const { name, nickname } = req.body;
    
    // Check if all required fields are provided
    if (!name || !nickname) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Name and nickname are required'
      });
    }
    
    // Get the user ID from the authenticated token
    const userId = req.userId;
    
    // Update user's profile information
    await pool.query(
      'UPDATE app_user SET name = $1, nickname = $2 WHERE id = $3',
      [name, nickname, userId]
    );
    
    // Get the updated user information
    const userResult = await pool.query(
      'SELECT id, name, nickname, email FROM app_user WHERE id = $1',
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
    
    // Return success response with updated user data
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'Profile updated successfully',
      user: user
    });
  } catch (error) {
    console.error('Error in update_profile route:', error);
    
    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
