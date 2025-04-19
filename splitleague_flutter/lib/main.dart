/*
Main entry point for the SplitLeague Flutter application
Sets up the MaterialApp and handles initial routing based on authentication status
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/login_user_screen.dart';
import 'screens/dashboard_screen.dart';
import 'helpers/auth_helper.dart';
import 'styles/app_styles.dart';
import 'providers/league_provider.dart';
import 'providers/accessibility_provider.dart';

void main() {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

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

          // Create base theme
          final baseTheme = ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppStyles.primaryColor,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
            scaffoldBackgroundColor: AppStyles.backgroundColor,
            appBarTheme: const AppBarTheme(
              backgroundColor: AppStyles.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
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

    setState(() {
      _isLoggedIn = isLoggedIn;
      _isLoading = false;
    });
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
