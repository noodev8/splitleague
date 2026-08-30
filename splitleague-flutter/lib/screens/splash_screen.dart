/*
Splash screen for the SplitLeague application
Displays the app logo and transitions to the appropriate screen
*/

import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/update_user_accessed_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/config.dart';
import '../helpers/version_helper.dart';
// import '../styles/app_styles.dart';
import 'dashboard_screen.dart';
import 'login_user_screen.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller for fade-in effect
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Flag to track if we've checked login status
  bool _isCheckingAuth = true;

  @override
  void initState() {
    super.initState();

    // Set up animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Create fade-in animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Start animation
    _animationController.forward();

    // Check login status after a delay (extended to 3 seconds)
    Timer(const Duration(milliseconds: 3000), _checkLoginStatus);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Launch app store based on platform
  Future<void> _launchAppStore() async {
    String storeUrl;

    if (Platform.isIOS) {
      // iOS App Store URL
      storeUrl = 'https://apps.apple.com/us/app/split-league/id6745337065';
    } else if (Platform.isAndroid) {
      // Google Play Store URL
      storeUrl =
          'https://play.google.com/store/apps/details?id=com.noodev8.splitleague';
    } else {
      // Fallback for other platforms
      return;
    }

    final Uri uri = Uri.parse(storeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    // Exit the app after launching the store
    SystemNavigator.pop();
  }

  // Show update required dialog
  void _showUpdateRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // User must update
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Update Required',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'A new version of SplitLeague is required to continue.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Current version: ${Config.appVersion}',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              const Text(
                'Please update to the latest version from the app store.',
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'Update Now',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                // Close the dialog
                Navigator.of(context).pop();
                // Launch the appropriate app store
                _launchAppStore();
              },
            ),
          ],
        );
      },
    );
  }

  // Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    bool isLoggedIn = await AuthHelper.isLoggedIn();
    bool isVersionValid = await VersionHelper.isAppVersionValid();

    // Update user accessed timestamp if logged in
    if (isLoggedIn) {
      try {
        final response = await UpdateUserAccessedApi.updateUserAccessed();

        // Check if token is invalid/expired
        final wasUnauthorized = await AuthHelper.handleUnauthorizedResponse(
          response,
        );
        if (wasUnauthorized) {
          // Token was invalid, treat as not logged in
          isLoggedIn = false;
        }
      } catch (e) {
        // Silently handle any errors, don't block the app startup
        // Error is ignored to avoid blocking app startup
      }
    }

    if (mounted) {
      setState(() {
        _isCheckingAuth = false;
      });

      // Check if version is valid first
      if (!isVersionValid) {
        _showUpdateRequiredDialog();
        return;
      }

      // Navigate to appropriate screen based on login status
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginUserScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // The first frame of the app. It is on screen for well under a second, so it does
    // one thing: the name, set the way the app sets names, on the app's own ground.
    //
    // It used to be the logo tile plus the line "Track scores, anytime, anywhere", which
    // described a category of app rather than this one, and which the sign-in screen then
    // repeated a second later.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppPalette.deep,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Split League',
                  style: AppType.t(
                    AppType.display,
                    color: AppPalette.onDark,
                    size: 36,
                  ),
                ),

                const SizedBox(height: 44),

                SizedBox(
                  height: 22,
                  width: 22,
                  child:
                      _isCheckingAuth
                          ? const CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white54,
                            ),
                          )
                          : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
