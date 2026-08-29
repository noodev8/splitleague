/*
Accessibility helper for the SplitLeague app
Provides utilities for improving accessibility
*/

// import 'package:flutter/material.dart';

/// Accessibility helper class
class AccessibilityHelper {
  /// Helper method to remove 'guest_' prefix from player names
  static String _formatPlayerName(String name) {
    if (name.startsWith('guest_')) {
      return name.substring(6); // Remove 'guest_' prefix
    }
    return name;
  }

  /// Returns a semantics label for a fixture card
  static String getFixtureLabel(Map<String, dynamic> fixture) {
    final String rawPlayer1 = fixture['player_1_nickname'] ?? fixture['player_1_name'] ?? 'Player 1';
    final String rawPlayer2 = fixture['player_2_nickname'] ?? fixture['player_2_name'] ?? 'Player 2';
    final player1 = _formatPlayerName(rawPlayer1);
    final player2 = _formatPlayerName(rawPlayer2);
    final date = fixture['scheduled_date'] ?? 'Unscheduled';
    final played = fixture['played'] == true;

    if (played) {
      final score1 = fixture['player_1_score'] ?? 0;
      final score2 = fixture['player_2_score'] ?? 0;
      return 'Played match. $player1 versus $player2. Score: $score1 to $score2. Date: $date';
    } else {
      return 'Upcoming match. $player1 versus $player2. Date: $date';
    }
  }

  /// Returns a semantics label for a league card
  static String getLeagueLabel(Map<String, dynamic> league) {
    final name = league['name'] ?? 'Unnamed League';
    final playerCount = league['player_count'] ?? 0;
    final isOrganizer = league['is_organizer'] == true;
    final hasFixtures = league['has_fixtures'] == true;

    String status = hasFixtures ? 'Active' : 'Not started';
    String role = isOrganizer ? 'You are the organizer' : 'You are a member';

    return '$name. $playerCount players. Status: $status. $role';
  }

  /// Returns a semantics label for a standings row
  static String getStandingsRowLabel(Map<String, dynamic> player, int position, String? winType) {
    final String rawName = player['nickname'] ?? player['name'] ?? 'Unknown';
    final name = _formatPlayerName(rawName);
    final played = player['played'] ?? 0;
    final points = player['points'] ?? 0;
    final isCurrentUser = player['is_current_user'] == true;

    String userIndicator = isCurrentUser ? 'You are ' : '';

    if (winType == 'WIN') {
      return '$userIndicator$name. Position $position. Played $played matches. Won $points matches.';
    } else {
      final won = player['won'] ?? 0;
      final drawn = player['drawn'] ?? 0;
      final lost = player['lost'] ?? 0;

      if (winType == 'WDL') {
        return '$userIndicator$name. Position $position. Played $played matches. Won $won, drawn $drawn, lost $lost. Points: $points.';
      } else if (winType == 'PTS') {
        final bonusPoints = player['bonus_points'] ?? 0;
        return '$userIndicator$name. Position $position. Played $played matches. Won $won, lost $lost. Bonus points: $bonusPoints. Total points: $points.';
      } else {
        return '$userIndicator$name. Position $position. Played $played matches. Won $won, lost $lost. Points: $points.';
      }
    }
  }

  /// Returns a semantics label for a tab
  static String getTabLabel(String tabName, bool isSelected) {
    return '$tabName tab, ${isSelected ? 'selected' : 'not selected'}';
  }
}
