/*
Show the profile screen with user information and settings
Provides options like logout
*/

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../helpers/auth_helper.dart';
import '../helpers/config.dart';
import '../helpers/error_helper.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import '../widgets/sl_action_row.dart';
import '../api/delete_account_api.dart';
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
      ErrorHelper.showErrorToast('Could not load your details');
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
      bool confirm =
          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Sign out?'),
                  content: const Text(
                    'Your leagues stay on your account. You will need your password to '
                    'get back in.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!confirm) return;

      // Perform logout
      await AuthHelper.logout();

      // Show success message
      // ErrorHelper.showSuccessToast('Logged out successfully');

      // Navigate to login screen
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginUserScreen()),
          (route) => false, // Remove all previous routes
        );
      }
    } catch (e) {
      ErrorHelper.showErrorToast('Could not sign you out');
    }
  }

  // Handle delete account button press
  Future<void> _handleDeleteAccount() async {
    try {
      // Show first confirmation dialog
      bool firstConfirm =
          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'Your account, your leagues and every result you have entered are '
                    'deleted. This cannot be undone.',
                    style: TextStyle(height: 1.5),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!firstConfirm) return;

      // Check if widget is still mounted before showing second dialog
      if (!mounted) return;

      // Show second confirmation dialog for extra safety
      bool secondConfirm =
          await showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Final Confirmation'),
                  content: const Text(
                    'This will permanently delete your account and all associated data. You will not be able to recover it. Are you absolutely sure?',
                    style: TextStyle(height: 1.5),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Yes, Delete My Account'),
                    ),
                  ],
                ),
          ) ??
          false;

      if (!secondConfirm) return;

      // Show a dialog to optionally collect reason for deletion
      String? reason;
      if (mounted) {
        reason = await showDialog<String>(
          context: context,
          builder: (context) {
            final TextEditingController reasonController =
                TextEditingController();
            return AlertDialog(
              title: const Text('Reason for Leaving'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Would you like to tell us why you\'re deleting your account? (Optional)',
                    style: TextStyle(height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    decoration: const InputDecoration(
                      hintText: 'Your reason (optional)',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Skip'),
                ),
                TextButton(
                  onPressed:
                      () => Navigator.of(context).pop(reasonController.text),
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      }

      // Show loading dialog while deleting account
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting account...'),
              ],
            ),
          );
        },
      );

      // Call the API to delete the account
      final response = await DeleteAccountApi.deleteAccount(reason: reason);

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (response['return_code'] == 'SUCCESS') {
        // Show success message
        ErrorHelper.showSuccessToast('Your account has been deleted');

        // Log out the user
        await AuthHelper.logout();

        // Navigate to login screen
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginUserScreen()),
            (route) => false, // Remove all previous routes
          );
        }
      } else {
        // Show error message
        ErrorHelper.showErrorToast(
          response['message'] ?? 'Could not delete your account',
        );
      }
    } catch (e) {
      ErrorHelper.showErrorToast('Could not delete your account');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.chalk,
      appBar: AppBar(
        title: const Text('Your account'),
        backgroundColor: AppPalette.surface,
        shape: const Border(bottom: BorderSide(color: AppPalette.hairline)),
      ),

      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                children: [
                  _buildIdentity(),

                  // Everything grouped by who it is for and what it does to you.
                  //
                  // The old screen had one card called "Actions" holding eight rows in
                  // no order: changing a password, restoring a hidden league, reading
                  // the privacy policy, deleting the account and signing out, all with
                  // the same tinted circular icon. Deleting an account sat two rows
                  // above signing out and looked exactly like it.
                  SlSection(
                    eyebrow: 'Your leagues',
                    children: [
                      SlActionRow(
                        label: 'Hidden leagues',
                        detail: 'Bring back a league you took off your list',
                        icon: Icons.visibility_off_outlined,
                        onTap:
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => const HiddenLeaguesScreen(),
                              ),
                            ),
                      ),
                    ],
                  ),

                  SlSection(
                    eyebrow: 'Settings',
                    children: [
                      SlActionRow(
                        label: 'Change your password',
                        icon: Icons.lock_outline,
                        onTap:
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) => const ChangePasswordScreen(),
                              ),
                            ),
                      ),
                      SlActionRow(
                        label: 'Text size and contrast',
                        icon: Icons.text_fields,
                        onTap:
                            () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const AccessibilitySettingsScreen(),
                              ),
                            ),
                      ),
                    ],
                  ),

                  SlSection(
                    eyebrow: 'About',
                    children: [
                      SlActionRow(
                        label: 'Get in touch',
                        detail: 'info@splitleague.com',
                        icon: Icons.mail_outline,
                        onTap: () => _launchURL('mailto:info@splitleague.com'),
                      ),
                      SlActionRow(
                        label: 'Privacy policy',
                        icon: Icons.shield_outlined,
                        onTap:
                            () => _launchURL(
                              'https://www.noodev8.com/privacy-policy/',
                            ),
                      ),
                      SlActionRow(
                        label: 'Terms of service',
                        icon: Icons.description_outlined,
                        onTap:
                            () => _launchURL(
                              'https://www.noodev8.com/splitleague-terms-and-conditions/',
                            ),
                      ),
                    ],
                  ),

                  // Signing out and deleting the account are separated from everything
                  // else and from each other, because one is routine and the other is
                  // permanent, and on the old screen they were adjacent and identical.
                  SlSection(
                    children: [
                      SlActionRow(
                        label: 'Sign out',
                        icon: Icons.logout,
                        onTap: _handleLogout,
                      ),
                    ],
                  ),

                  SlSection(
                    topGap: 12,
                    children: [
                      SlActionRow(
                        label: 'Delete your account',
                        detail:
                            'Permanent. Takes your leagues and results with it.',
                        icon: Icons.delete_outline,
                        onTap: _handleDeleteAccount,
                        destructive: true,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  Center(
                    child: Text(
                      'Split League ${Config.appVersion} (${Config.appBuildNumber})',
                      style: AppType.b(AppType.meta, size: 12),
                    ),
                  ),
                ],
              ),
    );
  }

  // Who you are, and the one thing you can change about it here.
  Widget _buildIdentity() {
    final String name = _userData?['name']?.toString() ?? '';
    final String nickname = _userData?['nickname']?.toString() ?? '';
    final String email = _userData?['email']?.toString() ?? '';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.hairline),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppPalette.tealTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              _getInitials(nickname),
              style: AppType.t(AppType.title, color: AppPalette.tealDeep),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name.isEmpty ? nickname : name,
                  style: AppType.t(AppType.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  // The display name is what other players see, so it is worth
                  // saying which of these two names that is - it was shown as
                  // "@nickname" before, which reads like a handle on a social
                  // network and is not what it is.
                  nickname.isEmpty ? email : '$nickname in leagues',
                  style: AppType.b(AppType.meta),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty && nickname.isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    email,
                    style: AppType.b(AppType.meta, size: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          IconButton(
            icon: const Icon(
              Icons.edit_outlined,
              size: 19,
              color: AppPalette.tealDeep,
            ),
            tooltip: 'Edit your details',
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
    );
  }

  // Initials for the avatar disc.
  String _getInitials(String? nickname) {
    if (nickname == null || nickname.isEmpty) return '';

    final List<String> parts = nickname.trim().split(' ');
    if (parts.length > 1 && parts[1].isNotEmpty) {
      return parts[0][0].toUpperCase() + parts[1][0].toUpperCase();
    }
    return nickname[0].toUpperCase();
  }

  // Open a link outside the app.
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ErrorHelper.showErrorToast('Could not open that link');
      }
    }
  }
}
