/*
Show the fixtures screen for a league
Allows the league creator to generate fixtures and view existing fixtures
*/

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/generate_fixtures_api.dart';
import '../api/get_league_fixtures_api.dart';
import '../api/get_league_members_api.dart';
import '../api/get_league_info_api.dart';
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

  // Error messages
  String? _generateErrorMessage;
  String? _fixturesErrorMessage;
  String? _membersErrorMessage;

  // Success message
  String? _successMessage;

  // Fixtures count
  int? _fixturesCount;

  // Fixtures list
  List<Map<String, dynamic>> _fixtures = [];

  // League members list
  List<Map<String, dynamic>> _leagueMembers = [];

  // Filter state
  String? _filterPlayerId;
  String? _filterPlayerName = 'All Fixtures';

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

  // User data
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadFixtures();
    _loadLeagueMembers();
  }

  // Load league members
  Future<void> _loadLeagueMembers() async {
    setState(() {
      _isLoadingMembers = true;
      _membersErrorMessage = null;
    });

    try {
      // Call get league members API
      final response = await GetLeagueMembersApi.getLeagueMembers(widget.league['id']);

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Get members from response
        final List<dynamic> membersData = response['members'] ?? [];

        // Convert to List<Map<String, dynamic>>
        final members = membersData.map((member) => member as Map<String, dynamic>).toList();

        setState(() {
          _leagueMembers = members;
          _isLoadingMembers = false;
          _membersErrorMessage = null;
        });
      } else {
        // Handle error
        setState(() {
          _isLoadingMembers = false;
          _membersErrorMessage = response['message'] ?? 'Failed to load league members';
        });
      }
    } catch (e) {
      // Handle exception
      setState(() {
        _isLoadingMembers = false;
        _membersErrorMessage = 'An error occurred while loading league members';
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
      // Call get league fixtures API
      print('Loading fixtures for league ID: ${widget.league['id']} (${widget.league['name']})');
      final response = await GetLeagueFixturesApi.getLeagueFixtures(widget.league['id']);

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Get fixtures from response
        final List<dynamic> fixturesData = response['fixtures'] ?? [];

        // Convert to List<Map<String, dynamic>>
        final fixtures = fixturesData.map((fixture) => fixture as Map<String, dynamic>).toList();

        setState(() {
          _fixtures = fixtures;
          _isLoadingFixtures = false;
          _fixturesErrorMessage = null;
        });
      } else if (response['return_code'] == 'NO_FIXTURES_FOUND') {
        // No fixtures found is not an error
        setState(() {
          _fixtures = [];
          _isLoadingFixtures = false;
          _fixturesErrorMessage = null;
        });
      } else {
        // Handle error
        setState(() {
          _isLoadingFixtures = false;
          _fixturesErrorMessage = response['message'] ?? 'Failed to load fixtures';
        });
      }
    } catch (e) {
      // Handle exception
      setState(() {
        _isLoadingFixtures = false;
        _fixturesErrorMessage = 'An error occurred while loading fixtures';
      });
    }
  }

  // Handle generate fixtures button press
  Future<void> _handleGenerateFixtures() async {
    // Show confirmation dialog
    bool confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Fixtures'),
        content: const Text(
          'This will generate fixtures for all members of the league. '
          'This action cannot be undone. Do you want to continue?'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: AppStyles.primaryColor,
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    ) ?? false;

    if (!confirm) return;

    // Set loading state
    setState(() {
      _isGeneratingFixtures = true;
      _generateErrorMessage = null;
      _successMessage = null;
      _fixturesCount = null;
    });

    try {
      // Call generate fixtures API
      final response = await GenerateFixturesApi.generateFixtures(widget.league['id']);

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Show success message
        setState(() {
          _isGeneratingFixtures = false;
          _successMessage = response['message'];
          _fixturesCount = response['fixtures_created'];
          _generateErrorMessage = null;
        });

        // Show success toast
        ErrorHelper.showSuccessToast(_successMessage ?? 'Fixtures generated successfully');

        // Reload fixtures
        _loadFixtures();
      } else {
        // Show error message
        setState(() {
          _isGeneratingFixtures = false;
          _generateErrorMessage = response['message'];
          _successMessage = null;
        });
      }
    } catch (e) {
      // Show error message
      setState(() {
        _isGeneratingFixtures = false;
        _generateErrorMessage = 'An error occurred. Please try again.';
        _successMessage = null;
      });
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
        title: const Text('Fixtures'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // League name
              Text(
                widget.league['name'],
                style: AppStyles.headingStyle,
              ),
              const SizedBox(height: 24),

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
                  onPressed: _isGeneratingFixtures ? null : _handleGenerateFixtures,
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

              // Fixtures section header (only shown when fixtures exist)
              if (_fixtures.isNotEmpty) ...[
                const Text(
                  'Fixtures',
                  style: AppStyles.subheadingStyle,
                ),

                // Filter controls in a separate row
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Filter indicator and button
                      Row(
                        children: [
                          // Filter menu button - moved to the left
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
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                          // Filter indicator - always shown
                          Container(
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
                                // Filter name with ellipsis (no icon)
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
                                // Only show clear button if not showing "All Fixtures"
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
                        ],
                      ),

                      // Refresh button
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadFixtures,
                        tooltip: 'Refresh fixtures',
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 16),

              // Fixtures error message
              if (_fixturesErrorMessage != null)
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
              if (_fixturesErrorMessage != null) const SizedBox(height: 16),

              // Fixtures list
              if (_isLoadingFixtures)
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
                    // League members section
                    const Text(
                      'League Members',
                      style: AppStyles.subheadingStyle,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isCreator
                        ? 'Check that all players have joined before generating fixtures.'
                        : 'Waiting for the organiser to generate fixtures.',
                      style: AppStyles.bodyStyle,
                    ),
                    const SizedBox(height: 16),

                    // Members list
                    if (_isLoadingMembers)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (_membersErrorMessage != null)
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
                                _membersErrorMessage!,
                                style: const TextStyle(
                                  color: AppStyles.errorColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (_leagueMembers.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            'No members have joined this league yet.',
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
                        itemCount: _leagueMembers.length,
                        itemBuilder: (context, index) {
                          final member = _leagueMembers[index];
                          final name = member['name'] ?? 'Unknown';
                          final nickname = member['nickname'] ?? '';
                          final displayName = nickname.isNotEmpty ? nickname : name;
                          final isCreator = member['is_creator'] ?? false;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: isCreator ? AppStyles.primaryColor : Colors.grey.shade200,
                                child: Icon(
                                  Icons.person,
                                  color: isCreator ? Colors.white : Colors.grey.shade700,
                                ),
                              ),
                              title: Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: isCreator
                                ? Chip(
                                    label: const Text(
                                      'Organiser',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                    backgroundColor: AppStyles.primaryColor,
                                    padding: EdgeInsets.zero,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  )
                                : null,
                            ),
                          );
                        },
                      ),
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
                  itemBuilder: (context, index) {
                    final fixture = _filterPlayerId != null ? _filteredFixtures[index] : _fixtures[index];
                    return FixtureCard(
                      fixture: fixture,
                      onTap: (fixture) async {
                        // Show loading indicator
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => const AlertDialog(
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Loading league info...'),
                              ],
                            ),
                          ),
                        );

                        try {
                          // Get league info to get the win_type
                          final response = await GetLeagueInfoApi.getLeagueInfo(widget.league['id']);

                          // Close loading dialog
                          if (context.mounted) {
                            Navigator.of(context).pop();
                          }

                          if (response['return_code'] == 'SUCCESS') {
                            // Add win_type to fixture data
                            final updatedFixture = Map<String, dynamic>.from(fixture);
                            updatedFixture['win_type'] = response['league']['win_type'];

                            // Debug info is logged in the console

                            // Navigate to update score screen with updated fixture data
                            if (context.mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => UpdateScoreScreen(
                                    fixture: updatedFixture,
                                    onScoreUpdated: () {
                                      // Reload fixtures when score is updated
                                      _loadFixtures();
                                    },
                                  ),
                                ),
                              );
                            }
                          } else {
                            // Show error message
                            if (context.mounted) {
                              ErrorHelper.showErrorToast(
                                response['message'] ?? 'Failed to get league info',
                              );
                            }
                          }
                        } catch (e) {
                          // Close loading dialog
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ErrorHelper.showErrorToast('An error occurred: $e');
                          }
                        }
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
