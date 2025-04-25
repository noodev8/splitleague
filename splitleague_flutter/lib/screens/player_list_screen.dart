/*
Screen for displaying the list of players in a league
Only shown if the league has not yet started (no fixtures)
Only the organizer can remove players from the list
*/

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/get_league_members_api.dart';
import '../api/remove_player_from_league_api.dart';
import '../api/generate_fixtures_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';
import 'league_details_screen.dart';
import 'fixtures_screen.dart';

class PlayerListScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const PlayerListScreen({
    super.key,
    required this.league,
  });

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  // List of league members
  List<Map<String, dynamic>> _members = [];

  // Loading state
  bool _isLoading = true;

  // Error message
  String? _errorMessage;

  // Flag to track if current user is the creator
  bool _isCreator = false;

  // Flag to track if fixtures exist
  bool _hasFixtures = false;

  // Flag to track if fixtures are being generated
  bool _isGeneratingFixtures = false;

  // Success message
  String? _successMessage;

  // Fixtures count
  int? _fixturesCount;

  @override
  void initState() {
    super.initState();
    // Debug print to show the entire league object
    print('League object: ${widget.league}');
    _loadMembers();
    _checkFixtures();
  }

  // Generate fixtures for the league
  Future<void> _generateFixtures() async {
    // Check if there are at least 2 players
    if (_members.length < 2) {
      ErrorHelper.showErrorToast('At least 2 players are needed to start the league');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start League'),
        content: const Text(
          'Are you sure you want to start the league and generate fixtures? '
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
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
            ),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    // If not confirmed, return
    if (confirmed != true) {
      return;
    }

    // Show loading indicator
    setState(() {
      _isGeneratingFixtures = true;
      _successMessage = null;
      _errorMessage = null;
    });

    try {
      // Call API to generate fixtures
      final response = await GenerateFixturesApi.generateFixtures(widget.league['league_id']);

      if (response['return_code'] == 'SUCCESS') {
        // Show success message
        setState(() {
          _isGeneratingFixtures = false;
          _hasFixtures = true;
          _successMessage = response['message'] ?? 'Fixtures generated successfully';
          _fixturesCount = response['fixtures_created'];
        });

        // Show success toast
        ErrorHelper.showSuccessToast(_successMessage!);

        // Navigate to fixtures screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => FixturesScreen(
                league: widget.league,
              ),
            ),
          );
        }
      } else if (response['return_code'] == 'FIXTURES_ALREADY_EXIST') {
        // If fixtures already exist, update our state
        setState(() {
          _isGeneratingFixtures = false;
          _hasFixtures = true;
          ErrorHelper.showErrorToast('Fixtures already exist for this league');
        });
      } else {
        setState(() {
          _isGeneratingFixtures = false;
          _errorMessage = response['message'] ?? 'Failed to generate fixtures';
        });

        // Show error toast
        ErrorHelper.showErrorToast(_errorMessage!);
      }
    } catch (e) {
      setState(() {
        _isGeneratingFixtures = false;
        _errorMessage = 'An error occurred while generating fixtures';
      });

      // Show error toast
      ErrorHelper.showErrorToast(_errorMessage!);
    }
  }

  // Check if fixtures exist for this league
  Future<void> _checkFixtures() async {
    try {
      // Check if hasFixtures is already provided in the league data
      if (widget.league.containsKey('has_fixtures')) {
        setState(() {
          _hasFixtures = widget.league['has_fixtures'] == true;
        });
        return;
      }

      // If not provided, we'll assume no fixtures for now
      // This is a safe default since the player list screen is typically
      // only shown when there are no fixtures
      setState(() {
        _hasFixtures = false;
      });
    } catch (e) {
      // If there's an error, assume no fixtures
      setState(() {
        _hasFixtures = false;
      });
    }
  }

  // Load league members
  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if current user is the creator
      final userData = await AuthHelper.getUserData();

      // The creator ID could be in 'creator_id', 'created_by', or the user might have 'is_creator' flag
      final creatorId = widget.league['creator_id'] ?? widget.league['created_by'];
      final isCreator = (userData != null &&
                         creatorId != null &&
                         userData['id'].toString() == creatorId.toString()) ||
                        widget.league['is_creator'] == true;

      // Debug prints to help diagnose issues
      print('User data: ${userData?['id']}');
      print('League creator ID: $creatorId');
      print('Is creator from check: $isCreator');
      print('Is creator from league: ${widget.league['is_creator']}');

      // Set creator flag
      setState(() {
        _isCreator = isCreator;
      });

      // Get league members
      final response = await GetLeagueMembersApi.getLeagueMembers(widget.league['league_id']);

      if (response['return_code'] == 'SUCCESS') {
        // Debug print to see the structure of the first member
        if ((response['members'] ?? []).isNotEmpty) {
          print('First member structure: ${response['members'][0]}');
        }

        setState(() {
          _members = List<Map<String, dynamic>>.from(response['members'] ?? []);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to load members';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while loading members';
        _isLoading = false;
      });
    }
  }

  // Remove player from league
  Future<void> _removePlayer(int playerId, String playerName) async {
    // Debug prints to help diagnose issues
    print('Attempting to remove player: $playerName (ID: $playerId)');
    print('Is creator: $_isCreator');
    print('Has fixtures: $_hasFixtures');

    // Check if fixtures exist
    if (_hasFixtures) {
      ErrorHelper.showErrorToast('Cannot remove players after fixtures are generated');
      return;
    }

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Player'),
        content: Text('Are you sure you want to remove $playerName from the league?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    // If not confirmed, return
    if (confirmed != true) {
      return;
    }

    // Show loading indicator
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call API to remove player
      final response = await RemovePlayerFromLeagueApi.removePlayerFromLeague(
        widget.league['league_id'],
        playerId,
      );

      if (response['return_code'] == 'SUCCESS') {
        // Show success message
        ErrorHelper.showSuccessToast(response['message'] ?? 'Player removed successfully');

        // Reload members
        _loadMembers();
      } else if (response['return_code'] == 'FIXTURES_EXIST') {
        // If fixtures exist, update our state
        setState(() {
          _hasFixtures = true;
          _isLoading = false;
          ErrorHelper.showErrorToast('Cannot remove players after fixtures are generated');
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to remove player';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred while removing player';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.league['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Details button in AppBar
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'League Details',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LeagueDetailsScreen(
                    league: widget.league,
                  ),
                ),
              ).then((_) {
                // Force UI refresh when returning from details
                if (mounted) {
                  setState(() {});
                }
              });
            },
          ),
        ],
      ),
      body: Container(
        color: AppStyles.backgroundColor,
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: SpinKitThreeBounce(
                    color: AppStyles.primaryColor,
                    size: 24,
                  ),
                )
              : _errorMessage != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: Colors.red,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadMembers,
                              style: AppStyles.primaryButtonStyle,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _members.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.people,
                                  size: 48,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No players in this league yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Player count badge
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppStyles.primaryColor.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.people, color: AppStyles.primaryColor, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_members.length} Players',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: AppStyles.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _members.length,
                                itemBuilder: (context, index) {
                                  final member = _members[index];
                                  final memberId = member['id'];
                                  final memberName = member['nickname'] ?? member['name'] ?? 'Unknown Player';
                                  // Check multiple possible fields for creator status
                                  final isCreator = member['is_creator'] == true ||
                                                   member['is_organiser'] == true ||
                                                   member['is_organizer'] == true;

                                  // Debug print for each list item to check conditions
                                  print('Player: $memberName, isCreator: $isCreator, _isCreator: $_isCreator, _hasFixtures: $_hasFixtures, showRemoveButton: ${_isCreator && !isCreator && !_hasFixtures}');

                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: Colors.grey.shade100,
                                        child: Icon(
                                          Icons.person,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                      title: Text(
                                        memberName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,  // All names now bold
                                        ),
                                      ),
                                      subtitle: isCreator
                                          ? const Text(
                                              'Organiser',
                                              style: TextStyle(
                                                color: AppStyles.primaryColor,
                                                fontSize: 12,
                                              ),
                                            )
                                          : null,
                                      trailing: _isCreator && !isCreator && !_hasFixtures
                                          ? Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red.withAlpha(25),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: IconButton(
                                                icon: const Icon(Icons.remove_circle, color: Colors.red),
                                                onPressed: () => _removePlayer(memberId, memberName),
                                                tooltip: 'Remove player',
                                              ),
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_isCreator) ...[
                              // Start League button (only shown if no fixtures exist)
                              if (!_hasFixtures)
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      const Divider(),
                                      const SizedBox(height: 16),
                                      const Text(
                                        'Ready to start the league?',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _members.length < 2
                                            ? 'You need at least 2 players to start the league. '
                                              'Invite more players using the league code.'
                                            : 'Once you start the league, fixtures will be generated for all current members. '
                                              'No more members can be added after this point.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: _members.length < 2 ? Colors.red.shade300 : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // Check if there are at least 2 players
                                      ElevatedButton.icon(
                                        onPressed: _isGeneratingFixtures || _members.length < 2
                                            ? null
                                            : _generateFixtures,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppStyles.primaryColor,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          // Use a different disabled color to indicate different reasons
                                          disabledBackgroundColor: _members.length < 2
                                              ? Colors.grey.shade400
                                              : Colors.grey.shade300,
                                        ),
                                        icon: _isGeneratingFixtures
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.sports),
                                        label: Text(_isGeneratingFixtures
                                            ? 'Generating...'
                                            : 'Start League'),
                                      ),

                                      // Show message if there are fewer than 2 players
                                      if (_members.length < 2)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: Text(
                                            'At least 2 players are needed to start the league',
                                            style: TextStyle(
                                              color: Colors.red.shade400,
                                              fontSize: 12,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                              // Note about player removal
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  _hasFixtures
                                      ? 'Note: Players cannot be removed after fixtures are generated.'
                                      : 'Note: You can remove players before fixtures are generated.',
                                  style: TextStyle(
                                    color: _hasFixtures ? Colors.red.shade400 : Colors.grey.shade700,
                                    fontStyle: FontStyle.italic,
                                    fontSize: 12,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ],
                        ),
        ),
      ),
    );
  }
}




