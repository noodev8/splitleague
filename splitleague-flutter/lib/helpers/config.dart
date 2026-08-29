/*
Configuration file for the SplitLeague application
Contains global configuration settings like API base URL and version information
*/

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'runtime_config.dart';

class Config {
  // Get the base URL from RuntimeConfig
  static String get baseUrl => RuntimeConfig().baseUrl;

  // App version information
  //
  // This is the REAL version of the running build, read from the platform
  // package at startup (Android versionName / iOS CFBundleShortVersionString),
  // both of which come from the "version:" line in pubspec.yaml.
  //
  // It used to be a hardcoded constant that never matched the shipped build,
  // which meant the forced update check compared the wrong number. Do not
  // hardcode it again - bump pubspec.yaml and this follows automatically.
  static String appVersion = '0.0.0';

  // Build number (Android versionCode / iOS CFBundleVersion) - developer info only
  static String appBuildNumber = '0';

  // Build timestamp (for developer screen)
  static final String buildTimestamp = DateTime.now().toString();

  // Load the real app version from the platform package
  // Called once from main() before the app is built
  static Future<void> loadAppVersion() async {
    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();

      appVersion = packageInfo.version;
      appBuildNumber = packageInfo.buildNumber;
    } catch (e) {
      // If the platform package cannot be read we leave the defaults in place.
      // The version check fails open, so a failure here never locks anyone out.
      debugPrint('Error loading app version: $e');
    }
  }
}
