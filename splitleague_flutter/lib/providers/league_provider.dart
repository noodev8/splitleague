import 'package:flutter/material.dart';
import '../api/get_fixtures_api.dart';
import '../api/get_league_info_api.dart';
import '../api/get_league_members_api.dart';
import '../api/get_standings_api.dart';
import '../api/generate_fixtures_api.dart';
import '../api/remove_player_from_league_api.dart';
import '../helpers/error_handler.dart';

class LeagueProvider extends ChangeNotifier {
  // Flag to track if the provider is disposed
  bool _disposed = false;

  @override
  void notifyListeners() {
    // Only notify if not disposed
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  // Reset the provider to allow reuse
  void reset() {
    _disposed = false;

    // We don't clear filter states here anymore
    // This allows filters to persist when navigating between screens
  }
  // League info
  Map<String, dynamic> _leagueInfo = {};
  Map<String, dynamic> get leagueInfo => _leagueInfo;
  bool _isLoadingLeagueInfo = true;
  bool get isLoadingLeagueInfo => _isLoadingLeagueInfo;
  String? _leagueInfoErrorMessage;
  String? get leagueInfoErrorMessage => _leagueInfoErrorMessage;

  // Fixtures
  List<Map<String, dynamic>> _fixtures = [];
  List<Map<String, dynamic>> get fixtures => _fixtures;
  List<Map<String, dynamic>> _filteredFixtures = [];
  List<Map<String, dynamic>> get filteredFixtures => _filteredFixtures;
  bool _isLoadingFixtures = true;
  bool get isLoadingFixtures => _isLoadingFixtures;
  String? _fixturesErrorMessage;
  String? get fixturesErrorMessage => _fixturesErrorMessage;

  // Track the last updated fixture ID for scrolling
  int? _lastUpdatedFixtureId;
  int? get lastUpdatedFixtureId => _lastUpdatedFixtureId;

  // Track if this is the first load of fixtures
  bool _isFirstLoad = true;
  bool get isFirstLoad => _isFirstLoad;

  // Standings
  List<Map<String, dynamic>> _standings = [];
  List<Map<String, dynamic>> get standings => _standings;
  bool _isLoadingStandings = false;
  bool get isLoadingStandings => _isLoadingStandings;
  String? _standingsErrorMessage;
  String? get standingsErrorMessage => _standingsErrorMessage;

  // League members
  List<Map<String, dynamic>> _leagueMembers = [];
  List<Map<String, dynamic>> get leagueMembers => _leagueMembers;
  bool _isLoadingMembers = true;
  bool get isLoadingMembers => _isLoadingMembers;
  String? _membersErrorMessage;
  String? get membersErrorMessage => _membersErrorMessage;

  // Generate fixtures
  bool _isGeneratingFixtures = false;
  bool get isGeneratingFixtures => _isGeneratingFixtures;
  String? _generateErrorMessage;
  String? get generateErrorMessage => _generateErrorMessage;
  String? _successMessage;
  String? get successMessage => _successMessage;
  int? _fixturesCount;
  int? get fixturesCount => _fixturesCount;

  // Filters
  String? _filterPlayerId;
  String? get filterPlayerId => _filterPlayerId;
  String? _filterPlayerName = 'All Fixtures';
  String? get filterPlayerName => _filterPlayerName;

  // Played status filter
  String? _filterPlayedStatus;
  String? get filterPlayedStatus => _filterPlayedStatus; // Can be 'played', 'not_played', or null (all)

  // Is creator flag
  bool _isCreator = false;
  bool get isCreator => _isCreator;

  // Current league ID
  dynamic _currentLeagueId;
  dynamic get currentLeagueId => _currentLeagueId;

  // Initialize with league ID and creator status
  void initLeague(dynamic leagueId, bool isCreator) {
    // Reset the disposed flag to allow data loading
    _disposed = false;

    // Only initialize if not already initialized with the same league
    if (_currentLeagueId != leagueId) {
      _currentLeagueId = leagueId;
      _isCreator = isCreator;
      loadLeagueInfo();
      loadLeagueMembers();
      loadFixtures();
    } else {
      // If it's the same league, just reload the data
      // This handles returning to the screen after exiting
      loadFixtures();
      if (_standings.isNotEmpty) {
        loadStandings();
      }
    }
  }

  // Load league info
  Future<void> loadLeagueInfo() async {
    if (_currentLeagueId == null) return;

    _isLoadingLeagueInfo = true;
    _leagueInfoErrorMessage = null;
    notifyListeners();

    try {
      final response = await GetLeagueInfoApi.getLeagueInfo(_currentLeagueId);

      if (response['return_code'] == 'SUCCESS') {
        _leagueInfo = response['league'] ?? {};
        _isLoadingLeagueInfo = false;
        _leagueInfoErrorMessage = null;
      } else {
        _leagueInfo = {};
        _isLoadingLeagueInfo = false;
        _leagueInfoErrorMessage = response['message'] ?? 'Failed to load league info';
      }
    } catch (e) {
      _leagueInfo = {};
      _isLoadingLeagueInfo = false;
      _leagueInfoErrorMessage = 'An error occurred while loading league info';
    }

    notifyListeners();
  }

  // Load fixtures
  Future<void> loadFixtures() async {
    if (_currentLeagueId == null || _disposed) return;

    _isLoadingFixtures = true;
    _fixturesErrorMessage = null;
    notifyListeners();

    try {
      final response = await GetFixturesApi.getFixtures(_currentLeagueId);

      if (response['return_code'] == 'SUCCESS') {
        _fixtures = List<Map<String, dynamic>>.from(response['fixtures'] ?? []);

        // Sort fixtures by ID on first load
        if (_isFirstLoad && _fixtures.isNotEmpty) {
          _sortFixturesById();
          _isFirstLoad = false;
        }

        _isLoadingFixtures = false;
        _fixturesErrorMessage = null;

        // Apply filters if set
        if (_filterPlayerId != null) {
          _applyFilter(_filterPlayerId!, _filterPlayerName);
        } else if (_filterPlayedStatus != null) {
          // Apply only played status filter
          _filteredFixtures = _fixtures.where((fixture) {
            bool playedMatch = _filterPlayedStatus == 'played';
            return fixture['played'] == playedMatch;
          }).toList();
        }
      } else if (response['return_code'] == 'NO_FIXTURES') {
        // Handle the no fixtures case gracefully - this is not an error
        _fixtures = [];
        _isLoadingFixtures = false;
        _fixturesErrorMessage = null; // Don't set an error message for this case
        _isFirstLoad = false; // Reset first load flag
      } else {
        _fixtures = [];
        _isLoadingFixtures = false;
        _fixturesErrorMessage = ErrorHandler.handleApiError(
          response,
          'Failed to load fixtures'
        );
        _isFirstLoad = false; // Reset first load flag
      }
    } catch (e) {
      _fixtures = [];
      _isLoadingFixtures = false;
      _fixturesErrorMessage = ErrorHandler.handleException(
        e,
        'An error occurred while loading fixtures'
      );
      _isFirstLoad = false; // Reset first load flag
      // Error is already logged by handleException
    }

    notifyListeners();

    // Force a second notification after a short delay to ensure UI updates
    // This helps with edge cases where the first notification might not trigger a rebuild
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  // Sort fixtures by ID
  void _sortFixturesById() {
    _fixtures.sort((a, b) {
      final aId = a['id'] is int ? a['id'] : int.tryParse(a['id'].toString()) ?? 0;
      final bId = b['id'] is int ? b['id'] : int.tryParse(b['id'].toString()) ?? 0;
      return aId.compareTo(bId);
    });
  }

  // Set the last updated fixture ID for scrolling
  void setLastUpdatedFixtureId(dynamic fixtureId) {
    if (fixtureId == null) return;

    // Convert to int if needed
    _lastUpdatedFixtureId = fixtureId is int
        ? fixtureId
        : int.tryParse(fixtureId.toString());

    notifyListeners();
  }

  // Clear the last updated fixture ID
  void clearLastUpdatedFixtureId() {
    _lastUpdatedFixtureId = null;
    notifyListeners();
  }

  // Load league members
  Future<void> loadLeagueMembers() async {
    if (_currentLeagueId == null || _disposed) return;

    _isLoadingMembers = true;
    _membersErrorMessage = null;
    notifyListeners();

    try {
      final response = await GetLeagueMembersApi.getLeagueMembers(_currentLeagueId);

      if (response['return_code'] == 'SUCCESS') {
        _leagueMembers = List<Map<String, dynamic>>.from(response['members'] ?? []);
        _isLoadingMembers = false;
        _membersErrorMessage = null;
      } else {
        _leagueMembers = [];
        _isLoadingMembers = false;
        _membersErrorMessage = response['message'] ?? 'Failed to load league members';
      }
    } catch (e) {
      _leagueMembers = [];
      _isLoadingMembers = false;
      _membersErrorMessage = 'An error occurred while loading league members';
    }

    notifyListeners();
  }

  // Load standings
  Future<void> loadStandings() async {
    if (_currentLeagueId == null || _disposed) return;

    _isLoadingStandings = true;
    _standingsErrorMessage = null;
    notifyListeners();

    try {
      final response = await GetStandingsApi.getStandings(_currentLeagueId);

      if (response['return_code'] == 'SUCCESS') {
        _standings = List<Map<String, dynamic>>.from(response['standings'] ?? []);
        _isLoadingStandings = false;
        _standingsErrorMessage = null;
      } else {
        _standings = [];
        _isLoadingStandings = false;
        _standingsErrorMessage = response['message'] ?? 'Failed to load standings';
      }
    } catch (e) {
      _standings = [];
      _isLoadingStandings = false;
      _standingsErrorMessage = 'An error occurred while loading standings';
    }

    notifyListeners();
  }

  // Generate fixtures
  Future<bool> generateFixtures(BuildContext context) async {
    if (_currentLeagueId == null || _disposed) return false;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Generate Fixtures'),
          content: const Text(
            'Are you sure you want to generate fixtures? '
            'This will create matches for all current members. '
            'No more members can be added after fixtures are generated.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('Generate'),
            ),
          ],
        );
      },
    );

    // If user cancelled, do nothing
    if (confirm != true) return false;

    _isGeneratingFixtures = true;
    _generateErrorMessage = null;
    _successMessage = null;
    _fixturesCount = null;
    notifyListeners();

    try {
      final response = await GenerateFixturesApi.generateFixtures(_currentLeagueId);

      if (response['return_code'] == 'SUCCESS') {
        _isGeneratingFixtures = false;
        _generateErrorMessage = null;
        _successMessage = 'Fixtures generated successfully';
        _fixturesCount = response['fixtures_count'];

        // Reload fixtures
        await loadFixtures();
        return true;
      } else {
        _isGeneratingFixtures = false;
        _generateErrorMessage = response['message'] ?? 'Failed to generate fixtures';
        _successMessage = null;
        _fixturesCount = null;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isGeneratingFixtures = false;
      _generateErrorMessage = 'An error occurred while generating fixtures';
      _successMessage = null;
      _fixturesCount = null;
      notifyListeners();
      return false;
    }
  }

  // Apply filter
  void applyFilter(String playerId, String? playerName) {
    _applyFilter(playerId, playerName);
    notifyListeners();
  }

  // Internal apply filter method
  void _applyFilter(String playerId, String? playerName) {
    _filterPlayerId = playerId;
    _filterPlayerName = playerName ?? 'Selected Player';
    _filteredFixtures = _fixtures.where((fixture) {
      bool playerMatch = fixture['player_1_id'].toString() == playerId ||
          fixture['player_2_id'].toString() == playerId;

      // Also apply played status filter if set
      if (_filterPlayedStatus != null) {
        bool playedMatch = _filterPlayedStatus == 'played';
        return playerMatch && (fixture['played'] == playedMatch);
      }

      return playerMatch;
    }).toList();
  }

  // Apply played status filter
  void applyPlayedStatusFilter(String status) {
    // If the same status is already applied, toggle it off
    if (_filterPlayedStatus == status) {
      clearPlayedStatusFilter();
      return;
    }

    // Update the filter status
    _filterPlayedStatus = status;

    // Re-apply player filter if it exists
    if (_filterPlayerId != null) {
      _applyFilter(_filterPlayerId!, _filterPlayerName);
    } else {
      // Apply only played status filter
      _filteredFixtures = _fixtures.where((fixture) {
        bool playedMatch = status == 'played';
        return fixture['played'] == playedMatch;
      }).toList();
    }

    // Always notify listeners to ensure UI updates
    notifyListeners();

    // Force a second notification after a short delay to ensure UI updates
    // This helps with edge cases where the first notification might not trigger a rebuild
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  // Clear played status filter
  void clearPlayedStatusFilter() {
    _filterPlayedStatus = null;

    // Re-apply player filter if it exists
    if (_filterPlayerId != null) {
      _applyFilter(_filterPlayerId!, _filterPlayerName);
    } else {
      // When no player filter, show all fixtures
      _filteredFixtures = [];
    }

    // Always notify listeners to ensure UI updates
    notifyListeners();

    // Force a second notification after a short delay to ensure UI updates
    // This helps with edge cases where the first notification might not trigger a rebuild
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_disposed) {
        notifyListeners();
      }
    });
  }

  // Clear player filter
  void clearFilter() {
    _filterPlayerId = null;
    _filterPlayerName = 'All Fixtures';

    // Keep played status filter if it exists
    if (_filterPlayedStatus != null) {
      _filteredFixtures = _fixtures.where((fixture) {
        bool playedMatch = _filterPlayedStatus == 'played';
        return fixture['played'] == playedMatch;
      }).toList();
    } else {
      _filteredFixtures = [];
    }

    notifyListeners();
  }

  // Clear success message
  void clearSuccessMessage() {
    _successMessage = null;
    _fixturesCount = null;
    notifyListeners();
  }

  // Remove a player from the league
  Future<bool> removePlayerFromLeague(BuildContext context, int playerId, String playerName) async {
    if (_currentLeagueId == null) return false;

    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Remove Player'),
          content: Text('Are you sure you want to remove $playerName from the league?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );

    // If user cancelled, do nothing
    if (confirm != true) return false;

    try {
      // Call the API to remove the player
      final response = await RemovePlayerFromLeagueApi.removePlayerFromLeague(
        _currentLeagueId,
        playerId,
      );

      if (response['return_code'] == 'SUCCESS') {
        // Show success message
        ErrorHandler.showSuccessToast(response['message'] ?? 'Player removed successfully');

        // Reload the league members list
        await loadLeagueMembers();
        return true;
      } else if (response['return_code'] == 'FIXTURES_EXIST') {
        // Show error message for fixtures exist
        ErrorHandler.showErrorToast(
          'Cannot remove player because fixtures have already been generated',
        );
        return false;
      } else {
        // Show generic error message
        ErrorHandler.showErrorToast(
          response['message'] ?? 'Failed to remove player',
        );
        return false;
      }
    } catch (e) {
      // Show error message for exceptions
      ErrorHandler.showErrorToast('An error occurred while removing the player');
      return false;
    }
  }

  // Helper method to format date
  String formatDate(String? dateString) {
    if (dateString == null) return 'Not available';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Helper method to get points type display
  String getPointsTypeDisplay(String? winType) {
    switch (winType) {
      case 'PTS':
        return 'Points Based';
      case 'WIN':
        return 'Win Only';
      case 'WDL':
        return 'Win/Draw/Loss';
      default:
        return 'Points Based';
    }
  }

  // Clear all data when leaving the screen
  // This is a safe version that doesn't notify listeners if called during disposal
  void clearData({bool notify = true, bool fullDispose = true}) {
    // Mark as disposed to prevent further updates if fullDispose is true
    // Otherwise, just clear the data but allow future operations
    if (fullDispose) {
      _disposed = true;
    }
    _leagueInfo = {};
    _fixtures = [];
    _filteredFixtures = [];
    _standings = [];
    _leagueMembers = [];
    _filterPlayerId = null;
    _filterPlayerName = null;
    _filterPlayedStatus = null;
    _currentLeagueId = null;
    _isCreator = false;
    _isLoadingLeagueInfo = true;
    _isLoadingFixtures = true;
    _isLoadingStandings = false;
    _isLoadingMembers = true;
    _isGeneratingFixtures = false;
    _leagueInfoErrorMessage = null;
    _fixturesErrorMessage = null;
    _standingsErrorMessage = null;
    _membersErrorMessage = null;
    _generateErrorMessage = null;
    _successMessage = null;
    _fixturesCount = null;
    _lastUpdatedFixtureId = null;
    _isFirstLoad = true;

    // Only notify listeners if requested (avoid during disposal)
    // and if the provider hasn't been disposed
    if (notify && !_disposed) {
      notifyListeners();
    }
  }
}
