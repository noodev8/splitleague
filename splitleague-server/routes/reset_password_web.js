/*
=======================================================================================================================================
Route: reset_password_web.js
=======================================================================================================================================
Purpose: Provide a web interface for users to reset their password using a token from the reset email
=======================================================================================================================================
Request URL:
GET /reset_password_web?token=reset_token_string

Success Response:
HTML page with password reset form
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const bcrypt = require('bcrypt');
const emailUtils = require('../utils/email_utils');

// GET /reset_password_web - Show password reset form
router.get('/', async (req, res) => {
  try {
    // Extract token from query parameters
    const { token } = req.query;
    
    // Check if token is provided
    if (!token) {
      return res.status(400).send(`
        <html>
          <head>
            <title>Password Reset Failed</title>
            <style>
              body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; text-align: center; }
              .error { color: #d32f2f; }
              h1 { color: #1976d2; }
            </style>
          </head>
          <body>
            <h1>Password Reset Failed</h1>
            <p class="error">Reset token is missing.</p>
            <p>Please check your email and try again with the correct reset link.</p>
          </body>
        </html>
      `);
    }
    
    // Find user with this verification token
    const userResult = await pool.query(
      'SELECT id, name, email, verification_expires FROM app_user WHERE verification_token = $1',
      [token]
    );
    
    // Check if user exists with this token
    if (userResult.rows.length === 0) {
      return res.status(400).send(`
        <html>
          <head>
            <title>Password Reset Failed</title>
            <style>
              body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; text-align: center; }
              .error { color: #d32f2f; }
              h1 { color: #1976d2; }
            </style>
          </head>
          <body>
            <h1>Password Reset Failed</h1>
            <p class="error">Invalid reset token.</p>
            <p>The reset link may have expired or been used already.</p>
            <p>Please request a new password reset email.</p>
          </body>
        </html>
      `);
    }
    
    const user = userResult.rows[0];
    
    // Check if token has expired
    const now = new Date();
    const tokenExpires = new Date(user.verification_expires);
    
    if (now > tokenExpires) {
      return res.status(400).send(`
        <html>
          <head>
            <title>Password Reset Failed</title>
            <style>
              body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; text-align: center; }
              .error { color: #d32f2f; }
              h1 { color: #1976d2; }
            </style>
          </head>
          <body>
            <h1>Password Reset Failed</h1>
            <p class="error">Reset token has expired.</p>
            <p>Please request a new password reset email.</p>
          </body>
        </html>
      `);
    }
    
    // Return password reset form
    return res.status(200).send(`
      <html>
        <head>
          <title>Reset Your Password</title>
          <style>
            body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; text-align: center; }
            h1 { color: #1976d2; }
            .form-group { margin-bottom: 15px; }
            input[type="password"] { width: 100%; padding: 10px; border: 1px solid #ddd; border-radius: 4px; font-size: 16px; }
            button { background-color: #1976d2; color: white; border: none; padding: 12px 24px; border-radius: 4px; cursor: pointer; font-size: 16px; }
            button:hover { background-color: #1565c0; }
            .error { color: #d32f2f; display: none; margin-top: 10px; }
            .success { color: #388e3c; display: none; margin-top: 10px; }
          </style>
        </head>
        <body>
          <h1>Reset Your Password</h1>
          <p>Hello ${user.name}, please enter your new password below:</p>
          
          <div id="resetForm">
            <div class="form-group">
              <input type="password" id="password" placeholder="New Password" required>
            </div>
            <div class="form-group">
              <input type="password" id="confirmPassword" placeholder="Confirm New Password" required>
            </div>
            <button onclick="resetPassword()">Reset Password</button>
            <p id="errorMessage" class="error"></p>
            <p id="successMessage" class="success">Password reset successful! You can now log in with your new password.</p>
          </div>
          
          <script>
            function resetPassword() {
              const password = document.getElementById('password').value;
              const confirmPassword = document.getElementById('confirmPassword').value;
              const errorMessage = document.getElementById('errorMessage');
              const successMessage = document.getElementById('successMessage');
              const resetForm = document.getElementById('resetForm');
              
              // Reset messages
              errorMessage.style.display = 'none';
              successMessage.style.display = 'none';
              
              // Validate passwords
              if (!password || password.length < 6) {
                errorMessage.textContent = 'Password must be at least 6 characters long';
                errorMessage.style.display = 'block';
                return;
              }
              
              if (password !== confirmPassword) {
                errorMessage.textContent = 'Passwords do not match';
                errorMessage.style.display = 'block';
                return;
              }
              
              // Send reset request
              fetch('/reset_password', {
                method: 'POST',
                headers: {
                  'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                  token: '${token}',
                  new_password: password
                })
              })
              .then(response => response.json())
              .then(data => {
                if (data.return_code === 'SUCCESS') {
                  // Show success message
                  document.getElementById('password').value = '';
                  document.getElementById('confirmPassword').value = '';
                  successMessage.style.display = 'block';
                } else {
                  // Show error message
                  errorMessage.textContent = data.message || 'An error occurred while resetting your password';
                  errorMessage.style.display = 'block';
                }
              })
              .catch(error => {
                errorMessage.textContent = 'An error occurred while resetting your password';
                errorMessage.style.display = 'block';
                console.error('Error:', error);
              });
            }
          </script>
        </body>
      </html>
    `);
  } catch (error) {
    console.error('Error showing password reset form:', error);
    return res.status(500).send(`
      <html>
        <head>
          <title>Password Reset Error</title>
          <style>
            body { font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px; text-align: center; }
            .error { color: #d32f2f; }
            h1 { color: #1976d2; }
          </style>
        </head>
        <body>
          <h1>Password Reset Error</h1>
          <p class="error">An error occurred while processing your password reset request.</p>
          <p>Please try again later or contact support.</p>
        </body>
      </html>
    `);
  }
});

module.exports = router;
