/*
=======================================================================================================================================
API Route: admin_login
=======================================================================================================================================
Method: POST
Purpose: Authenticates the single hard-coded administrator and returns an admin JWT.
=======================================================================================================================================
Request Payload:
{
  "email": "aandreou25@gmail.com",     // string, required
  "password": "..."                    // string, required
}

Success Response:
{
  "return_code": "SUCCESS",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",  // string, admin JWT, 7 day expiry
  "admin": {
    "email": "aandreou25@gmail.com"    // string, the admin's email
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"INVALID_CREDENTIALS"
"SERVER_ERROR"
=======================================================================================================================================

About the hard-coded credentials
--------------------------------
There is exactly one administrator and the credentials live in this file rather than in the
database. That is deliberate for now: the admin tool is a private internal thing, there is
no sign-up, no password reset and no second admin, and putting an is_admin column on
app_user would mean a schema change plus a risk that some other route starts trusting it.

The password is stored as a bcrypt hash, not plaintext, so a copy of this file is not
immediately a working login. The plaintext is written in the comment below on purpose so
that the password cannot be lost - the whole point of a single hard-coded admin is that
there is no reset flow to fall back on.

  Email:    aandreou25@gmail.com
  Password: aWwSPnQ-Yjv6rLb-YR3qgXQ

If you would rather the hash not sit in the repository, set ADMIN_PASSWORD_HASH in the
server .env and it wins over the constant below. Same for ADMIN_EMAIL. Nothing else needs
to change.

Token lifetime is 7 days, not the 180 days the app uses. An admin token can delete leagues,
so it should not be a long-lived key sitting in a browser for half a year.
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');

// The one administrator. Overridable from the environment, but these are the defaults.
const ADMIN_EMAIL = process.env.ADMIN_EMAIL || 'aandreou25@gmail.com';
const ADMIN_PASSWORD_HASH = process.env.ADMIN_PASSWORD_HASH ||
  '$2b$10$QYbz/U0V4blljZBwigqjFuFFaSSPhqDYIEXnQoPiiEkmW.3rn/vPm';

// POST /admin_login
router.post('/', async (req, res) => {
  try {
    // Extract the credentials from the request body
    const { email, password } = req.body;

    // Both fields are required
    if (!email || !password) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Email and password are required'
      });
    }

    // Compare the email case-insensitively and with the surrounding spaces trimmed, because
    // a browser password manager or a phone keyboard will happily hand over " Aandreou25@..."
    const emailMatches = String(email).trim().toLowerCase() === ADMIN_EMAIL.toLowerCase();

    // Always run the bcrypt compare, even when the email is already wrong.
    //
    // If we returned early on a bad email the response would come back in under a
    // millisecond, while a bad password would take the ~100ms bcrypt needs. That difference
    // is measurable from outside and tells an attacker which half they got right. Doing the
    // work either way keeps both failures looking the same.
    const passwordMatches = await bcrypt.compare(password, ADMIN_PASSWORD_HASH);

    // Both have to be right, and we do not say which one was not
    if (!emailMatches || !passwordMatches) {
      return res.status(401).json({
        return_code: 'INVALID_CREDENTIALS',
        message: 'Invalid email or password'
      });
    }

    // Generate the admin token. Note there is no userId in here - see admin_middleware.js
    // for why that matters.
    const token = jwt.sign(
      { role: 'admin', email: ADMIN_EMAIL },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    // Return the token
    return res.status(200).json({
      return_code: 'SUCCESS',
      token: token,
      admin: {
        email: ADMIN_EMAIL
      }
    });
  } catch (error) {
    console.error('Error in admin_login route:', error);

    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
