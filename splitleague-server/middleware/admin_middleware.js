/*
=======================================================================================================================================
Middleware: admin_middleware.js
=======================================================================================================================================
Purpose: Verifies the admin JWT and protects every /admin_* route.
=======================================================================================================================================

Why this exists separately from auth_middleware.js
--------------------------------------------------
The admin endpoints live on the same public API as the app's own routes, so they are
reachable by anybody who knows the URL. They therefore need their own door, and it must be
a different door from the one the app uses.

A normal user token is signed with { userId: 123 } and lasts 180 days. If the admin routes
simply used auth_middleware.js, every one of the 252 real users would be holding a key to
the admin tool. So an admin token instead carries { role: 'admin', email: ... } and no
userId, and this middleware refuses anything that does not say role === 'admin'.

The reverse also holds: an admin token has no userId, so auth_middleware.js sets
req.userId = undefined and the ordinary routes cannot be driven with it either. The two
token types are deliberately not interchangeable in either direction.

Both are signed with the same JWT_SECRET. That is fine - it is the claim inside the token
that separates them, and the secret is what stops anybody forging either one.
=======================================================================================================================================
*/

const jwt = require('jsonwebtoken');

// Middleware to verify an admin JWT token
const verifyAdmin = (req, res, next) => {
  // Get the token from the Authorization header
  const authHeader = req.headers.authorization;

  // Check a bearer token was actually sent
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      return_code: 'UNAUTHORIZED',
      message: 'No token provided'
    });
  }

  // Extract the token from "Bearer <token>"
  const token = authHeader.split(' ')[1];

  try {
    // Verify the signature and expiry
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // This is the check that matters. A valid signature is not enough - a perfectly
    // genuine user token has a valid signature too. It has to say it is an admin token.
    if (decoded.role !== 'admin') {
      return res.status(403).json({
        return_code: 'FORBIDDEN',
        message: 'Not an admin token'
      });
    }

    // Make the admin's email available to the route, mainly so deletions can be logged
    req.adminEmail = decoded.email;

    // Continue to the route handler
    next();
  } catch (error) {
    // Expired, tampered with, or signed with a different secret
    return res.status(401).json({
      return_code: 'UNAUTHORIZED',
      message: 'Invalid token'
    });
  }
};

module.exports = verifyAdmin;
