/*
=======================================================================================================================================
Route: verify_web_email.js
=======================================================================================================================================
Purpose: Verify a user's email address via web browser using the verification token in URL query parameter
=======================================================================================================================================
Request URL:
GET /verify_web_email?token=verification_token_string

Success Response:
HTML page with success message
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const emailUtils = require('../utils/email_utils');

// GET /verify_web_email
router.get('/', async (req, res) => {
  try {
    // Extract token from query parameters
    const { token } = req.query;
    
    // Check if token is provided
    if (!token) {
      return res.status(400).send(`
        <html>
          <head>
            <title>Email Verification Failed</title>
            <style>
              body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; text-align: center; }
              .error { color: #d32f2f; }
              h1 { color: #1976d2; }
            </style>
          </head>
          <body>
            <h1>Email Verification Failed</h1>
            <p class="error">Verification token is missing.</p>
            <p>Please check your email and try again with the correct verification link.</p>
          </body>
        </html>
      `);
    }
    
    // Find user with this verification token
    const userResult = await pool.query(
      'SELECT id, name, email, email_verified, verification_expires FROM app_user WHERE verification_token = $1',
      [token]
    );
    
    // Check if user exists with this token
    if (userResult.rows.length === 0) {
      return res.status(400).send(`
        <html>
          <head>
            <title>Email Verification Failed</title>
            <style>
              body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; text-align: center; }
              .error { color: #d32f2f; }
              h1 { color: #1976d2; }
            </style>
          </head>
          <body>
            <h1>Email Verification Failed</h1>
            <p class="error">Invalid verification token.</p>
            <p>The verification link may have expired or been used already.</p>
          </body>
        </html>
      `);
    }
    
    const user = userResult.rows[0];
    
    // Check if email is already verified
    if (user.email_verified) {
      return res.status(200).send(`
        <html>
          <head>
            <title>Email Already Verified</title>
            <style>
              body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; text-align: center; }
              h1 { color: #1976d2; }
              .success { color: #388e3c; }
            </style>
          </head>
          <body>
            <h1>Email Already Verified</h1>
            <p class="success">Your email address has already been verified.</p>
            <p>You can now log in to the SplitLeague app.</p>
          </body>
        </html>
      `);
    }
    
    // Check if token has expired
    const now = new Date();
    const tokenExpires = new Date(user.verification_expires);
    
    if (now > tokenExpires) {
      return res.status(400).send(`
        <html>
          <head>
            <title>Email Verification Failed</title>
            <style>
              body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; text-align: center; }
              .error { color: #d32f2f; }
              h1 { color: #1976d2; }
            </style>
          </head>
          <body>
            <h1>Email Verification Failed</h1>
            <p class="error">Verification token has expired.</p>
            <p>Please request a new verification email from the app.</p>
          </body>
        </html>
      `);
    }
    
    // Update user's email_verified status and clear verification token
    await pool.query(
      'UPDATE app_user SET email_verified = true, verification_token = NULL, verification_expires = NULL WHERE id = $1',
      [user.id]
    );
    
    // Send verification success email
    await emailUtils.sendVerificationSuccessEmail(user.email, user.name);
    
    // Return success HTML page
    return res.status(200).send(`
      <html>
        <head>
          <title>Email Verification Successful</title>
          <style>
            body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; text-align: center; }
            h1 { color: #1976d2; }
            .success { color: #388e3c; font-weight: bold; }
          </style>
        </head>
        <body>
          <h1>Email Verification Successful</h1>
          <p class="success">Your email address has been successfully verified!</p>
          <p>Thank you for completing this important step, ${user.name}.</p>
          <p>You can now log in to the SplitLeague app.</p>
        </body>
      </html>
    `);
  } catch (error) {
    console.error('Error verifying email via web:', error);
    return res.status(500).send(`
      <html>
        <head>
          <title>Email Verification Error</title>
          <style>
            body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; text-align: center; }
            .error { color: #d32f2f; }
            h1 { color: #1976d2; }
          </style>
        </head>
        <body>
          <h1>Email Verification Error</h1>
          <p class="error">An error occurred while verifying your email.</p>
          <p>Please try again later or contact support.</p>
        </body>
      </html>
    `);
  }
});

module.exports = router;
