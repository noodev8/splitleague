/*
Show the fixtures screen for a league
This screen shows fixtures, standings, and league details
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/generate_fixtures_api.dart';
import '../api/get_fixtures_api.dart';
import '../api/get_league_info_api.dart';
import '../api/get_league_members_api.dart';
import '../api/get_standings_api.dart';
import '../api/remove_player_from_league_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../widgets/tab_selector.dart';
import '../widgets/fixtures_tab_content.dart';
import '../widgets/standings_tab_content.dart';
import '../widgets/details_tab_content.dart';
import 'update_score_screen.dart';

class FixturesScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const FixturesScreen({
    super.key,
    required this.league,
  });

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
  // Selected tab index
  int _selectedTabIndex = 0;

  // User data
  Map<String, dynamic>? _userData;

  // League info
  Map<String, dynamic> _leagueInfo = {};

  // Fixtures
  List<Map<String, dynamic>> _fixtures = [];
  List<Map<String, dynamic>> _filteredFixtures = [];
  bool _isLoadingFixtures = true;
  String? _fixturesErrorMessage;

  // Standings
  List<Map<String, dynamic>> _standings = [];
  bool _isLoadingStandings = false;
  String? _standingsErrorMessage;

  // League members
  List<Map<String, dynamic>> _leagueMembers = [];
  bool _isLoadingMembers = true;
  String? _membersErrorMessage;

  // Generate fixtures
  bool _isGeneratingFixtures = false;
  String? _generateErrorMessage;
  String? _successMessage;
  int? _fixturesCount;

  // Filter
  String? _filterPlayerId;
  String? _filterPlayerName;

  // Is creator flag
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadLeagueInfo();
    _loadLeagueMembers();
    _loadFixtures();
  }

  // Load user data from secure storage
  Future<void> _loadUserData() async {
    try {
      Map<String, dynamic>? userData = await AuthHelper.getUserData();
      setState(() {
        _userData = userData;
        // Check if current user is the creator
        _isCreator = userData != null &&
            widget.league['creator_id'] != null &&
            userData['id'].toString() == widget.league['creator_id'].toString();
      });
    } catch (e) {
      // Handle error
    }
  }

  // Load league info
  Future<void> _loadLeagueInfo() async {
    try {
      final response = await GetLeagueInfoApi.getLeagueInfo(widget.league['league_id']);

      if (response['return_code'] == 'SUCCESS') {
        setState(() {
          _leagueInfo = response['league_info'] ?? {};
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  // Load fixtures
  Future<void> _loadFixtures() async {
    setState(() {
      _isLoadingFixtures = true;
      _fixturesErrorMessage = null;
    });

    try {
      final response = await GetFixturesApi.getFixtures(widget.league['league_id']);

      if (response['return_code'] == 'SUCCESS') {
        setState(() {
          _fixtures = List<Map<String, dynamic>>.from(response['fixtures'] ?? []);
          _isLoadingFixtures = false;
          _fixturesErrorMessage = null;

          // Apply filter if set
          if (_filterPlayerId != null) {
            _applyFilter(_filterPlayerId!, _filterPlayerName);
          }
        });
      } else {
        setState(() {
          _fixtures = [];
          _isLoadingFixtures = false;
          _fixturesErrorMessage = response['message'] ?? 'Failed to load fixtures';
        });
      }
    } catch (e) {
      setState(() {
        _fixtures = [];
        _isLoadingFixtures = false;
        _fixturesErrorMessage = 'An error occurred while loading fixtures';
      });
    }
  }

  // Load league members
  Future<void> _loadLeagueMembers() async {
    setState(() {
      _isLoadingMembers = true;
      _membersErrorMessage = null;
    });

    try {
      final response = await GetLeagueMembersApi.getLeagueMembers(widget.league['league_id']);

      if (response['return_code'] == 'SUCCESS') {
        setState(() {
          _leagueMembers = List<Map<String, dynamic>>.from(response['members'] ?? []);
          _isLoadingMembers = false;
          _membersErrorMessage = null;
        });
      } else {
        setState(() {
          _leagueMembers = [];
          _isLoadingMembers = false;
          _membersErrorMessage = response['message'] ?? 'Failed to load league members';
        });
      }
    } catch (e) {
      setState(() {
        _leagueMembers = [];
        _isLoadingMembers = false;
        _membersErrorMessage = 'An error occurred while loading league members';
      });
    }
  }

  // Load standings
  Future<void> _loadStandings() async {
    setState(() {
      _isLoadingStandings = true;
      _standingsErrorMessage = null;
    });

    try {
      final response = await GetStandingsApi.getStandings(widget.league['league_id']);

      if (response['return_code'] == 'SUCCESS') {
        setState(() {
          _standings = List<Map<String, dynamic>>.from(response['standings'] ?? []);
          _isLoadingStandings = false;
          _standingsErrorMessage = null;
        });
      } else {
        setState(() {
          _standings = [];
          _isLoadingStandings = false;
          _standingsErrorMessage = response['message'] ?? 'Failed to load standings';
        });
      }
    } catch (e) {
      setState(() {
        _standings = [];
        _isLoadingStandings = false;
        _standingsErrorMessage = 'An error occurred while loading standings';
      });
    }
  }

  // Generate fixtures
  Future<void> _generateFixtures() async {
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
    if (confirm != true) return;

    setState(() {
      _isGeneratingFixtures = true;
      _generateErrorMessage = null;
      _successMessage = null;
      _fixturesCount = null;
    });

    try {
      final response = await GenerateFixturesApi.generateFixtures(widget.league['league_id']);

      if (response['return_code'] == 'SUCCESS') {
        setState(() {
          _isGeneratingFixtures = false;
          _generateErrorMessage = null;
          _successMessage = 'Fixtures generated successfully';
          _fixturesCount = response['fixtures_count'];
        });

        // Reload fixtures
        _loadFixtures();
      } else {
        setState(() {
          _isGeneratingFixtures = false;
          _generateErrorMessage = response['message'] ?? 'Failed to generate fixtures';
          _successMessage = null;
          _fixturesCount = null;
        });
      }
    } catch (e) {
      setState(() {
        _isGeneratingFixtures = false;
        _generateErrorMessage = 'An error occurred while generating fixtures';
        _successMessage = null;
        _fixturesCount = null;
      });
    }
  }

  // Navigate to update score screen
  void _navigateToUpdateScore(Map<String, dynamic> fixture) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UpdateScoreScreen(
          fixture: fixture,
          leagueId: widget.league['league_id'],
          winType: _leagueInfo['win_type'],
        ),
      ),
    );

    // If score was updated, reload fixtures and standings
    if (result == true) {
      _loadFixtures();
      if (_selectedTabIndex == 1) {
        _loadStandings();
      }
    }
  }

  // Show filter menu
  void _showFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter Fixtures',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('All Fixtures'),
                onTap: () {
                  setState(() {
                    _filterPlayerId = null;
                    _filterPlayerName = 'All Fixtures';
                  });
                  Navigator.of(context).pop();
                },
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _leagueMembers.length,
                  itemBuilder: (context, index) {
                    final member = _leagueMembers[index];
                    final memberId = member['id'].toString();
                    final memberName = member['nickname'] ?? member['name'] ?? 'Unknown Player';

                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(memberName),
                      onTap: () {
                        _applyFilter(memberId, memberName);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Apply filter
  void _applyFilter(String playerId, String? playerName) {
    setState(() {
      _filterPlayerId = playerId;
      _filterPlayerName = playerName ?? 'Selected Player';
      _filteredFixtures = _fixtures.where((fixture) {
        return fixture['player_1_id'].toString() == playerId ||
            fixture['player_2_id'].toString() == playerId;
      }).toList();
    });
  }

  // Clear filter
  void _clearFilter() {
    setState(() {
      _filterPlayerId = null;
      _filterPlayerName = 'All Fixtures';
    });
  }

  // Handle tab change
  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    // Load standings if switching to standings tab
    if (index == 1 && _standings.isEmpty && !_isLoadingStandings) {
      _loadStandings();
    }
  }

  // Remove a player from the league
  Future<void> _removePlayerFromLeague(int playerId, String playerName) async {
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
    if (confirm != true) return;

    try {
      // Call the API to remove the player
      final response = await RemovePlayerFromLeagueApi.removePlayerFromLeague(
        widget.league['league_id'],
        playerId,
      );

      if (response['return_code'] == 'SUCCESS') {
        // Show success message
        if (mounted) {
          ErrorHelper.showSuccessToast(response['message'] ?? 'Player removed successfully');
        }

        // Reload the league members list
        _loadLeagueMembers();
      } else if (response['return_code'] == 'FIXTURES_EXIST') {
        // Show error message for fixtures exist
        if (mounted) {
          ErrorHelper.showErrorToast(
            'Cannot remove player because fixtures have already been generated',
          );
        }
      } else {
        // Show generic error message
        if (mounted) {
          ErrorHelper.showErrorToast(
            response['message'] ?? 'Failed to remove player',
          );
        }
      }
    } catch (e) {
      // Show error message for exceptions
      if (mounted) {
        ErrorHelper.showErrorToast('An error occurred while removing the player');
      }
    }
  }

  // Copy to clipboard
  void _copyToClipboard(String? text) {
    if (text == null || text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ErrorHelper.showSuccessToast('Code copied to clipboard');
    });
  }

  // Helper method to format date
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Not available';

    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  // Helper method to get points type display
  String _getPointsTypeDisplay(String? winType) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.league['name']),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade100,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tab selector
                TabSelector(
                  selectedIndex: _selectedTabIndex,
                  onTabChanged: _onTabChanged,
                ),
                const SizedBox(height: 24),

                // Tab content
                if (_selectedTabIndex == 0) // Fixtures tab
                  FixturesTabContent(
                    isCreator: _isCreator,
                    isLoadingFixtures: _isLoadingFixtures,
                    isLoadingMembers: _isLoadingMembers,
                    isGeneratingFixtures: _isGeneratingFixtures,
                    fixtures: _fixtures,
                    filteredFixtures: _filteredFixtures,
                    leagueMembers: _leagueMembers,
                    filterPlayerId: _filterPlayerId,
                    filterPlayerName: _filterPlayerName,
                    generateErrorMessage: _generateErrorMessage,
                    fixturesErrorMessage: _fixturesErrorMessage,
                    membersErrorMessage: _membersErrorMessage,
                    successMessage: _successMessage,
                    fixturesCount: _fixturesCount,
                    onGenerateFixtures: _generateFixtures,
                    onLoadFixtures: _loadFixtures,
                    onShowFilterMenu: _showFilterMenu,
                    onNavigateToUpdateScore: _navigateToUpdateScore,
                    onRemovePlayerFromLeague: _removePlayerFromLeague,
                    onClearFilter: _clearFilter,
                  )
                else if (_selectedTabIndex == 1) // Standings tab
                  StandingsTabContent(
                    isLoadingStandings: _isLoadingStandings,
                    standings: _standings,
                    standingsErrorMessage: _standingsErrorMessage,
                    winType: _leagueInfo['win_type'],
                    onLoadStandings: _loadStandings,
                  )
                else // Details tab
                  DetailsTabContent(
                    leagueInfo: _leagueInfo,
                    hasFixtures: _fixtures.isNotEmpty,
                    onCopyToClipboard: _copyToClipboard,
                    formatDate: _formatDate,
                    getPointsTypeDisplay: _getPointsTypeDisplay,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
