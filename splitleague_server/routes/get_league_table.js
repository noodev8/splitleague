/*
=======================================================================================================================================
API Route: get_league_table
=======================================================================================================================================
Method: POST
Purpose: Calculates and returns the league table standings based on the league's points rules.
=======================================================================================================================================
Request Payload:
{
  "league_id": 1                       // integer, required - The ID of the league to get standings for
}

Success Response:
{
  "return_code": "SUCCESS",
  "standings": [
    {
      "user_id": 123,                  // integer, the user's ID
      "name": "John Doe",              // string, the user's name
      "nickname": "Johnny",            // string, the user's nickname
      "played": 10,                    // integer, number of games played
      "won": 5,                        // integer, number of games won
      "drawn": 2,                      // integer, number of games drawn (only for WDL leagues)
      "lost": 3,                       // integer, number of games lost
      "points": 17,                    // integer, total points
      "score_for": 25,                 // integer, total score for (only for PTS leagues)
      "score_against": 18,             // integer, total score against (only for PTS leagues)
      "score_diff": 7                  // integer, score difference (only for PTS leagues)
    },
    // More players...
  ]
}
=======================================================================================================================================
Return Codes:
"SUCCESS"
"MISSING_FIELDS"
"LEAGUE_NOT_FOUND"
"NOT_A_MEMBER"
"SERVER_ERROR"
=======================================================================================================================================
*/

const express = require('express');
const router = express.Router();
const db = require('../db');
const verifyToken = require('../middleware/auth_middleware');

