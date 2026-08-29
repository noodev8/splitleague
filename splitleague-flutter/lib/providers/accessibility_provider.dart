/*
Accessibility provider for the SplitLeague app
Manages accessibility settings and provides them to the app
*/

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AccessibilityProvider extends ChangeNotifier {
  bool _highContrast = false;
  bool _largeText = false;
  bool _reduceAnimations = false;
  bool _isLoaded = false;

  bool get highContrast => _highContrast;
  bool get largeText => _largeText;
  bool get reduceAnimations => _reduceAnimations;
  bool get isLoaded => _isLoaded;

  AccessibilityProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _highContrast = prefs.getBool('high_contrast') ?? false;
    _largeText = prefs.getBool('large_text') ?? false;
    _reduceAnimations = prefs.getBool('reduce_animations') ?? false;
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('high_contrast', value);
    notifyListeners();
  }

  Future<void> setLargeText(bool value) async {
    _largeText = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('large_text', value);
    notifyListeners();
  }

  Future<void> setReduceAnimations(bool value) async {
    _reduceAnimations = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('reduce_animations', value);
    notifyListeners();
  }

  // Get text scale factor based on settings
  double getTextScaleFactor() {
    return _largeText ? 1.3 : 1.0;
  }

  // Get theme data based on settings
  ThemeData getThemeData(ThemeData baseTheme) {
    if (!_highContrast) {
      return baseTheme;
    }

    // Create a high contrast theme
    return baseTheme.copyWith(
      colorScheme: baseTheme.colorScheme.copyWith(
        // Increase contrast for text and background
        //
        // background/onBackground were deprecated aliases of surface/onSurface and were
        // being set to the same values, so they were removed rather than renamed.
        surface: Colors.white,
        onSurface: Colors.black,
        // Make primary color darker for better contrast
        primary: Colors.blue.shade800,
        onPrimary: Colors.white,
        // Make secondary color darker for better contrast
        secondary: Colors.blue.shade900,
        onSecondary: Colors.white,
      ),
      textTheme: baseTheme.textTheme.apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
      scaffoldBackgroundColor: Colors.white,
      cardColor: Colors.white,
      dividerColor: Colors.black45,
    );
  }
}
