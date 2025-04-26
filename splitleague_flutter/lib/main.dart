/*
Main entry point for the SplitLeague Flutter application
Sets up the MaterialApp and handles initial routing based on authentication status
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/login_user_screen.dart';
import 'screens/dashboard_screen.dart';
import 'helpers/auth_helper.dart';
import 'helpers/config.dart';
import 'helpers/runtime_config.dart';
import 'helpers/version_helper.dart';
import 'styles/app_styles.dart';
import 'providers/league_provider.dart';
import 'providers/accessibility_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize runtime configuration
  await RuntimeConfig().initialize();

  // Run the app
  runApp(const SplitLeagueApp());
}

class SplitLeagueApp extends StatelessWidget {
  const SplitLeagueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LeagueProvider()),
        ChangeNotifierProvider(create: (_) => AccessibilityProvider()),
      ],
      child: Consumer<AccessibilityProvider>(
        builder: (context, accessibilityProvider, _) {
          // Apply accessibility settings
          final textScaleFactor = accessibilityProvider.getTextScaleFactor();

          // Create standard base theme
          final baseTheme = ThemeData(
            primarySwatch: Colors.indigo,
            primaryColor: AppStyles.primaryColor,
            colorScheme: ColorScheme.light(
              primary: AppStyles.primaryColor,
              secondary: AppStyles.accentColor,
            ),
            scaffoldBackgroundColor: AppStyles.backgroundColor,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppStyles.primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
            ),
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          // Apply high contrast if needed
          final theme = accessibilityProvider.getThemeData(baseTheme);

          return MaterialApp(
            builder: (context, child) {
              return MediaQuery(
                // Apply text scaling
                data: MediaQuery.of(context).copyWith(
                  textScaler: TextScaler.linear(textScaleFactor),
                ),
                child: child!,
              );
            },
            title: 'SplitLeague',
            debugShowCheckedModeBanner: false,
            // Enable accessibility features
            showSemanticsDebugger: false, // Set to true for debugging accessibility
            theme: theme,
            home: const AuthCheckScreen(),
          );
        },
      ),
    );
  }
}

class AuthCheckScreen extends StatefulWidget {
  const AuthCheckScreen({super.key});

  @override
  State<AuthCheckScreen> createState() => _AuthCheckScreenState();
}

class _AuthCheckScreenState extends State<AuthCheckScreen> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  // Check if user is already logged in
  Future<void> _checkLoginStatus() async {
    bool isLoggedIn = await AuthHelper.isLoggedIn();

    // Check if the app version is valid
    bool isVersionValid = await VersionHelper.isAppVersionValid();

    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });

    // Only show update required dialog if version is not valid
    if (mounted && !isVersionValid) {
      _showUpdateRequiredDialog();
    }
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.system_update,
                size: 48,
                color: Colors.red,
              ),
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
                // Close the app - in a real app, this would redirect to the app store
                Navigator.of(context).pop();
                // Exit the app
                SystemNavigator.pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while checking login status
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Navigate to appropriate screen based on login status
    if (_isLoggedIn) {
      return const DashboardScreen();
    } else {
      return const LoginUserScreen();
    }
  }
}
