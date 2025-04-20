/*
Screen for displaying the list of players in a league
Only shown if the league has not yet started (no fixtures)
Only the organizer can remove players from the list
*/

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/get_league_members_api.dart';
import '../api/remove_player_from_league_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';

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

  @override
  void initState() {
    super.initState();
    _loadMembers();
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
      final isCreator = userData != null &&
          widget.league['creator_id'] != null &&
          userData['id'].toString() == widget.league['creator_id'].toString();

      // Set creator flag
      setState(() {
        _isCreator = isCreator;
      });

      // Get league members
      final response = await GetLeagueMembersApi.getLeagueMembers(widget.league['league_id']);

      if (response['return_code'] == 'SUCCESS') {
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.league['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade900,
              Colors.blue.shade700,
              Colors.blue.shade200,
              Colors.white,
            ],
            stops: const [0.0, 0.1, 0.3, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: SpinKitThreeBounce(
                    color: Colors.blue,
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
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  const Icon(Icons.people, color: Colors.blue),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Players (${_members.length})',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.builder(
                                itemCount: _members.length,
                                itemBuilder: (context, index) {
                                  final member = _members[index];
                                  final memberId = member['id'];
                                  final memberName = member['nickname'] ?? member['name'] ?? 'Unknown Player';
                                  final isCreator = member['is_creator'] == true;

                                  return Card(
                                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isCreator ? Colors.blue.shade100 : Colors.grey.shade100,
                                        child: Icon(
                                          Icons.person,
                                          color: isCreator ? Colors.blue : Colors.grey.shade700,
                                        ),
                                      ),
                                      title: Text(
                                        memberName,
                                        style: TextStyle(
                                          fontWeight: isCreator ? FontWeight.bold : FontWeight.normal,
                                        ),
                                      ),
                                      subtitle: isCreator
                                          ? const Text(
                                              'Organizer',
                                              style: TextStyle(
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            )
                                          : null,
                                      trailing: _isCreator && !isCreator
                                          ? IconButton(
                                              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                              onPressed: () => _removePlayer(memberId, memberName),
                                              tooltip: 'Remove player',
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                            if (_isCreator)
                              Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Text(
                                  'Note: You can remove players only before fixtures are generated.',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
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
