/*
Show the fixtures screen for a league
Allows the league creator to generate fixtures and view existing fixtures
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/generate_fixtures_api.dart';
import '../api/get_league_fixtures_api.dart';
import '../api/get_league_members_api.dart';
import '../api/get_league_info_api.dart';
import '../api/get_league_table_api.dart';
import '../api/remove_player_from_league_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';
import '../widgets/fixture_card.dart';
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
  // Loading states
  bool _isGeneratingFixtures = false;
  bool _isLoadingFixtures = true;
  bool _isLoadingMembers = true;
  bool _isLoadingStandings = false;
  bool _isLoadingLeagueInfo = false;

  // Error messages
  String? _generateErrorMessage;
  String? _fixturesErrorMessage;
  String? _membersErrorMessage;
  String? _standingsErrorMessage;
  String? _leagueInfoErrorMessage;

  // Success message
  String? _successMessage;

  // Fixtures count
  int? _fixturesCount;

  // Fixtures list
  List<Map<String, dynamic>> _fixtures = [];

  // League members list
  List<Map<String, dynamic>> _leagueMembers = [];

  // League standings list
  List<Map<String, dynamic>> _standings = [];

  // League info
  Map<String, dynamic> _leagueInfo = {};

  // User data
  Map<String, dynamic>? _userData;

  // Filter state
  String? _filterPlayerId;
  String? _filterPlayerName = 'All Fixtures';

  // Tab selection
  int _selectedTabIndex = 0; // 0 = Fixtures, 1 = Standings, 2 = Details

  // Filtered fixtures
  List<Map<String, dynamic>> get _filteredFixtures {
    if (_filterPlayerId == null) return _fixtures;

    return _fixtures.where((fixture) {
      final player1Id = fixture['player_1_id'];
      final player2Id = fixture['player_2_id'];
      return player1Id.toString() == _filterPlayerId || player2Id.toString() == _filterPlayerId;
    }).toList();
  }

  // Is user the creator of the league
  bool get _isCreator => widget.league['is_creator'] ?? false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFixtures();
    _loadLeagueMembers();
    _loadLeagueInfo();
  }

  // Load league standings
  Future<void> _loadStandings() async {
    setState(() {
      _isLoadingStandings = true;
      _standingsErrorMessage = null;
    });

    try {
      // Use GetLeagueTableApi instead of direct getLeagueTable call
      final response = await GetLeagueTableApi.getLeagueTable(widget.league['league_id']);

      if (response['return_code'] == 'SUCCESS') {
        setState(() {
          _standings = List<Map<String, dynamic>>.from(response['standings'] ?? []);
          _isLoadingStandings = false;
        });
      } else if (response['return_code'] == 'NO_STANDINGS_FOUND' ||
                response['return_code'] == 'NO_FIXTURES_PLAYED') {
        // Don't set error message for no standings, just set empty standings list
        setState(() {
          _standings = [];
          _isLoadingStandings = false;
          _standingsErrorMessage = null;
        });
      } else {
        // Only set error message for actual errors
        setState(() {
          _standingsErrorMessage = response['message'];
          _isLoadingStandings = false;
        });
      }
    } catch (e) {
      setState(() {
        _standingsErrorMessage = 'Failed to load standings: $e';
        _isLoadingStandings = false;
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
      final response = await GetLeagueMembersApi.getLeagueMembers(widget.league['league_id']); // Changed from 'id'

      if (response['return_code'] == 'SUCCESS') {
        final List<dynamic> membersData = response['members'] ?? [];
        final members = membersData.map((member) => member as Map<String, dynamic>).toList();

        setState(() {
          _leagueMembers = members;
          _isLoadingMembers = false;
          _membersErrorMessage = null;
        });
      } else {
        setState(() {
          _isLoadingMembers = false;
          _membersErrorMessage = response['message'] ?? 'Failed to load league members';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingMembers = false;
        _membersErrorMessage = 'An error occurred while loading league members';
      });
    }
  }

  // Called when tab changes
  void _onTabChanged(int index) {
    setState(() {
      _selectedTabIndex = index;
    });

    // Load data based on selected tab
    if (index == 1) {
      _loadStandings();
    } else if (index == 2) {
      _loadLeagueInfo();
    }
  }

  // Load league info
  Future<void> _loadLeagueInfo() async {
    setState(() {
      _isLoadingLeagueInfo = true;
      _leagueInfoErrorMessage = null;
    });

    try {
      final result = await GetLeagueInfoApi.getLeagueInfo(widget.league['league_id']); // Changed from 'id'

      if (result['return_code'] == 'SUCCESS') {
        setState(() {
          _leagueInfo = result['league'];
          _isLoadingLeagueInfo = false;
        });
      } else if (result['return_code'] == 'LEAGUE_NOT_FOUND') {
        // Don't set error message for league not found, just set empty league info
        setState(() {
          _leagueInfo = {};
          _isLoadingLeagueInfo = false;
          _leagueInfoErrorMessage = null;
        });
      } else {
        // Only set error message for actual errors
        setState(() {
          _leagueInfoErrorMessage = result['message'];
          _isLoadingLeagueInfo = false;
        });
      }
    } catch (e) {
      setState(() {
        _leagueInfoErrorMessage = 'Failed to load league info: $e';
        _isLoadingLeagueInfo = false;
      });
    }
  }

  // Load user data from secure storage
  Future<void> _loadUserData() async {
    try {
      Map<String, dynamic>? userData = await AuthHelper.getUserData();
      setState(() {
        _userData = userData;
      });
    } catch (e) {
      // Handle error silently
      // Error is ignored as this is not critical functionality
    }
  }

  // Load fixtures for the league
  Future<void> _loadFixtures() async {
    setState(() {
      _isLoadingFixtures = true;
      _fixturesErrorMessage = null;
    });

    try {
      final response = await GetLeagueFixturesApi.getLeagueFixtures(widget.league['league_id']);

      if (response['return_code'] == 'SUCCESS') {
        final List<dynamic> fixturesData = response['fixtures'] ?? [];
        setState(() {
          _fixtures = List<Map<String, dynamic>>.from(fixturesData);
          _isLoadingFixtures = false;
          _fixturesErrorMessage = null;
        });
      } else if (response['return_code'] == 'NO_FIXTURES_FOUND') {
        // Don't set error message for no fixtures, just set empty fixtures list
        setState(() {
          _fixtures = [];
          _isLoadingFixtures = false;
          _fixturesErrorMessage = null;
        });
      } else {
        // Only set error message for actual errors
        setState(() {
          _isLoadingFixtures = false;
          _fixturesErrorMessage = response['message'] ?? 'Failed to load fixtures';
        });
      }
    } catch (e) {
      setState(() {
        _isLoadingFixtures = false;
        _fixturesErrorMessage = 'An error occurred while loading fixtures';
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
            'Once fixtures are generated, no new members can join the league. '
            'Are you sure you want to generate fixtures now?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppStyles.primaryColor),
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
    });

    try {
      final response = await GenerateFixturesApi.generateFixtures(widget.league['league_id']);

      if (response['return_code'] == 'SUCCESS') {
        setState(() {
          _isGeneratingFixtures = false;
          _successMessage = response['message'];
          _fixturesCount = response['fixtures_created'];
          _generateErrorMessage = null;
        });

        ErrorHelper.showSuccessToast(_successMessage ?? 'Fixtures generated successfully');
        _loadFixtures();
      } else {
        setState(() {
          _isGeneratingFixtures = false;
          _generateErrorMessage = response['message'];
          _successMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _isGeneratingFixtures = false;
        _generateErrorMessage = 'An error occurred while generating fixtures';
        _successMessage = null;
      });
    }
  }

  // When navigating to UpdateScoreScreen
  void _navigateToUpdateScore(Map<String, dynamic> fixture) async {
    try {
      final response = await GetLeagueInfoApi.getLeagueInfo(widget.league['league_id']);

      if (response['return_code'] == 'SUCCESS') {
        final updatedFixture = Map<String, dynamic>.from(fixture);
        updatedFixture['win_type'] = response['league']['win_type'];

        // Add is_creator flag to check authorization
        updatedFixture['is_creator'] = _isCreator;

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => UpdateScoreScreen(
                fixture: updatedFixture,
                onScoreUpdated: () {
                  _loadFixtures();
                },
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ErrorHelper.showErrorToast(
            response['message'] ?? 'Failed to get league info',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHelper.showErrorToast('Failed to load league info');
      }
    }
  }

  // Show filter menu
  void _showFilterMenu(BuildContext context) {
    if (_fixtures.isEmpty) return;

    // Get all players for counting
    final allPlayers = <String, Map<String, dynamic>>{};
    for (final fixture in _fixtures) {
      final player1Id = fixture['player_1_id'].toString();
      final player2Id = fixture['player_2_id'].toString();
      final player1Name = fixture['player_1_name'];
      final player2Name = fixture['player_2_name'];

      if (!allPlayers.containsKey(player1Id)) {
        allPlayers[player1Id] = {'name': player1Name};
      }

      if (!allPlayers.containsKey(player2Id)) {
        allPlayers[player2Id] = {'name': player2Name};
      }
    }

    final totalPlayerCount = allPlayers.length;
    final displayedPlayerCount = _uniquePlayers.length;

    // Use a safer approach to position the menu
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    final RenderBox? overlay = Navigator.of(context).overlay?.context.findRenderObject() as RenderBox?;

    if (renderBox == null || overlay == null) {
      // If we can't get the render objects, use a default position
      return;
    }

    // Calculate position relative to the button
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        renderBox.localToGlobal(Offset.zero, ancestor: overlay),
        renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: [
        // Show all fixtures option
        PopupMenuItem<String>(
          value: 'all',
          child: Row(
            children: [
              Icon(
                Icons.filter_list,
                size: 18,
                color: _filterPlayerId == null ? AppStyles.primaryColor : Colors.grey.shade700,
              ),
              const SizedBox(width: 8),
              Text(
                'All Fixtures',
                style: TextStyle(
                  fontWeight: _filterPlayerId == null ? FontWeight.bold : FontWeight.normal,
                  color: _filterPlayerId == null ? AppStyles.primaryColor : null,
                ),
              ),
            ],
          ),
        ),
        // My fixtures option
        if (_userData != null)
          PopupMenuItem<String>(
            value: 'my',
            child: Row(
              children: [
                Icon(
                  Icons.person,
                  size: 18,
                  color: _filterPlayerId == _userData!['id'].toString() ? AppStyles.primaryColor : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Text(
                  'My Fixtures',
                  style: TextStyle(
                    fontWeight: _filterPlayerId == _userData!['id'].toString() ? FontWeight.bold : FontWeight.normal,
                    color: _filterPlayerId == _userData!['id'].toString() ? AppStyles.primaryColor : null,
                  ),
                ),
              ],
            ),
          ),
        // Divider
        const PopupMenuDivider(),
        // Header for players list
        PopupMenuItem<String>(
          enabled: false,
          child: Text(
            'Players',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // List of players
        ..._uniquePlayers.map((player) {
          final playerId = player['id'].toString();
          final playerName = player['name'] as String;
          final playerNickname = player['nickname'] as String?;

          // Use nickname if available, otherwise use name
          String displayName;
          if (playerNickname != null && playerNickname.isNotEmpty) {
            // Use nickname only
            displayName = playerNickname;
          } else {
            // If no nickname, use name but truncate if too long
            if (playerName.length > 20) {
              displayName = '${playerName.substring(0, 17)}...';
            } else {
              displayName = playerName;
            }
          }

          return PopupMenuItem<String>(
            value: 'player:$playerId:$displayName',
            child: Row(
              children: [
                Icon(
                  Icons.sports_handball,
                  size: 18,
                  color: _filterPlayerId == playerId ? AppStyles.primaryColor : Colors.grey.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontWeight: _filterPlayerId == playerId ? FontWeight.bold : FontWeight.normal,
                      color: _filterPlayerId == playerId ? AppStyles.primaryColor : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),

        // Show "More Players" option if there are more players than we're displaying
        if (totalPlayerCount > displayedPlayerCount)
          PopupMenuItem<String>(
            enabled: false,
            child: Row(
              children: [
                Icon(
                  Icons.more_horiz,
                  size: 18,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(width: 8),
                Text(
                  '${totalPlayerCount - displayedPlayerCount} more players...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
      ],
    ).then((value) {
      setState(() {
        if (value == 'all') {
          // Show all fixtures
          _filterPlayerId = null;
          _filterPlayerName = 'All Fixtures';
        } else if (value == 'my' && _userData != null) {
          // Show my fixtures
          _filterPlayerId = _userData!['id'].toString();
          _filterPlayerName = 'My Fixtures';
        } else if (value?.startsWith('player:') ?? false) {
          // Show fixtures for specific player
          final parts = value!.split(':');
          if (parts.length >= 3) {
            _filterPlayerId = parts[1];
            _filterPlayerName = parts.sublist(2).join(':');
          }
        }
      });

      // Reload fixtures to apply filter
      setState(() {});
    });
  }

  // Get all unique players in fixtures
  List<Map<String, dynamic>> get _uniquePlayers {
    final players = <String, Map<String, dynamic>>{};

    for (final fixture in _fixtures) {
      final player1Id = fixture['player_1_id'].toString();
      final player2Id = fixture['player_2_id'].toString();
      final player1Name = fixture['player_1_name'];
      final player2Name = fixture['player_2_name'];
      final player1Nickname = fixture['player_1_nickname'];
      final player2Nickname = fixture['player_2_nickname'];

      if (!players.containsKey(player1Id)) {
        players[player1Id] = {
          'id': player1Id,
          'name': player1Name,
          'nickname': player1Nickname,
        };
      }

      if (!players.containsKey(player2Id)) {
        players[player2Id] = {
          'id': player2Id,
          'name': player2Name,
          'nickname': player2Nickname,
        };
      }
    }

    // Sort players by name and limit to 10 to avoid very long menus
    final sortedPlayers = players.values.toList()
      ..sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));

    return sortedPlayers.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.league['name']),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          // Reduce horizontal padding to fix overflow
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Removed league name as it's now in the app bar
              const SizedBox(height: 8),

              // Tab selection
              Container(
                padding: const EdgeInsets.all(2),
                decoration: AppStyles.tabContainerDecoration,
                child: Row(
                  children: [
                    // Fixtures tab
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _onTabChanged(0),
                        style: _selectedTabIndex == 0
                            ? AppStyles.activeTabButtonStyle
                            : AppStyles.tabButtonStyle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.sports_soccer,
                              size: 14,
                              color: _selectedTabIndex == 0 ? Colors.white : AppStyles.secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Fixtures',
                              style: TextStyle(
                                fontWeight: _selectedTabIndex == 0 ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Standings tab (moved to second position)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _onTabChanged(1),
                        style: _selectedTabIndex == 1
                            ? AppStyles.activeTabButtonStyle
                            : AppStyles.tabButtonStyle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.leaderboard,
                              size: 14,
                              color: _selectedTabIndex == 1 ? Colors.white : AppStyles.secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Standings',
                              style: TextStyle(
                                fontWeight: _selectedTabIndex == 1 ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Details tab (moved to third position)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _onTabChanged(2),
                        style: _selectedTabIndex == 2
                            ? AppStyles.activeTabButtonStyle
                            : AppStyles.tabButtonStyle,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: _selectedTabIndex == 2 ? Colors.white : AppStyles.secondaryTextColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Details',
                              style: TextStyle(
                                fontWeight: _selectedTabIndex == 2 ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Tab content
              if (_selectedTabIndex == 1) // Standings tab
                _buildStandingsTab()
              else if (_selectedTabIndex == 2) // Details tab
                _buildDetailsTab()
              else // Fixtures tab (default)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Generate fixtures section (only for league creator and if no fixtures exist)
                    if (_isCreator && _fixtures.isEmpty && !_isLoadingFixtures) ...[
                      const Text(
                        'Generate Fixtures',
                        style: AppStyles.subheadingStyle,
                      ),
                      const SizedBox(height: 16),

                      const Text(
                        'As the league organiser, you can generate fixtures for all members of the league. '
                        'This will create matches based on the "Play Each Other" setting.',
                        style: AppStyles.bodyStyle,
                      ),
                      const SizedBox(height: 24),

                      // Generate fixtures button
                      ElevatedButton.icon(
                        onPressed: _isGeneratingFixtures ? null : _generateFixtures,
                        style: AppStyles.primaryButtonStyle,
                        icon: const Icon(Icons.sports),
                        label: _isGeneratingFixtures
                            ? const SpinKitThreeBounce(
                                color: Colors.white,
                                size: 24,
                              )
                            : const Text('Generate Fixtures'),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Generate error message
                    if (_generateErrorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppStyles.errorColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppStyles.errorColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _generateErrorMessage!,
                                style: const TextStyle(
                                  color: AppStyles.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_generateErrorMessage != null) const SizedBox(height: 24),

                    // Success message
                    if (_successMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppStyles.successColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_outline, color: AppStyles.successColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _successMessage!,
                                    style: const TextStyle(
                                      color: AppStyles.successColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_fixturesCount != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Created $_fixturesCount fixtures',
                                style: TextStyle(
                                  color: AppStyles.successColor.withAlpha(204), // 0.8 opacity
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (_successMessage != null) const SizedBox(height: 24),

                    // Fixtures section (only shown when fixtures exist)
                    if (_fixtures.isNotEmpty) ...[
                      // Removed Fixtures header text as we have tab buttons now

                      // Filter controls in a separate row
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          children: [
                            // Filter menu button
                            IconButton(
                              icon: Icon(
                                Icons.filter_list,
                                color: _filterPlayerId != null ? AppStyles.primaryColor : null,
                              ),
                              onPressed: () {
                                _showFilterMenu(context);
                              },
                              tooltip: 'Filter fixtures',
                              constraints: const BoxConstraints(
                                minWidth: 36,  // Reduced from 40
                                minHeight: 36, // Reduced from 40
                              ),
                            ),
                            // Filter indicator with Expanded
                            Expanded(
                              child: Container(
                                constraints: const BoxConstraints(maxWidth: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                margin: const EdgeInsets.only(left: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppStyles.primaryColor.withAlpha(100)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        _filterPlayerName ?? 'All Fixtures',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: _filterPlayerId != null ? AppStyles.primaryColor : Colors.grey.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                    ),
                                    if (_filterPlayerId != null) ...[
                                      const SizedBox(width: 4),
                                      InkWell(
                                        onTap: () {
                                          setState(() {
                                            _filterPlayerId = null;
                                            _filterPlayerName = 'All Fixtures';
                                          });
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: const Icon(
                                          Icons.close,
                                          size: 14,
                                          color: AppStyles.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                            // Refresh button
                            IconButton(
                              icon: const Icon(Icons.refresh),
                              onPressed: _loadFixtures,
                              tooltip: 'Refresh fixtures',
                              constraints: const BoxConstraints(
                                minWidth: 36,  // Reduced from default
                                minHeight: 36, // Reduced from default
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Fixtures error message
                    if (!_isCreator && _fixturesErrorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppStyles.errorColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppStyles.errorColor),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _fixturesErrorMessage!,
                                style: const TextStyle(
                                  color: AppStyles.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_isCreator && _fixturesErrorMessage != null) const SizedBox(height: 16),

                    // Fixtures list
                    if (_isLoadingFixtures || _isLoadingMembers)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_fixtures.isEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_isCreator) ...[
                            // League members section for creator
                            const Text(
                              'League Members',
                              style: AppStyles.subheadingStyle,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Check that all players have joined before generating fixtures.',
                              style: AppStyles.bodyStyle,
                            ),
                            const SizedBox(height: 16),

                            // Show league members list
                            if (_leagueMembers.isNotEmpty)
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _leagueMembers.length,
                                itemBuilder: (context, index) {
                                  final member = _leagueMembers[index];
                                  final bool isCreatorMember = member['is_creator'] == true;
                                  final int memberId = member['id'];
                                  final String memberName = member['nickname'] ?? member['name'] ?? 'Unknown Player';

                                  return ListTile(
                                    leading: Icon(
                                      isCreatorMember ? Icons.star : Icons.person,
                                      color: isCreatorMember ? Colors.amber : null,
                                    ),
                                    title: Text(memberName),
                                    // Only show delete button for non-creator members and if current user is creator
                                    trailing: _isCreator && !isCreatorMember
                                      ? IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _removePlayerFromLeague(memberId, memberName),
                                          tooltip: 'Remove player',
                                        )
                                      : null,
                                  );
                                },
                              )
                            else if (_membersErrorMessage != null)
                              Text(
                                _membersErrorMessage!,
                                style: TextStyle(color: Colors.red.shade700),
                              ),
                          ] else ...[
                            // Message for non-creator members
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 32),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.sports_soccer,
                                      size: 64,
                                      color: Colors.grey.shade400,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No Fixtures Yet',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Waiting for the organiser to generate fixtures',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      )
                    else if (_filterPlayerId != null && _filteredFixtures.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No fixtures found for ${_filterPlayerName ?? "selected player"}.',
                            style: AppStyles.bodyStyle,
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        // Disable scrolling on the inner ListView
                        physics: const NeverScrollableScrollPhysics(),
                        // Shrink the ListView to fit its content
                        shrinkWrap: true,
                        itemCount: _filterPlayerId != null ? _filteredFixtures.length : _fixtures.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Map<String, dynamic> fixture =
                              _filterPlayerId != null ? _filteredFixtures[index] : _fixtures[index];
                          return FixtureCard(
                            fixture: fixture,
                            onTap: _navigateToUpdateScore,
                          );
                        },
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Build the standings tab
  Widget _buildStandingsTab() {
    // Load standings if not already loaded
    if (_standings.isEmpty && !_isLoadingStandings && _standingsErrorMessage == null) {
      _loadStandings();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Loading indicator
        if (_isLoadingStandings)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: SpinKitCircle(color: AppStyles.primaryColor, size: 50.0),
            ),
          )
        // Error message
        else if (_standingsErrorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: AppStyles.errorColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppStyles.errorColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _standingsErrorMessage!,
                    style: const TextStyle(color: AppStyles.errorColor),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppStyles.primaryColor),
                  onPressed: _loadStandings,
                  tooltip: 'Retry',
                ),
              ],
            ),
          )
        // Empty standings
        else if (_standings.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.leaderboard_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No standings available',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Play some matches to see the standings',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          )
        // Standings table
        else
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withAlpha(40),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppStyles.primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 24, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                      const SizedBox(width: 8),
                      const Expanded(
                        flex: 3,
                        child: Text('Player', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                      const SizedBox(width: 8),
                      const SizedBox(width: 30, child: Text('P', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                      const SizedBox(width: 30, child: Text('W', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                      if (_standings.isNotEmpty && _standings.first.containsKey('drawn') && _leagueInfo['win_type'] != 'WIN')
                        const SizedBox(width: 30, child: Text('D', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                      const SizedBox(width: 30, child: Text('L', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                      const SizedBox(width: 8),
                      const SizedBox(width: 30, child: Text('Pts', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center)),
                    ],
                  ),
                ),

                // Table rows
                ...List.generate(_standings.length, (index) {
                  final player = _standings[index];
                  final isCurrentUser = player['user_id'] == _userData?['id'];

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isCurrentUser ? AppStyles.primaryColor.withAlpha(15) : Colors.white,
                      border: Border(
                        bottom: BorderSide(
                          color: index < _standings.length - 1 ? Colors.grey.shade200 : Colors.transparent,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Position
                        SizedBox(
                          width: 24,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: index < 3 ? AppStyles.primaryColor : AppStyles.textColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Player name
                        Expanded(
                          flex: 3,
                          child: Text(
                            player['nickname'] ?? player['name'],
                            style: TextStyle(
                              fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                              color: isCurrentUser ? AppStyles.primaryColor : AppStyles.textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Played
                        SizedBox(width: 30, child: Text('${player['played']}', textAlign: TextAlign.center)),

                        // Won
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${player['won']}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppStyles.successColor, fontWeight: FontWeight.w500),
                          ),
                        ),

                        // Drawn (only for PTS and WDL leagues)
                        if (player.containsKey('drawn') && _leagueInfo['win_type'] != 'WIN')
                          SizedBox(width: 30, child: Text('${player['drawn']}', textAlign: TextAlign.center)),

                        // Lost
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${player['lost']}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppStyles.errorColor, fontWeight: FontWeight.w500),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Points
                        SizedBox(
                          width: 30,
                          child: Text(
                            '${player['points']}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }

  // Build the details tab
  Widget _buildDetailsTab() {
    // Load league info if not already loaded
    if (_leagueInfo.isEmpty && !_isLoadingLeagueInfo && _leagueInfoErrorMessage == null) {
      _loadLeagueInfo();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Loading indicator
        if (_isLoadingLeagueInfo)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: SpinKitCircle(color: AppStyles.primaryColor, size: 50.0),
            ),
          )
        else if (_leagueInfoErrorMessage != null)
          Center(
            child: Text(
              _leagueInfoErrorMessage!,
              style: const TextStyle(color: AppStyles.errorColor),
            ),
          )
        else ...[
          // League info card
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppStyles.primaryColor.withAlpha(50)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // League name
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppStyles.primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          color: AppStyles.primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'League Name',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppStyles.secondaryTextColor,
                              ),
                            ),
                            Text(
                              _leagueInfo['name'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Organiser
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppStyles.primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.person,
                          color: AppStyles.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Organiser',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppStyles.secondaryTextColor,
                            ),
                          ),
                          FutureBuilder<String>(
                            future: _getOrganizerNickname(_leagueInfo['created_by']), // Changed from organiser_id to created_by
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text('Loading...',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }
                              // Debug info removed

                              return Text(
                                snapshot.data ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // League Code
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppStyles.primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _fixtures.isNotEmpty ? Icons.check_circle : Icons.key,
                          color: AppStyles.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fixtures.isNotEmpty ? 'Join Status' : 'Join Code',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppStyles.secondaryTextColor,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  _fixtures.isNotEmpty
                                    ? 'Complete'
                                    : (_leagueInfo['public_code'] ?? 'Unknown'),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Only show copy button if league hasn't started
                                if (_fixtures.isEmpty)
                                  GestureDetector(
                                    onTap: () => _copyToClipboard(_leagueInfo['public_code']),
                                    child: const Icon(
                                      Icons.copy,
                                      size: 18,
                                      color: AppStyles.primaryColor,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Points Type
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppStyles.primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.score,
                          color: AppStyles.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Points Type',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppStyles.secondaryTextColor,
                            ),
                          ),
                          Text(
                            _getPointsTypeDisplay(_leagueInfo['win_type']),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Created at
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppStyles.primaryColor.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.history,
                          color: AppStyles.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Created On',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppStyles.secondaryTextColor,
                            ),
                          ),
                          Text(
                            _formatDate(_leagueInfo['created_at']),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Points rules section
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: AppStyles.primaryColor.withAlpha(50)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Points rules list
                  Column(
                    children: [
                      // Win points
                      _buildPointsCard(
                        'Win',
                        '${_leagueInfo['points_for_win'] ?? 0}',
                        Icons.emoji_events,
                        AppStyles.primaryColor,
                      ),
                      const SizedBox(height: 12),

                      // Draw points (only for WDL)
                      if (_leagueInfo['win_type'] == 'WDL') ...[
                        _buildPointsCard(
                          'Draw',
                          '${_leagueInfo['points_for_draw'] ?? 0}',
                          Icons.handshake,
                          AppStyles.primaryColor,
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Win margin bonus
                      _buildPointsCard(
                        'Win Margin Bonus',
                        '${_leagueInfo['points_for_win_margin'] ?? 0}',
                        Icons.add_circle,
                        AppStyles.primaryColor,
                      ),
                      const SizedBox(height: 12),

                      // Close loss points
                      _buildPointsCard(
                        'Lose within margin',
                        '${_leagueInfo['points_for_close_loss'] ?? 0}',
                        Icons.remove_circle,
                        AppStyles.primaryColor,
                      ),
                      const SizedBox(height: 12),

                      // Margin threshold
                      _buildPointsCard(
                        'Margin Threshold',
                        '${_leagueInfo['win_margin_threshold'] ?? 0}',
                        Icons.speed,
                        AppStyles.primaryColor,
                      ),
                      const SizedBox(height: 12),

                      // Play each other
                      _buildPointsCard(
                        'Play Each Other',
                        '${_leagueInfo['play_each_other'] ?? 1} time${_leagueInfo['play_each_other'] == 1 ? '' : 's'}',
                        Icons.repeat,
                        AppStyles.primaryColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Helper method to build points rule card
  Widget _buildPointsCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity, // Make container take full width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: color.withAlpha(200),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
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

  // Copy to clipboard
  void _copyToClipboard(String? text) {
    if (text == null || text.isEmpty) return;

    Clipboard.setData(ClipboardData(text: text)).then((_) {
      ErrorHelper.showSuccessToast('Code copied to clipboard');
    });
  }

  // Helper method to get organizer nickname
  Future<String> _getOrganizerNickname(dynamic userId) async {
    if (userId == null) return 'Unknown';

    // Check if the organizer is in the league members list
    for (var member in _leagueMembers) {
      if (member['id'] == userId) {  // Changed from user_id to id
        return member['nickname'] ?? member['name'] ?? 'Unknown';
      }
    }

    // If not found in members, check if it's the current user
    if (_userData != null && _userData!['id'] == userId) {
      return _userData!['nickname'] ?? _userData!['name'] ?? 'Unknown';
    }

    // If still not found, return the user ID
    return 'User #$userId';
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
}
