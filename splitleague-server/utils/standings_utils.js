/*
=======================================================================================================================================
Utility: standings_utils
=======================================================================================================================================
Purpose: Works out a league table from its fixtures, applying that league's scoring rules.

This lives in one place on purpose. The in-app standings (get_league_table) and the public
read-only league page (public_league) both call it, so the table a player sees in the app and
the table someone sees on a shared link can never drift apart. If you change the scoring rules,
change them here and both follow.

Three scoring systems are supported, chosen by league_points.win_type:

  PTS  Points-based, e.g. snooker. Real scores are recorded. Points for a win, an optional bonus
       for winning by a margin, optional consolation points for a close loss, points for a draw.
  WIN  Win only, e.g. pool. Stored as 1-0 or 0-1. Points for a win, nothing else.
  WDL  Win/Draw/Loss, e.g. football. Stored as 1-0, 0-1, or 1-1. Points for a win or a draw.
=======================================================================================================================================
*/

// Work out the league table
//
// league   - a row joining league and league_points, so it carries win_type, points_for_win,
//            points_for_draw, points_for_win_margin, points_for_close_loss, win_margin_threshold
// members  - rows of { user_id, name, nickname }
// fixtures - PLAYED fixtures only, rows of { player_1_id, player_2_id, player_1_score, player_2_score }
//
// Returns the standings sorted best first.
const calculateStandings = (league, members, fixtures) => {

  const winType = league.win_type;

  // Start every member on zero
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
      playerStats.base_points = 0;
      playerStats.bonus_points = 0;
    }

    return playerStats;
  });

  // Walk every played fixture and apply the league's rules
  fixtures.forEach(fixture => {

    // Find the players in our standings array
    const player1Index = standings.findIndex(p => p.user_id === fixture.player_1_id);
    const player2Index = standings.findIndex(p => p.user_id === fixture.player_2_id);

    // Skip if either player is not found - happens if a player was removed from the league
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
        standings[player1Index].base_points += league.points_for_win;

        // Bonus points for winning by margin
        const margin = fixture.player_1_score - fixture.player_2_score;
        if (margin >= league.win_margin_threshold) {
          standings[player1Index].points += league.points_for_win_margin;
          standings[player1Index].bonus_points += league.points_for_win_margin;
        }

        // Points for close loss
        if (margin < league.win_margin_threshold) {
          standings[player2Index].points += league.points_for_close_loss;
          standings[player2Index].bonus_points += league.points_for_close_loss;
        }
      } else if (fixture.player_2_score > fixture.player_1_score) {
        // Player 2 wins
        standings[player2Index].won++;
        standings[player1Index].lost++;

        // Base points for win
        standings[player2Index].points += league.points_for_win;
        standings[player2Index].base_points += league.points_for_win;

        // Bonus points for winning by margin
        const margin = fixture.player_2_score - fixture.player_1_score;
        if (margin >= league.win_margin_threshold) {
          standings[player2Index].points += league.points_for_win_margin;
          standings[player2Index].bonus_points += league.points_for_win_margin;
        }

        // Points for close loss
        if (margin < league.win_margin_threshold) {
          standings[player1Index].points += league.points_for_close_loss;
          standings[player1Index].bonus_points += league.points_for_close_loss;
        }
      } else {
        // Draw (equal scores)
        standings[player1Index].drawn += 1;
        standings[player2Index].drawn += 1;

        // Points for draw
        standings[player1Index].points += league.points_for_draw;
        standings[player2Index].points += league.points_for_draw;
        standings[player1Index].base_points += league.points_for_draw;
        standings[player2Index].base_points += league.points_for_draw;
      }
    } else if (winType === 'WIN') {
      // Win-only league (like Pool)

      // In WIN type, we store the result as:
      // player_1_score = 1, player_2_score = 0 (player 1 wins)
      // player_1_score = 0, player_2_score = 1 (player 2 wins)
      if (fixture.player_1_score === 1 && fixture.player_2_score === 0) {
        // Player 1 wins
        standings[player1Index].won++;
        standings[player2Index].lost++;
        standings[player1Index].points += league.points_for_win;
      } else if (fixture.player_1_score === 0 && fixture.player_2_score === 1) {
        // Player 2 wins
        standings[player2Index].won++;
        standings[player1Index].lost++;
        standings[player2Index].points += league.points_for_win;
      }
    } else if (winType === 'WDL') {
      // Win/Draw/Loss league (like Football)

      // In WDL type, we store the result as:
      // player_1_score = 1, player_2_score = 0 (player 1 wins)
      // player_1_score = 0, player_2_score = 1 (player 2 wins)
      // player_1_score = 1, player_2_score = 1 (draw)
      if (fixture.player_1_score === 1 && fixture.player_2_score === 0) {
        // Player 1 wins
        standings[player1Index].won++;
        standings[player2Index].lost++;
        standings[player1Index].points += league.points_for_win;
      } else if (fixture.player_1_score === 0 && fixture.player_2_score === 1) {
        // Player 2 wins
        standings[player2Index].won++;
        standings[player1Index].lost++;
        standings[player2Index].points += league.points_for_win;
      } else if (fixture.player_1_score === 1 && fixture.player_2_score === 1) {
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

  return standings;
};

module.exports = { calculateStandings };
