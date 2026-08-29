/*
Sample league model for guest users
Provides mock data for a sample league to demonstrate app features without API calls
*/

class SampleLeague {
  // Get a sample league object
  static Map<String, dynamic> getSampleLeague() {
    return {
      'league_id': 9999,
      'id': 9999,
      'name': 'Sample Football League',
      'creator_id': 1,
      'created_by': 1,
      'public_code': '1234',
      'active': true,
      'allow_code_share': true,
      'is_creator': false,
      'created_at': DateTime.now().toString(),
      'last_accessed': DateTime.now().toString(),
      'win_type': 'WDL', // Win/Draw/Loss
      'points_for_win': 3,
      'points_for_draw': 1,
      'points_for_loss': 0,
      'points_for_win_margin': 0,
      'points_for_close_loss': 0,
      'win_margin_threshold': 0,
      'play_each_other': 2,
    };
  }

  // Get sample league members
  static List<Map<String, dynamic>> getSampleMembers() {
    return [
      {
        'id': 1,
        'user_id': 1,
        'name': 'John Smith',
        'nickname': 'John',
        'email': 'john@example.com',
      },
      {
        'id': 2,
        'user_id': 2,
        'name': 'Sarah Johnson',
        'nickname': 'Sarah',
        'email': 'sarah@example.com',
      },
      {
        'id': 3,
        'user_id': 3,
        'name': 'Michael Brown',
        'nickname': 'Mike',
        'email': 'mike@example.com',
      },
      {
        'id': 4,
        'user_id': 4,
        'name': 'Emma Wilson',
        'nickname': 'Emma',
        'email': 'emma@example.com',
      },
    ];
  }

  // Get sample fixtures
  static List<Map<String, dynamic>> getSampleFixtures() {
    return [
      {
        'id': 1,
        'league_id': 9999,
        'player_1_id': 1,
        'player_2_id': 2,
        'player_1_name': 'John',
        'player_2_name': 'Sarah',
        'player_1_score': 2,
        'player_2_score': 1,
        'played': true,
        'created_at': _getDateString(-14), // 14 days ago
        'updated_at': _getDateString(-14),
      },
      {
        'id': 2,
        'league_id': 9999,
        'player_1_id': 3,
        'player_2_id': 4,
        'player_1_name': 'Mike',
        'player_2_name': 'Emma',
        'player_1_score': 0,
        'player_2_score': 3,
        'played': true,
        'created_at': _getDateString(-13), // 13 days ago
        'updated_at': _getDateString(-13),
      },
      {
        'id': 3,
        'league_id': 9999,
        'player_1_id': 1,
        'player_2_id': 3,
        'player_1_name': 'John',
        'player_2_name': 'Mike',
        'player_1_score': 1,
        'player_2_score': 1,
        'played': true,
        'created_at': _getDateString(-10), // 10 days ago
        'updated_at': _getDateString(-10),
      },
      {
        'id': 4,
        'league_id': 9999,
        'player_1_id': 2,
        'player_2_id': 4,
        'player_1_name': 'Sarah',
        'player_2_name': 'Emma',
        'player_1_score': 2,
        'player_2_score': 2,
        'played': true,
        'created_at': _getDateString(-7), // 7 days ago
        'updated_at': _getDateString(-7),
      },
      {
        'id': 5,
        'league_id': 9999,
        'player_1_id': 1,
        'player_2_id': 4,
        'player_1_name': 'John',
        'player_2_name': 'Emma',
        'player_1_score': 0,
        'player_2_score': 1,
        'played': true,
        'created_at': _getDateString(-3), // 3 days ago
        'updated_at': _getDateString(-3),
      },
      {
        'id': 6,
        'league_id': 9999,
        'player_1_id': 2,
        'player_2_id': 3,
        'player_1_name': 'Sarah',
        'player_2_name': 'Mike',
        'player_1_score': 3,
        'player_2_score': 0,
        'played': true,
        'created_at': _getDateString(-1), // 1 day ago
        'updated_at': _getDateString(-1),
      },
      {
        'id': 7,
        'league_id': 9999,
        'player_1_id': 1,
        'player_2_id': 2,
        'player_1_name': 'John',
        'player_2_name': 'Sarah',
        'player_1_score': null,
        'player_2_score': null,
        'played': false,
        'created_at': _getDateString(0), // Today
        'updated_at': _getDateString(0),
      },
      {
        'id': 8,
        'league_id': 9999,
        'player_1_id': 3,
        'player_2_id': 4,
        'player_1_name': 'Mike',
        'player_2_name': 'Emma',
        'player_1_score': null,
        'player_2_score': null,
        'played': false,
        'created_at': _getDateString(0), // Today
        'updated_at': _getDateString(0),
      },
    ];
  }

  // Get sample standings
  static List<Map<String, dynamic>> getSampleStandings() {
    return [
      {
        'user_id': 4,
        'name': 'Emma Wilson',
        'nickname': 'Emma',
        'played': 3,
        'won': 2,
        'drawn': 1,
        'lost': 0,
        'points': 7,
        'score_for': 6,
        'score_against': 2,
        'score_diff': 4,
      },
      {
        'user_id': 2,
        'name': 'Sarah Johnson',
        'nickname': 'Sarah',
        'played': 3,
        'won': 1,
        'drawn': 1,
        'lost': 1,
        'points': 4,
        'score_for': 6,
        'score_against': 4,
        'score_diff': 2,
      },
      {
        'user_id': 1,
        'name': 'John Smith',
        'nickname': 'John',
        'played': 3,
        'won': 1,
        'drawn': 1,
        'lost': 1,
        'points': 4,
        'score_for': 3,
        'score_against': 3,
        'score_diff': 0,
      },
      {
        'user_id': 3,
        'name': 'Michael Brown',
        'nickname': 'Mike',
        'played': 3,
        'won': 0,
        'drawn': 1,
        'lost': 2,
        'points': 1,
        'score_for': 1,
        'score_against': 7,
        'score_diff': -6,
      },
    ];
  }

  // Helper method to get a date string relative to today
  static String _getDateString(int daysOffset) {
    final date = DateTime.now().add(Duration(days: daysOffset));
    return date.toIso8601String();
  }
}
