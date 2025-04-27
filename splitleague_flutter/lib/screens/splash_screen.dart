/*
Splash screen for the SplitLeague application
Displays the app logo and transitions to the appropriate screen
*/

import 'package:flutter/material.dart';
import 'dart:async';
import '../helpers/auth_helper.dart';
import '../helpers/version_helper.dart';
// import '../styles/app_styles.dart';
import '../widgets/app_logo.dart';
import 'dashboard_screen.dart';
import 'login_user_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
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
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
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

  // Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    bool isLoggedIn = await AuthHelper.isLoggedIn();
    bool isVersionValid = await VersionHelper.isAppVersionValid();

    if (mounted) {
      setState(() {
        _isCheckingAuth = false;
      });

      // Navigate to appropriate screen
      if (isLoggedIn && isVersionValid) {
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
    return Scaffold(
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
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo
                const AppLogo(
                  size: 150,
                  subtitle: 'Track scores, anytime, anywhere',
                ),

                const SizedBox(height: 48),

                // Loading indicator
                if (_isCheckingAuth)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}
