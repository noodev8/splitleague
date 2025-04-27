/*
Screen for displaying the list of players in a league
Only shown if the league has not yet started (no fixtures)
Only the organizer can remove players from the list
Also allows the league organizer to generate fixtures
*/

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:provider/provider.dart';
import '../api/get_league_members_api.dart';
import '../api/remove_player_from_league_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';
import '../providers/league_provider.dart';
//import 'league_details_screen.dart';
import 'dashboard_screen.dart';

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

  // Generate fixtures state
  bool _isGeneratingFixtures = false;
  String? _generateErrorMessage;
  String? _successMessage;
  int? _fixturesCount;

  // League provider
  late LeagueProvider _leagueProvider;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _checkFixtures();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the league provider
    _leagueProvider = Provider.of<LeagueProvider>(context, listen: false);
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

  // Generate fixtures
  Future<void> _generateFixtures() async {
    setState(() {
      _isGeneratingFixtures = true;
      _generateErrorMessage = null;
      _successMessage = null;
      _fixturesCount = null;
    });

    try {
      // Initialize the league provider if needed
      if (_leagueProvider.currentLeagueId != widget.league['league_id']) {
        _leagueProvider.initLeague(widget.league['league_id'], _isCreator);
      }

      // Call the generate fixtures method from the provider
      final result = await _leagueProvider.generateFixtures(context);

      if (result) {
        // Update success state
        setState(() {
          _isGeneratingFixtures = false;
          _successMessage = _leagueProvider.successMessage;
          _fixturesCount = _leagueProvider.fixturesCount;
          _hasFixtures = true; // Update fixtures exist flag
        });

        // Reload members to refresh UI
        _loadMembers();
      } else {
        // Update error state
        setState(() {
          _isGeneratingFixtures = false;
          _generateErrorMessage = _leagueProvider.generateErrorMessage;
        });
      }
    } catch (e) {
      // Handle error
      setState(() {
        _isGeneratingFixtures = false;
        _generateErrorMessage = 'An error occurred while generating fixtures';
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
        title: Text(
          widget.league['name'],
          style: const TextStyle(fontWeight: FontWeight.bold)
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
          },
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF005F8A), // Top color from logo gradient
                Color(0xFF00B3A4), // Bottom color from logo gradient
              ],
            ),
          ),
        ),
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
                            // Generate fixtures section (only for league creator and if no fixtures exist)
                            if (_isCreator && !_hasFixtures) ...[
                              const SizedBox(height: 24),
                              const Divider(),
                              const SizedBox(height: 16),

                              const Text(
                                'Generate Fixtures',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),

                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.0),
                                child: Text(
                                  'As the league organiser, you can generate fixtures for all members of the league. '
                                  'This will create matches based on the "Play Each Other" setting.',
                                  style: TextStyle(fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Generate fixtures button
                              Center(
                                child: ElevatedButton.icon(
                                  onPressed: _isGeneratingFixtures ? null : _generateFixtures,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  ),
                                  icon: const Icon(Icons.sports),
                                  label: _isGeneratingFixtures
                                      ? const SpinKitThreeBounce(
                                          color: Colors.white,
                                          size: 24,
                                        )
                                      : const Text('Generate Fixtures'),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Generate error message
                            if (_generateErrorMessage != null) ...[
                              const SizedBox(height: 16),
                              ErrorDisplay(
                                message: _generateErrorMessage!,
                                onRetry: _generateFixtures,
                                retryText: 'Try Again',
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Success message
                            if (_successMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(16),
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.green.shade200),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: Colors.green,
                                      size: 32,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      _fixturesCount != null
                                        ? '$_successMessage\nCreated $_fixturesCount fixtures'
                                        : _successMessage!,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            if (_isCreator)
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
                        ),
        ),
      ),
    );
  }
}

// Success display widget
class SuccessDisplay extends StatelessWidget {
  final String message;

  const SuccessDisplay({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.green,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// Error display widget
class ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final String retryText;

  const ErrorDisplay({
    super.key,
    required this.message,
    this.onRetry,
    this.retryText = 'Retry',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.red.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade100,
                foregroundColor: Colors.red.shade700,
              ),
              child: Text(retryText),
            ),
          ],
        ],
      ),
    );
  }
}

// Empty state display widget
class EmptyStateDisplay extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onAction;
  final bool showPullToRefresh;

  const EmptyStateDisplay({
    super.key,
    required this.message,
    required this.icon,
    this.actionText,
    this.onAction,
    this.showPullToRefresh = true,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
