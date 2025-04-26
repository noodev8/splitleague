/*
Show the profile screen with user information and settings
Provides options like logout
*/

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';
import 'login_user_screen.dart';
import 'hidden_leagues_screen.dart';
import 'accessibility_settings_screen.dart';
import 'edit_profile_screen.dart';
import 'change_password_screen.dart';

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

  // Navigate to edit profile screen
  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(userData: _userData!),
      ),
    );

    // Reload user data if profile was updated
    if (result == true) {
      await _loadUserData();
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
        backgroundColor: const Color(0xFF005F8A),
        elevation: 0,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: SafeArea(
          bottom: false,
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Profile info card
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              // Avatar
                              Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 50,
                                    backgroundColor: AppStyles.primaryColor.withAlpha(40),
                                    child: Text(
                                      _getInitials(_userData!['nickname']),
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: AppStyles.primaryColor,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: GestureDetector(
                                      onTap: _navigateToEditProfile,
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: AppStyles.primaryColor,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 2,
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.edit,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Name and Edit button
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        // Name
                                        Text(
                                          _userData!['name'],
                                          style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        // Nickname
                                        Text(
                                          '@${_userData!['nickname']}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[600],
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              // Edit Profile Button
                              TextButton.icon(
                                onPressed: _navigateToEditProfile,
                                icon: const Icon(Icons.edit),
                                label: const Text('Edit Profile'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppStyles.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // User info section
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 32.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 16.0),
                                child: Text(
                                  'Account Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Email
                              _buildInfoItem(
                                icon: Icons.email,
                                title: 'Email',
                                value: _userData!['email'],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Actions section
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 32.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 16.0, top: 8.0, bottom: 16.0),
                                child: Text(
                                  'Actions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              // Change Password button
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppStyles.primaryColor.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.lock_outline,
                                    color: AppStyles.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                title: const Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Update your account password',
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const ChangePasswordScreen(),
                                    ),
                                  );
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),

                              const SizedBox(height: 8),

                              // Hidden Leagues button
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppStyles.primaryColor.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.visibility_off,
                                    color: AppStyles.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                title: const Text(
                                  'Hidden Leagues',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: const Text(
                                  'View and restore hidden leagues',
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
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
                              ),
                              const Divider(),
                              // Accessibility settings button
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.accessibility_new,
                                    color: Colors.purple,
                                    size: 24,
                                  ),
                                ),
                                title: const Text(
                                  'Accessibility Settings',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Customize accessibility options',
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const AccessibilitySettingsScreen(),
                                    ),
                                  );
                                },
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const Divider(),
                              // Contact Us
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.email_outlined,
                                    color: Colors.blue,
                                    size: 24,
                                  ),
                                ),
                                title: const Text(
                                  'Contact Us',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Email us at info@splitleague.com',
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(Icons.open_in_new),
                                onTap: () => _launchURL('mailto:info@splitleague.com'),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Privacy Policy
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.teal.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.privacy_tip_outlined,
                                    color: Colors.teal,
                                    size: 24,
                                  ),
                                ),
                                title: const Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: const Text(
                                  'View our privacy policy',
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(Icons.open_in_new),
                                onTap: () => _launchURL('https://www.noodev8.com/privacy-policy/'),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              // Terms of Service
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    color: Colors.amber,
                                    size: 24,
                                  ),
                                ),
                                title: const Text(
                                  'Terms of Service',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: const Text(
                                  'View our terms of service',
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(Icons.open_in_new),
                                onTap: () => _launchURL('https://www.noodev8.com/splitleague-terms-and-conditions/'),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const Divider(),
                              // Logout button
                              ListTile(
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withAlpha(30),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                    size: 24,
                                  ),
                                ),
                                title: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                subtitle: const Text(
                                  'Sign out of your account',
                                  style: TextStyle(
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                                onTap: _handleLogout,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppStyles.primaryColor.withAlpha(30),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: AppStyles.primaryColor,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
        ),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  // Helper method to get initials from nickname
  String _getInitials(String nickname) {
    if (nickname.isEmpty) return '';

    List<String> nicknameParts = nickname.split(' ');
    if (nicknameParts.length > 1) {
      return nicknameParts[0][0].toUpperCase() + nicknameParts[1][0].toUpperCase();
    } else {
      return nickname[0].toUpperCase();
    }
  }

  // Launch URL in browser
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ErrorHelper.showErrorToast('Could not launch $url');
    }
  }
}




