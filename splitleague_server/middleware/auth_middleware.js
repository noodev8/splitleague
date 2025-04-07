/*
=======================================================================================================================================
Middleware: auth_middleware.js
=======================================================================================================================================
Purpose: Middleware to verify JWT tokens and protect routes
=======================================================================================================================================
*/

const jwt = require('jsonwebtoken');

// Middleware to verify JWT token
const verifyToken = (req, res, next) => {
  // Get the token from the Authorization header
  const authHeader = req.headers.authorization;
  
  // Check if token exists
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      return_code: 'UNAUTHORIZED',
      message: 'No token provided'
    });
  }
  
  // Extract the token
  const token = authHeader.split(' ')[1];
  
  try {
    // Verify the token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    // Add the user ID to the request object
    req.userId = decoded.userId;
    
    // Continue to the next middleware or route handler
    next();
  } catch (error) {
    // Return error if token is invalid
    return res.status(401).json({
      return_code: 'UNAUTHORIZED',
      message: 'Invalid token'
    });
  }
};

module.exports = verifyToken;
