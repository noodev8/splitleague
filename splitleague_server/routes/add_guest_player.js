/*
=======================================================================================================================================
API Route: add_guest_player
=======================================================================================================================================
Method: POST
Purpose: Allows a league organizer to add a guest player to their league without requiring the player to register.
         Creates a guest user account and adds them to the specified league.
=======================================================================================================================================
Request Payload:
{
  "league_id": 1,                      // integer, required - ID of the league
  "guest_nickname": "Guest Player"     // string, optional - Custom nickname for the guest (defaults to "Guest Player" if not provided)
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Guest player successfully added to the league",
  "guest_user": {
    "id": 123,                         // integer, unique user ID of the created guest
    "nickname": "guest_nickname"       // string, the guest's nickname with guest_ prefix
  }
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"LEAGUE_NOT_FOUND"
"NOT_ORGANIZER"
"FIXTURES_EXIST"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');
const bcrypt = require('bcrypt');

// POST /add_guest_player
router.post('/', verifyToken, async (req, res) => {
  // Start a database transaction to ensure all operations succeed or fail together
  const client = await pool.connect();
  
  try {
    // Extract data from request body
    const { league_id, guest_nickname } = req.body;
    
    // Check if league_id is provided
    if (!league_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League ID is required'
      });
    }
    
    // Get the authenticated user ID from the token (the organizer)
    const organizerId = req.userId;
    
    // Begin transaction
    await client.query('BEGIN');
    
    // Check if the league exists
    const leagueResult = await client.query(
      'SELECT * FROM league WHERE id = $1',
      [league_id]
    );
    
    // If league doesn't exist, return error
    if (leagueResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found'
      });
    }
    
    const league = leagueResult.rows[0];
    
    // Check if the authenticated user is the organizer of the league
    if (league.created_by !== organizerId) {
      await client.query('ROLLBACK');
      return res.status(403).json({
        return_code: 'NOT_ORGANIZER',
        message: 'Only the league organizer can add guest players'
      });
    }
    
    // Check if fixtures have been generated for this league
    const fixturesResult = await client.query(
      'SELECT COUNT(*) FROM fixture WHERE league_id = $1',
      [league_id]
    );
    
    // If fixtures exist, return error
    if (parseInt(fixturesResult.rows[0].count) > 0) {
      await client.query('ROLLBACK');
      return res.status(400).json({
        return_code: 'FIXTURES_EXIST',
        message: 'Cannot add guest player because fixtures have already been generated'
      });
    }
    
    // Set default guest nickname if not provided
    const baseNickname = guest_nickname || 'Guest Player';
    
    // Add 'guest_' prefix to the nickname for display
    const displayNickname = `guest_${baseNickname}`;
    
    // Hash the password (using 'guest' as the password)
    const saltRounds = 10;
    const passwordHash = await bcrypt.hash('guest', saltRounds);
    
    // Insert the guest user into the app_user table
    const insertUserResult = await client.query(
      `INSERT INTO app_user 
       (name, nickname, email, password_hash, email_verified, created_at) 
       VALUES ($1, $2, $3, $4, $5, CURRENT_TIMESTAMP) 
       RETURNING id`,
      ['guest', displayNickname, 'guest', passwordHash, true]
    );
    
    // Get the newly created guest user ID
    const guestUserId = insertUserResult.rows[0].id;
    
    // Add the guest user to the league_members table
    await client.query(
      `INSERT INTO league_members 
       (league_id, user_id, active, joined_at, last_accessed) 
       VALUES ($1, $2, true, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)`,
      [league_id, guestUserId]
    );
    
    // Commit the transaction
    await client.query('COMMIT');
    
    // Return success response with guest user details
    return res.status(201).json({
      return_code: 'SUCCESS',
      message: 'Guest player successfully added to the league',
      guest_user: {
        id: guestUserId,
        nickname: displayNickname
      }
    });
    
  } catch (error) {
    // Rollback the transaction in case of error
    await client.query('ROLLBACK');
    
    console.error('Error adding guest player:', error);
    
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while adding the guest player'
    });
    
  } finally {
    // Release the client back to the pool
    client.release();
  }
});

module.exports = router;
