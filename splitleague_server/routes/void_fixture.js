/*
=======================================================================================================================================
API Route: void_fixture
=======================================================================================================================================
Method: POST
Purpose: Allows the client to void (delete) a fixture from the system
=======================================================================================================================================
Request Payload:
{
  "fixture_id": 123                    // integer, required - The ID of the fixture to void
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Fixture successfully voided"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"
"FIXTURE_NOT_FOUND"
"MISSING_FIELDS"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /void_fixture
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract fixture_id from request body
    const { fixture_id } = req.body;
    
    // Validate that fixture_id is provided
    if (!fixture_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Fixture ID is required'
      });
    }
    
    // Get the current user ID from the token
    const userId = req.userId;
    
    // First, check if the fixture exists and get league information
    const fixtureResult = await pool.query(
      `SELECT f.*, l.created_by as league_creator
       FROM fixture f
       JOIN league l ON f.league_id = l.id
       WHERE f.id = $1`,
      [fixture_id]
    );
    
    // If no fixture found, return error
    if (fixtureResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'FIXTURE_NOT_FOUND',
        message: 'Fixture not found'
      });
    }
    
    const fixture = fixtureResult.rows[0];
    
    // Check if user is authorized to void the fixture
    // Only the league creator should be able to void fixtures
    if (fixture.league_creator != userId) {
      return res.status(403).json({
        return_code: 'UNAUTHORIZED',
        message: 'Only the league organizer can void fixtures'
      });
    }
    
    // Delete the fixture from the database
    await pool.query(
      'DELETE FROM fixture WHERE id = $1',
      [fixture_id]
    );
    
    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'Fixture successfully voided'
    });
    
  } catch (error) {
    // Log the error for debugging
    console.error('Error in void_fixture route:', error);
    
    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
