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

// Use routes
app.use('/register', register);
app.use('/login_user', login_user);
app.use('/create_league', create_league);
app.use('/join_league', join_league);
app.use('/get_user_leagues', get_user_leagues);
app.use('/generate_fixtures', generate_fixtures);
app.use('/get_league_fixtures', get_league_fixtures);

// Root route
app.get('/', (req, res) => {
    res.json({ message: 'Welcome to SplitLeague API' });
});

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`✅ Server running on port ${PORT}`);
});
