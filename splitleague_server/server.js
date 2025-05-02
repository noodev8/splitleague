/*
=======================================================================================================================================
Server: server.js
=======================================================================================================================================
Purpose: Main entry point for the SplitLeague API server
=======================================================================================================================================
*/

const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Initialize Express app
const app = express();

// Middleware
app.use(cors());
app.use(express.json());

// Import routes
const register_user = require('./routes/register_user');
const login_user = require('./routes/login_user');
const create_league = require('./routes/create_league');
const join_league = require('./routes/join_league');
const get_user_leagues = require('./routes/get_user_leagues');
const generate_fixtures = require('./routes/generate_fixtures');
const get_league_fixtures = require('./routes/get_league_fixtures');
const get_league_members = require('./routes/get_league_members');
const update_fixture_score = require('./routes/update_fixture_score');
const get_league_info = require('./routes/get_league_info');
const get_league_table = require('./routes/get_league_table');
const remove_player_from_league = require('./routes/remove_player_from_league');
const update_last_accessed = require('./routes/update_last_accessed');
const deactivate_league_membership = require('./routes/deactivate_league_membership');
const get_hidden_leagues = require('./routes/get_hidden_leagues');
const reactivate_league_membership = require('./routes/reactivate_league_membership');
const void_fixture = require('./routes/void_fixture');

// Import email and password management routes
const verify_email = require('./routes/verify_email');
const verify_web_email = require('./routes/verify_web_email');
const resend_verification = require('./routes/resend_verification');
const forgot_password = require('./routes/forgot_password');
const reset_password = require('./routes/reset_password');
const reset_password_web = require('./routes/reset_password_web');
const change_password = require('./routes/change_password');
const update_profile = require('./routes/update_profile');

// Import app version route
const get_app_version = require('./routes/get_app_version');

// Import account deletion route
const delete_account = require('./routes/delete_account');

// Use routes
app.use('/register_user', register_user);
app.use('/login_user', login_user);
app.use('/create_league', create_league);
app.use('/join_league', join_league);
app.use('/get_user_leagues', get_user_leagues);
app.use('/generate_fixtures', generate_fixtures);
app.use('/get_league_fixtures', get_league_fixtures);
app.use('/get_league_members', get_league_members);
app.use('/update_fixture_score', update_fixture_score);
app.use('/get_league_info', get_league_info);
app.use('/get_league_table', get_league_table);
app.use('/remove_player_from_league', remove_player_from_league);
app.use('/update_last_accessed', update_last_accessed);
app.use('/deactivate_league_membership', deactivate_league_membership);
app.use('/get_hidden_leagues', get_hidden_leagues);
app.use('/reactivate_league_membership', reactivate_league_membership);
app.use('/void_fixture', void_fixture);

// Use email and password management routes
app.use('/verify_email', verify_email);
app.use('/verify_web_email', verify_web_email);
app.use('/resend_verification', resend_verification);
app.use('/forgot_password', forgot_password);
app.use('/reset_password', reset_password);
app.use('/reset_password_web', reset_password_web);
app.use('/change_password', change_password);
app.use('/update_profile', update_profile);

// Use app version route
app.use('/get_app_version', get_app_version);

// Use account deletion route
app.use('/delete_account', delete_account);

// Root route
app.get('/', (req, res) => {
    res.json({ message: 'Welcome to SplitLeague API' });
});

//const PORT = process.env.PORT || 3003;
//app.listen(PORT, '0.0.0.0', () => console.log(`✅ Server running on port ${PORT}`);

// Start server
const PORT = process.env.PORT || 3003;
app.listen(PORT, '0.0.0.0', () => {
     console.log(`✅ Server running on port ${PORT}`);
 });
