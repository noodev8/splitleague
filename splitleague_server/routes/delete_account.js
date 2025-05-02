/*
=======================================================================================================================================
API Route: delete_account
=======================================================================================================================================
Method: POST
Purpose: Deletes a user account and all associated data for GDPR compliance. Logs the deletion in the deletion_log table.
=======================================================================================================================================
Request Payload:
{
  "reason": "string, optional - reason for account deletion"
}

Success Response:
{
  "return_code": "SUCCESS",
  "message": "Account successfully deleted"
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"UNAUTHORIZED"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// POST /delete_account
router.post('/', verifyToken, async (req, res) => {
  // Start a database transaction to ensure all operations succeed or fail together
  const client = await pool.connect();
  
  try {
    // Get the user ID from the authenticated token
    const userId = req.userId;
    const { reason } = req.body;
    
    // Begin transaction
    await client.query('BEGIN');
    
    // First, get user details for logging purposes before deletion
    const userResult = await client.query(
      'SELECT id, email FROM app_user WHERE id = $1',
      [userId]
    );
    
    // Check if user exists
    if (userResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        return_code: 'UNAUTHORIZED',
        message: 'User not found'
      });
    }
    
    const userEmail = userResult.rows[0].email;
    
    // Log the deletion in the deletion_log table
    await client.query(
      'INSERT INTO deletion_log (user_id, email, deletion_method, requested_by, reason) VALUES ($1, $2, $3, $4, $5)',
      [userId, userEmail, 'USER_REQUESTED', userId, reason || 'User requested account deletion']
    );
    
    // Delete all fixtures where the user is player_1 or player_2
    // This needs to be done before deleting from league_members to maintain referential integrity
    await client.query(
      'DELETE FROM fixture WHERE player_1_id = $1 OR player_2_id = $1',
      [userId]
    );
    
    // Get leagues created by this user
    const createdLeaguesResult = await client.query(
      'SELECT id FROM league WHERE created_by = $1',
      [userId]
    );
    
    // For each league created by this user
    for (const row of createdLeaguesResult.rows) {
      const leagueId = row.id;
      
      // Delete league points for leagues created by this user
      await client.query(
        'DELETE FROM league_points WHERE league_id = $1',
        [leagueId]
      );
      
      // Delete all fixtures for leagues created by this user
      await client.query(
        'DELETE FROM fixture WHERE league_id = $1',
        [leagueId]
      );
      
      // Delete all league members for leagues created by this user
      await client.query(
        'DELETE FROM league_members WHERE league_id = $1',
        [leagueId]
      );
    }
    
    // Delete leagues created by this user
    await client.query(
      'DELETE FROM league WHERE created_by = $1',
      [userId]
    );
    
    // Delete user's league memberships
    await client.query(
      'DELETE FROM league_members WHERE user_id = $1',
      [userId]
    );
    
    // Finally, delete the user account
    await client.query(
      'DELETE FROM app_user WHERE id = $1',
      [userId]
    );
    
    // Commit the transaction
    await client.query('COMMIT');
    
    // Return success response
    return res.status(200).json({
      return_code: 'SUCCESS',
      message: 'Account successfully deleted'
    });
    
  } catch (error) {
    // Rollback the transaction in case of error
    await client.query('ROLLBACK');
    
    console.error('Error in delete_account route:', error);
    
    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  } finally {
    // Release the client back to the pool
    client.release();
  }
});

module.exports = router;