// Apply authentication middleware to this route
router.post('/', verifyToken, async (req, res) => {
  try {
    // Extract league_id from request body
    const { league_id } = req.body;

    // Validate required fields
    if (!league_id) {
      return res.status(400).json({
        return_code: 'MISSING_FIELDS',
        message: 'League ID is required'
      });
    }

    // Get the authenticated user's ID from the token
    const userId = req.userId;

    // Check if the league exists
    const leagueQuery = `
      SELECT l.*, lp.win_type, lp.points_for_win, lp.points_for_draw,
             lp.points_for_win_margin, lp.points_for_close_loss, lp.win_margin_threshold
      FROM league l
      JOIN league_points lp ON l.id = lp.league_id
      WHERE l.id = $1
    `;

    const leagueResult = await db.query(leagueQuery, [league_id]);

    // If league doesn't exist, return error
    if (leagueResult.rows.length === 0) {
      return res.status(404).json({
        return_code: 'LEAGUE_NOT_FOUND',
        message: 'League not found'
      });
    }

    // Get league details
    const league = leagueResult.rows[0];
    const winType = league.win_type;

    // Check if the user is a member of the league
    const membershipQuery = `
      SELECT * FROM league_members
      WHERE league_id = $1 AND user_id = $2
      UNION
      SELECT * FROM league_members
      WHERE league_id = $1 AND user_id = (SELECT created_by FROM league WHERE id = $1)
    `;

    const membershipResult = await db.query(membershipQuery, [league_id, userId]);

    // If user is not a member or creator, return error
    if (membershipResult.rows.length === 0) {
      return res.status(403).json({
        return_code: 'NOT_A_MEMBER',
        message: 'You must be a member of the league to view the standings'
      });
    }

    // Get all league members
    const membersQuery = `
      SELECT lm.user_id, u.name, u.nickname
      FROM league_members lm
      JOIN app_user u ON lm.user_id = u.id
      WHERE lm.league_id = $1
      UNION
      SELECT u.id as user_id, u.name, u.nickname
      FROM app_user u
      JOIN league l ON u.id = l.created_by
      WHERE l.id = $1
    `;

    const membersResult = await db.query(membersQuery, [league_id]);
    const members = membersResult.rows;

    // Get all fixtures for the league
    const fixturesQuery = `
      SELECT * FROM fixture
      WHERE league_id = $1 AND played = true
    `;

    const fixturesResult = await db.query(fixturesQuery, [league_id]);
    const fixtures = fixturesResult.rows;

    // Initialize standings array with all members
    let standings = members.map(member => {
      // Base stats for all league types
      let playerStats = {
        user_id: member.user_id,
        name: member.name,
        nickname: member.nickname,
        played: 0,
        won: 0,
        lost: 0,
        points: 0,
        drawn: 0  // Always include drawn field for consistency
      };

      // Add specific stats for PTS leagues
      if (winType === 'PTS') {
        playerStats.score_for = 0;
        playerStats.score_against = 0;
        playerStats.score_diff = 0;
      }

      return playerStats;
    });

    // Calculate standings based on fixtures and league rules
    fixtures.forEach(fixture => {
      // Find the players in our standings array
      const player1Index = standings.findIndex(p => p.user_id === fixture.player_1_id);
      const player2Index = standings.findIndex(p => p.user_id === fixture.player_2_id);

      // Skip if either player is not found (shouldn't happen, but just in case)
      if (player1Index === -1 || player2Index === -1) {
        return;
      }

      // Increment games played for both players
      standings[player1Index].played++;
      standings[player2Index].played++;

      // Calculate points based on league type
      if (winType === 'PTS') {
        // Points-based league (like Snooker)

        // Update scores
        standings[player1Index].score_for += fixture.player_1_score;
        standings[player1Index].score_against += fixture.player_2_score;
        standings[player2Index].score_for += fixture.player_2_score;
        standings[player2Index].score_against += fixture.player_1_score;

        // Update score difference
        standings[player1Index].score_diff = standings[player1Index].score_for - standings[player1Index].score_against;
        standings[player2Index].score_diff = standings[player2Index].score_for - standings[player2Index].score_against;

        // Determine winner and loser
        if (fixture.player_1_score > fixture.player_2_score) {
          // Player 1 wins
          standings[player1Index].won++;
          standings[player2Index].lost++;

          // Base points for win
          standings[player1Index].points += league.points_for_win;

          // Bonus points for winning by margin
          const margin = fixture.player_1_score - fixture.player_2_score;
          if (margin >= league.win_margin_threshold) {
            standings[player1Index].points += league.points_for_win_margin;
          }

          // Points for close loss
          if (margin < league.win_margin_threshold) {
            standings[player2Index].points += league.points_for_close_loss;
          }
        } else if (fixture.player_2_score > fixture.player_1_score) {
          // Player 2 wins
          standings[player2Index].won++;
          standings[player1Index].lost++;

          // Base points for win
          standings[player2Index].points += league.points_for_win;

          // Bonus points for winning by margin
          const margin = fixture.player_2_score - fixture.player_1_score;
          if (margin >= league.win_margin_threshold) {
            standings[player2Index].points += league.points_for_win_margin;
          }

          // Points for close loss
          if (margin < league.win_margin_threshold) {
            standings[player1Index].points += league.points_for_close_loss;
          }
        } else {
          // Draw (equal scores)
          standings[player1Index].drawn += 1;
          standings[player2Index].drawn += 1;

          // Points for draw
          standings[player1Index].points += league.points_for_draw;
          standings[player2Index].points += league.points_for_draw;
        }
      } else if (winType === 'WIN') {
        // Win-only league (like Pool)

        // In WIN type, we store the result in player_1_score as 1 (player 1 wins) or 2 (player 2 wins)
        if (fixture.player_1_score === 1) {
          // Player 1 wins
          standings[player1Index].won++;
          standings[player2Index].lost++;
          standings[player1Index].points += league.points_for_win;
        } else if (fixture.player_1_score === 2) {
          // Player 2 wins
          standings[player2Index].won++;
          standings[player1Index].lost++;
          standings[player2Index].points += league.points_for_win;
        }
      } else if (winType === 'WDL') {
        // Win/Draw/Loss league (like Football)

        // In WDL type, we store the result in player_1_score as:
        // 1 (player 1 wins), 2 (player 2 wins), or 0 (draw)
        if (fixture.player_1_score === 1) {
          // Player 1 wins
          standings[player1Index].won++;
          standings[player2Index].lost++;
          standings[player1Index].points += league.points_for_win;
        } else if (fixture.player_1_score === 2) {
          // Player 2 wins
          standings[player2Index].won++;
          standings[player1Index].lost++;
          standings[player2Index].points += league.points_for_win;
        } else if (fixture.player_1_score === 0) {
          // Draw
          standings[player1Index].drawn++;
          standings[player2Index].drawn++;
          standings[player1Index].points += league.points_for_draw;
          standings[player2Index].points += league.points_for_draw;
        }
      }
    });

    // Sort standings by points (highest first)
    standings.sort((a, b) => {
      // First sort by points
      if (b.points !== a.points) {
        return b.points - a.points;
      }

      // If points are equal and it's a points-based league, sort by score difference
      if (winType === 'PTS' && b.score_diff !== a.score_diff) {
        return b.score_diff - a.score_diff;
      }

      // If still equal, sort by games won
      if (b.won !== a.won) {
        return b.won - a.won;
      }

      // If still equal, sort by games played (fewer games is better)
      if (a.played !== b.played) {
        return a.played - b.played;
      }

      // If everything is equal, sort alphabetically by name
      return a.name.localeCompare(b.name);
    });

    // Return the standings
    return res.json({
      return_code: 'SUCCESS',
      standings: standings
    });

  } catch (error) {
    console.error('Error getting league table:', error);
    return res.status(500).json({
      return_code: 'SERVER_ERROR',
      message: 'An error occurred while getting the league table'
    });
  }
});

module.exports = router;
