/*
Show the dashboard screen after user login
This is a basic placeholder showing the app_user name only
Provides a logout button to return to the login screen
*/

import 'package:flutter/material.dart';
import '../api/get_user_leagues_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';
import '../widgets/league_card.dart';
import 'login_user_screen.dart';
import 'create_league_screen.dart';
import 'join_league_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // User data
  Map<String, dynamic>? _userData;

  // Leagues data
  List<Map<String, dynamic>> _leagues = [];

  // Loading states
  bool _isLoadingUser = true;
  bool _isLoadingLeagues = true;

  // Error message for leagues
  String? _leaguesErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserLeagues();
  }

  // Load user data from secure storage
  Future<void> _loadUserData() async {
    try {
      Map<String, dynamic>? userData = await AuthHelper.getUserData();

      setState(() {
        _userData = userData;
        _isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
      ErrorHelper.showErrorToast('Failed to load user data');
    }
  }

  // Load user leagues from API
  Future<void> _loadUserLeagues() async {
    try {
      // Call the API to get user leagues
      final response = await GetUserLeaguesApi.getUserLeagues();

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Get leagues from response
        final List<dynamic> leaguesData = response['leagues'] ?? [];

        // Convert to List<Map<String, dynamic>>
        final leagues = leaguesData.map((league) => league as Map<String, dynamic>).toList();

        setState(() {
          _leagues = leagues;
          _isLoadingLeagues = false;
          _leaguesErrorMessage = null;
        });
      } else {
        // Handle error
        setState(() {
          _isLoadingLeagues = false;
          _leaguesErrorMessage = response['message'] ?? 'Failed to load leagues';
        });
      }
    } catch (e) {
      // Handle exception
      setState(() {
        _isLoadingLeagues = false;
        _leaguesErrorMessage = 'An error occurred while loading leagues';
      });
    }
  }

  // Handle logout button press
  Future<void> _handleLogout() async {
    try {
      // Show confirmation dialog
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Logout'),
            ),
          ],
        ),
      ) ?? false;

      if (!confirm) return;

      // Perform logout
      await AuthHelper.logout();

      // Show success message
      ErrorHelper.showSuccessToast('Logged out successfully');

      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginUserScreen()),
        );
      }
    } catch (e) {
      ErrorHelper.showErrorToast('Failed to logout');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: (_isLoadingUser || _isLoadingLeagues)
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _userData == null
              ? const Center(
                  child: Text('No user data found'),
                )
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome message
                      Text(
                        'Welcome, ${_userData!['name']}!',
                        style: AppStyles.headingStyle,
                      ),
                      const SizedBox(height: 24),

                      // User info card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: AppStyles.cardDecoration,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Profile',
                              style: AppStyles.subheadingStyle,
                            ),
                            const Divider(),
                            const SizedBox(height: 8),

                            // User details
                            _buildUserInfoRow('Name', _userData!['name']),
                            const SizedBox(height: 8),
                            _buildUserInfoRow('Nickname', _userData!['nickname']),
                            const SizedBox(height: 8),
                            _buildUserInfoRow('Email', _userData!['email']),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // League section
                      const Text(
                        'Leagues',
                        style: AppStyles.subheadingStyle,
                      ),
                      const SizedBox(height: 16),

                      // League action buttons
                      Row(
                        children: [
                          // Create league button
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const CreateLeagueScreen(),
                                  ),
                                ).then((_) => _loadUserLeagues()); // Reload leagues after returning
                              },
                              style: AppStyles.primaryButtonStyle,
                              icon: const Icon(Icons.add),
                              label: const Text('Create'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Join league button
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => JoinLeagueScreen(
                                      onLeagueJoined: () {
                                        // Reload leagues when a league is joined
                                        _loadUserLeagues();
                                      },
                                    ),
                                  ),
                                );
                              },
                              style: AppStyles.secondaryButtonStyle,
                              icon: const Icon(Icons.group_add),
                              label: const Text('Join'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Create a new league or join an existing one using a 4-digit code.',
                        style: AppStyles.bodyStyle,
                      ),

                      const SizedBox(height: 24),

                      // My Leagues section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My Leagues',
                            style: AppStyles.subheadingStyle,
                          ),
                          // Refresh button
                          IconButton(
                            icon: const Icon(Icons.refresh),
                            onPressed: _loadUserLeagues,
                            tooltip: 'Refresh leagues',
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Error message
                      if (_leaguesErrorMessage != null)
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
                                  _leaguesErrorMessage!,
                                  style: const TextStyle(
                                    color: AppStyles.errorColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_leaguesErrorMessage != null) const SizedBox(height: 16),

                      // Leagues list
                      if (_leagues.isEmpty && _leaguesErrorMessage == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'You are not a member of any leagues yet.',
                              style: AppStyles.bodyStyle,
                            ),
                          ),
                        )
                      else
                        Expanded(
                          child: ListView.builder(
                            itemCount: _leagues.length,
                            itemBuilder: (context, index) {
                              return LeagueCard(
                                league: _leagues[index],
                                onTap: () {
                                  // Handle league tap
                                  ErrorHelper.showSuccessToast('League details coming soon!');
                                },
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
    );
  }

  // Helper method to build user info rows
  Widget _buildUserInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppStyles.secondaryTextColor,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppStyles.bodyStyle,
          ),
        ),
      ],
    );
  }
}
