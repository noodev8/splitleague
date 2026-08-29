/*
Main entry point for the SplitLeague Flutter application
Sets up the MaterialApp and handles initial routing based on authentication status
*/

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screens/login_user_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/splash_screen.dart';
import 'helpers/auth_helper.dart';
import 'helpers/config.dart';
import 'helpers/deep_link_helper.dart';
import 'helpers/route_observer.dart';
// import 'helpers/runtime_config.dart';
import 'helpers/version_helper.dart';
import 'styles/app_styles.dart';
import 'providers/league_provider.dart';
import 'providers/accessibility_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize runtime configuration
  // await RuntimeConfig().initialize();

  // Read the real app version from the platform package before anything runs.
  // The forced update check on the splash screen compares this against the
  // minimum version held in the app_version_requirement table on the server.
  await Config.loadAppVersion();

  // Start listening for shared league links (https://splitleague.noodev8.com/l/<code>)
  // Done before runApp so a link that launched the app is not missed.
  await DeepLinkHelper.initialise();

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
            cardTheme: CardThemeData(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );

          // Apply high contrast if needed
          final theme = accessibilityProvider.getThemeData(baseTheme);

          return RefreshConfiguration(
            // Make pull-to-refresh less sensitive
            headerTriggerDistance: 120.0, // Default is 80.0, higher means less sensitive
            dragSpeedRatio: 0.7, // Default is 1.0, lower means more drag required
            // Adjust spring animation to feel less "jumpy"
            springDescription: const SpringDescription(
              mass: 2.5,       // Default is 2.2
              stiffness: 120,  // Default is 150, lower means less "snap back" force
              damping: 20,     // Default is 16, higher means more damping
            ),
            // Other configuration options
            enableScrollWhenRefreshCompleted: true,
            enableBallisticRefresh: false,
            child: MaterialApp(
              // Lets a deep link drive navigation from outside the widget tree
              navigatorKey: DeepLinkHelper.navigatorKey,
              // Lets a screen know when it comes back into view - see route_observer.dart
              navigatorObservers: [routeObserver],
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
              home: const SplashScreen(),
            ),
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

  // Launch app store based on platform
  Future<void> _launchAppStore() async {
    String storeUrl;

    if (Platform.isIOS) {
      // iOS App Store URL
      storeUrl = 'https://apps.apple.com/us/app/split-league/id6745337065';
    } else if (Platform.isAndroid) {
      // Google Play Store URL
      storeUrl = 'https://play.google.com/store/apps/details?id=com.noodev8.splitleague';
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
