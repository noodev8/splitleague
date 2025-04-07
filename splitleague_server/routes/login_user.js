/*
=======================================================================================================================================
API Route: login_user
=======================================================================================================================================
Method: POST
Purpose: Authenticates a user using their email and password. Returns a token and basic user details upon success.
=======================================================================================================================================
Request Payload:
{
  "email": "user@example.com",         // string, required
  "password": "securepassword123"      // string, required
}

Success Response:
{
  "return_code": "SUCCESS"
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", // string, JWT token for auth
  "user": {
    "id": 123,                         // integer, unique user ID
    "name": "Andreas",                 // string, user's name
    "email": "user@example.com",       // string, user's email
    "nickname": "Andy"                 // string, user's nickname
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_CREDENTIALS"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../db');

// POST /login_user
router.post('/', async (req, res) => {
  try {
    // Extract email and password from request body
    const { email, password } = req.body;
    
    // Check if email and password are provided
    if (!email || !password) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Email and password are required'
      });
    }
    
    // Query the database to find the user by email
    const userResult = await pool.query(
      'SELECT id, name, nickname, email, password_hash FROM app_user WHERE email = $1',
      [email]
    );
    
    // Check if user exists
    if (userResult.rows.length === 0) {
      return res.status(401).json({
        return_code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password'
      });
    }
    
    // Get the user from the result
    const user = userResult.rows[0];
    
    // Compare the provided password with the stored hash
    const isPasswordValid = await bcrypt.compare(password, user.password_hash);
    
    // Check if password is valid
    if (!isPasswordValid) {
      return res.status(401).json({
        return_code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password'
      });
    }
    
    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '7d' } // Token expires in 7 days
    );
    
    // Return success response with token and user data
    return res.status(200).json({
      return_code: 'SUCCESS',
      token: token,
      user: {
        id: user.id,
        name: user.name,
        nickname: user.nickname,
        email: user.email
      }
    });
  } catch (error) {
    console.error('Error in login_user route:', error);
    
    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
