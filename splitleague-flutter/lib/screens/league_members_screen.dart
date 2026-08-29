/*
Screen for displaying and managing league members
Allows organizers to view and add notes for each member
Only accessible to league organizers
*/

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/get_league_members_api.dart';
import '../api/get_notes_api.dart';
import '../api/update_notes_api.dart';
import '../api/convert_guest_to_user_api.dart';
import '../helpers/auth_helper.dart';
import '../styles/app_styles.dart';

class LeagueMembersScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const LeagueMembersScreen({
    super.key,
    required this.league,
  });

  @override
  State<LeagueMembersScreen> createState() => _LeagueMembersScreenState();
}

class _LeagueMembersScreenState extends State<LeagueMembersScreen> {
  // List of league members
  List<Map<String, dynamic>> _members = [];

  // Loading state
  bool _isLoading = true;

  // Error message
  String? _errorMessage;

  // Flag to track if current user is the creator
  bool _isCreator = false;

  // League provider

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

      // The creator ID could be in 'creator_id', 'created_by', or the user might have 'is_creator' flag
      final creatorId = widget.league['creator_id'] ?? widget.league['created_by'];
      final isCreator = (userData != null &&
                       creatorId != null &&
                       userData['id'].toString() == creatorId.toString()) ||
                      widget.league['is_creator'] == true;

      // Set creator flag
      setState(() {
        _isCreator = isCreator;
      });

      // If not creator, navigate back to league details
      if (!_isCreator) {
        if (!mounted) return;

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only league organizers can access this screen'),
            backgroundColor: Colors.red,
          ),
        );

        // Back where we came from. This screen is always pushed on top of Details, so
        // popping returns to the real Details screen with its own state - rebuilding a
        // fresh one, as this used to, also had to guess at the league's stage.
        Navigator.of(context).pop();
        return;
      }

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

  // View/Edit notes for a player
  Future<void> _viewEditNotes(int playerId, String playerName) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Get current notes
      final response = await GetNotesApi.getNotes(
        leagueId: widget.league['league_id'],
        userId: playerId,
      );

      // Dismiss loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      if (response['return_code'] == 'SUCCESS') {
        final notes = response['notes'] ?? '';

        // Show dialog to view/edit notes
        if (!mounted) return;
        final result = await _showNotesDialog(playerName, notes);

        // If notes were updated, save them
        if (result != null) {
          await _updateNotes(playerId, playerName, result);
        }
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to load notes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Dismiss loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show dialog to view/edit notes
  Future<String?> _showNotesDialog(String playerName, String currentNotes) async {
    final controller = TextEditingController(text: currentNotes);

    // Get current user data to check if we're updating notes for ourselves
    final userData = await AuthHelper.getUserData();
    final currentUserId = userData?['id'];

    // Check if any member in the list matches the current user
    bool isCurrentUser = false;
    if (currentUserId != null) {
      for (final member in _members) {
        if (member['id'] == currentUserId &&
            (member['nickname'] == playerName || member['name'] == playerName)) {
          isCurrentUser = true;
          break;
        }
      }
    }

    // Set the dialog title based on whether we're updating notes for ourselves or another player
    final dialogTitle = isCurrentUser ? 'Notes for you' : 'Notes for $playerName';

    // Check if the widget is still mounted before showing the dialog
    if (!mounted) return null;

    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Add notes for this player. Notes for any player may be visible to all league members.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLength: 100,
              maxLines: 3,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter notes here...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // Update notes for a player
  Future<void> _updateNotes(int playerId, String playerName, String notes) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Update notes
      final response = await UpdateNotesApi.updateNotes(
        leagueId: widget.league['league_id'],
        userId: playerId,
        notes: notes,
      );

      // Dismiss loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      if (response['return_code'] == 'SUCCESS') {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notes updated for $playerName'),
            backgroundColor: Colors.green,
          ),
        );

        // Back to league details, which reloads the notes when it sees `true` come back.
        if (!mounted) return;
        Navigator.of(context).pop(true);
      } else {
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to update notes'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Dismiss loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show convert guest to user dialog
  Future<void> _showConvertGuestDialog(int guestUserId, String guestName) async {
    final emailController = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert Guest to User'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
              'Convert "$guestName" from a guest player to a registered user.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'Enter the email address of the registered user:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email Address',
                hintText: 'user@example.com',
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withAlpha(50)),
              ),
              child: const Text(
                'Note: This will transfer all fixtures and league data from the guest to the registered user. The guest account will be deleted.',
                style: TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
          ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(emailController.text.trim()),
            child: const Text('Convert'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      await _convertGuestToUser(guestUserId, result, guestName);
    }
  }

  // Convert guest to registered user
  Future<void> _convertGuestToUser(int guestUserId, String email, String guestName) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      // Convert guest to registered user using the provided email
      final response = await ConvertGuestToUserApi.convertGuestToUser(
        guestUserId: guestUserId,
        registeredUserEmail: email,
        leagueId: widget.league['league_id'],
      );

      // Dismiss loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      if (response['return_code'] == 'SUCCESS') {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully converted $guestName to registered user'),
            backgroundColor: Colors.green,
          ),
        );

        // Reload members
        _loadMembers();
      } else {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to convert guest'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Dismiss loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while converting guest'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.league['name']} - Members'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
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
      body: _isLoading
        ? const Center(
            child: SpinKitCircle(
              color: Colors.blue,
              size: 50.0,
            ),
          )
        : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : Column(
              children: [
                // Content area
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Header text
                              Text(
                                'League Members',
                                style: AppStyles.sectionHeading,
                              ),
                              const SizedBox(height: 16),

                              // Player count
                              Text(
                                '${_members.length} players in league',
                                style: AppStyles.subtitle,
                              ),
                              const SizedBox(height: 16),

                              // Players list
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _members.length,
                                itemBuilder: (context, index) {
                                  final member = _members[index];
                                  final memberId = member['id'];
                                  final memberName = member['nickname'] ?? member['name'] ?? 'Unknown Player';
                                  final isCreator = member['is_creator'] == true ||
                                                  member['is_organiser'] == true ||
                                                  member['is_organizer'] == true;

                                  // Check if this is a guest player (nickname starts with 'guest_')
                                  final isGuest = memberName.startsWith('guest_');

                                  // Display name - for guests, remove the 'guest_' prefix for display
                                  final displayName = isGuest
                                      ? memberName.substring(6) // Remove 'guest_' prefix
                                      : memberName;

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8.0),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isGuest ? Colors.orange : null,
                                        child: Text(
                                          displayName.substring(0, 1).toUpperCase(),
                                        ),
                                      ),
                                      title: Text(displayName),
                                      subtitle: isCreator
                                        ? const Text('League Organizer',
                                            style: TextStyle(color: Colors.blue)
                                          )
                                        : isGuest
                                          ? const Text('Guest Player',
                                              style: TextStyle(color: Colors.orange)
                                            )
                                          : null,
                                      trailing: isGuest && _isCreator
                                        ? IconButton(
                                            icon: const Icon(Icons.person_add, color: Colors.orange),
                                            onPressed: () => _showConvertGuestDialog(memberId, displayName),
                                            tooltip: 'Convert Guest to User',
                                          )
                                        : isGuest
                                          ? null // No notes for guest players
                                          : IconButton(
                                              icon: const Icon(Icons.note_add, color: Colors.blue),
                                              onPressed: () => _viewEditNotes(memberId, displayName),
                                              tooltip: 'Add/Edit Notes',
                                            ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
