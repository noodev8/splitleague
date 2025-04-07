/*
=======================================================================================================================================
Middleware: auth.js
=======================================================================================================================================
Purpose: Verifies JWT tokens for protected routes and attaches the user ID to the request object
=======================================================================================================================================
*/

const jwt = require('jsonwebtoken');
require('dotenv').config();

// Middleware function to verify JWT token
const authenticateToken = (req, res, next) => {
    // Get the token from the Authorization header
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Format: "Bearer TOKEN"
    
    // If no token is provided
    if (!token) {
        return res.status(401).json({ 
            return_code: "UNAUTHORIZED", 
            message: "Authentication token is required" 
        });
    }
    
    // Verify the token
    jwt.verify(token, process.env.JWT_SECRET, (err, user) => {
        if (err) {
            return res.status(403).json({ 
                return_code: "INVALID_TOKEN", 
                message: "Invalid or expired token" 
            });
        }
        
        // If token is valid, save the user ID to the request object
        req.user = user;
        next();
    });
};

module.exports = authenticateToken;
