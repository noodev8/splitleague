/*
Show the profile screen with user information and settings
Provides options like logout
*/

import 'package:flutter/material.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';
import 'login_user_screen.dart';
import 'hidden_leagues_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginUserScreen()),
          (route) => false, // Remove all previous routes
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
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _userData == null
              ? const Center(
                  child: Text('No user data found'),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile header
                      Center(
                        child: Column(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: AppStyles.primaryColor.withAlpha(25),
                              child: Text(
                                _getInitials(_userData!['name']),
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: AppStyles.primaryColor,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Name
                            Text(
                              _userData!['name'],
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            // Nickname
                            Text(
                              '@${_userData!['nickname']}',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // User info section
                      const Text(
                        'Account Information',
                        style: AppStyles.subheadingStyle,
                      ),
                      const SizedBox(height: 16),

                      // Email
                      _buildInfoItem(
                        icon: Icons.email,
                        title: 'Email',
                        value: _userData!['email'],
                      ),
                      const Divider(),

                      const SizedBox(height: 32),

                      // Actions section
                      const Text(
                        'Actions',
                        style: AppStyles.subheadingStyle,
                      ),
                      const SizedBox(height: 16),

                      // Hidden Leagues button
                      ListTile(
                        leading: const Icon(
                          Icons.visibility_off,
                          color: AppStyles.primaryColor,
                        ),
                        title: const Text(
                          'Hidden Leagues',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const HiddenLeaguesScreen(),
                            ),
                          );
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor: AppStyles.primaryColor.withAlpha(20),
                      ),

                      const SizedBox(height: 16),

                      // Logout button
                      ListTile(
                        leading: const Icon(
                          Icons.logout,
                          color: Colors.red,
                        ),
                        title: const Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onTap: _handleLogout,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        tileColor: Colors.red.withAlpha(25),
                      ),
                    ],
                  ),
                ),
    );
  }

  // Helper method to build info items
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppStyles.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper method to get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return '';

    List<String> nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return nameParts[0][0].toUpperCase() + nameParts[1][0].toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }
}
