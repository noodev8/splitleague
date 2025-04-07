/*
Show the dashboard screen after user login
This is a basic placeholder showing the app_user name only
Provides a logout button to return to the login screen
*/

import 'package:flutter/material.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';
import 'login_user_screen.dart';
import 'create_league_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // User data
  Map<String, dynamic>? _userData;

  // Loading state
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Load user data from secure storage
  Future<void> _loadUserData() async {
    try {
      Map<String, dynamic>? userData = await AuthHelper.getUserData();

      setState(() {
        _userData = userData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ErrorHelper.showErrorToast('Failed to load user data');
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
      body: _isLoading
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

                      // Create league button
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const CreateLeagueScreen(),
                            ),
                          );
                        },
                        style: AppStyles.primaryButtonStyle,
                        icon: const Icon(Icons.add),
                        label: const Text('Create New League'),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'You can create a new league or join an existing one using a 4-digit code.',
                        style: AppStyles.bodyStyle,
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
