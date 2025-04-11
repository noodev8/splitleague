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
const register = require('./routes/register_user');
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

// Use routes
app.use('/register', register);
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

// Root route
app.get('/', (req, res) => {
    res.json({ message: 'Welcome to SplitLeague API' });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`✅ Server running on port ${PORT}`);
});
