/*
=======================================================================================================================================
API Route: register_user
=======================================================================================================================================
Method: POST
Purpose: Registers a new user with the provided details. Returns a token and basic user details upon success.
=======================================================================================================================================
Request Payload:
{
  "name": "John Doe",                  // string, required
  "nickname": "Johnny",                // string, required
  "email": "user@example.com",         // string, required
  "password": "securepassword123"      // string, required
}

Success Response:
{
  "return_code": "SUCCESS"
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", // string, JWT token for auth
  "user": {
    "id": 123,                         // integer, unique user ID
    "name": "John Doe",                // string, user's name
    "nickname": "Johnny",              // string, user's nickname
    "email": "user@example.com"        // string, user's email
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"EMAIL_ALREADY_EXISTS"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../db');

// POST /register_user
router.post('/', async (req, res) => {
  try {
    // Extract user details from request body
    const { name, nickname, email, password } = req.body;

    // Check if all required fields are provided
    if (!name || !nickname || !email || !password) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'All fields are required'
      });
    }

    // Check if email already exists
    const emailCheckResult = await pool.query(
      'SELECT id FROM app_user WHERE email = $1',
      [email]
    );

    if (emailCheckResult.rows.length > 0) {
      return res.status(409).json({
        return_code: 'EMAIL_ALREADY_EXISTS',
        message: 'Email already exists'
      });
    }

    // Hash the password
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash(password, saltRounds);

    // Create the account already verified, and send no email
    //
    // Email verification used to gate login. It cost us 30% of all signups: 75 of 251
    // real registrations never verified and so could never log in - people who had
    // already typed their details in and wanted to use the app. For a pub league scores
    // app there is nothing behind the door worth defending with that, so verification is
    // mimicked rather than enforced: mark the account verified on the way in.
    //
    // The email_verified column stays, always true, so there is no schema change and
    // nothing downstream to break. verification_token and verification_expires are left
    // NULL here, but the COLUMNS MUST STAY - password reset writes and reads exactly
    // those two (see forgot_password.js and reset_password.js).
    const insertResult = await pool.query(
      'INSERT INTO app_user (name, nickname, email, password_hash, verification_token, verification_expires, email_verified) VALUES ($1, $2, $3, $4, $5, $6, $7) RETURNING id',
      [name, nickname, email, passwordHash, null, null, true]
    );

    // Get the new user's ID
    const userId = insertResult.rows[0].id;

    // Generate JWT token
    const token = jwt.sign(
      { userId: userId },
      process.env.JWT_SECRET,
      { expiresIn: '180d' } // Token expires in 180 days
    );

    // Return success response with token and user data
    return res.status(201).json({
      return_code: 'SUCCESS',
      token: token,
      user: {
        id: userId,
        name: name,
        nickname: nickname,
        email: email
      }
    });
  } catch (error) {
    console.error('Error in register route:', error);

    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
