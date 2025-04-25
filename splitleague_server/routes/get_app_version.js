/*
=======================================================================================================================================
API Route: get_app_version
=======================================================================================================================================
Method: POST
Purpose: Retrieves the minimum required app version for a specific platform from the app_version_requirement table.
=======================================================================================================================================
Request Payload:
{
  "platform": "android"                // string, required - The platform to get the minimum version for (e.g., "android", "ios")
}

Success Response:
{
  "return_code": "SUCCESS",
  "platform": "android",               // string - The platform requested
  "minimum_version": "1.0"             // string - The minimum required version for the platform
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"PLATFORM_NOT_FOUND"
"MISSING_FIELDS"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const pool = require('../db');

// POST /get_app_version
router.post('/', async (req, res) => {
  try {
    // Extract platform from request body
    const { platform } = req.body;
    
    // Check if platform is provided
    if (!platform) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'Platform is required'
      });
    }
    
    // Query the database for the minimum version for the specified platform
    const versionResult = await pool.query(
      'SELECT platform, minimum_version FROM app_version_requirement WHERE platform = $1',
      [platform.toLowerCase()]
    );
    
    // Check if a record was found for the platform
    if (versionResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'PLATFORM_NOT_FOUND',
        message: `No version requirement found for platform: ${platform}`
      });
    }
    
    // Get the version data
    const versionData = versionResult.rows[0];
    
    // Return success response with platform and minimum version
    return res.status(200).json({
      return_code: 'SUCCESS',
      platform: versionData.platform,
      minimum_version: versionData.minimum_version.toString()
    });
  } catch (error) {
    console.error('Error in get_app_version route:', error);
    
    // Return server error response
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while processing your request'
    });
  }
});

module.exports = router;
