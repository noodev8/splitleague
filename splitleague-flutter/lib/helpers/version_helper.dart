/*
Helper class for version-related functionality
Provides methods to check if the current app version meets the minimum required version

The minimum version lives in the app_version_requirement table on the server, one
row per platform. Raising that row is what forces existing installs to update.
*/

import 'dart:io';
import 'package:flutter/foundation.dart';
import '../api/get_app_version_api.dart';
import 'config.dart';

class VersionHelper {
  // Check if the current app version meets the minimum required version
  static Future<bool> isAppVersionValid() async {
    try {
      // Determine the current platform
      String platform;
      if (Platform.isAndroid) {
        platform = 'android';
      } else if (Platform.isIOS) {
        platform = 'ios';
      } else {
        // For web or desktop, assume it's valid
        return true;
      }

      // Get the current app version (loaded from the platform package in main())
      final String currentVersion = Config.appVersion;

      // If the version could not be read we must not lock the user out.
      // '0.0.0' is the "not loaded" placeholder set in config.dart
      if (currentVersion.isEmpty || currentVersion == '0.0.0') {
        return true;
      }

      // Get the minimum required version from the server
      final response = await GetAppVersionApi.getAppVersion(platform);

      // Check if the request was successful
      if (response['return_code'] == 'SUCCESS') {
        // Get the minimum required version
        final String minimumVersion = response['minimum_version'].toString();

        // A blank minimum means nothing is being enforced - let the user in
        if (minimumVersion.trim().isEmpty) {
          return true;
        }

        // Compare versions
        return _compareVersions(currentVersion, minimumVersion) >= 0;
      } else {
        // If there was an error, assume the version is valid
        // This prevents blocking users due to server issues
        return true;
      }
    } catch (e) {
      // If there was an exception, assume the version is valid
      debugPrint('Error checking app version: $e');
      return true;
    }
  }

  // Compare two version strings, e.g. "1.2.0" against "1.10"
  // Returns:
  //  1 if version1 > version2
  //  0 if version1 == version2
  // -1 if version1 < version2
  static int _compareVersions(String version1, String version2) {
    // Break each version into its numeric parts
    final List<int> v1Parts = _parseVersion(version1);
    final List<int> v2Parts = _parseVersion(version2);

    // Get the maximum length
    final int maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    // Compare each part
    for (int i = 0; i < maxLength; i++) {
      // Get the parts, defaulting to 0 if not present
      final int v1Part = i < v1Parts.length ? v1Parts[i] : 0;
      final int v2Part = i < v2Parts.length ? v2Parts[i] : 0;

      // Compare parts
      if (v1Part > v2Part) {
        return 1;
      } else if (v1Part < v2Part) {
        return -1;
      }
    }

    // If we get here, the versions are equal
    return 0;
  }

  // Turn a version string into a list of numbers
  //
  // Tolerates anything the stores or the database might hand us:
  //   "1.2.0"      -> [1, 2, 0]
  //   "1.1.2+112"  -> [1, 1, 2]      build number after "+" is dropped
  //   "2.0.0-beta" -> [2, 0, 0]      pre-release suffix after "-" is dropped
  //   "1.05"       -> [1, 5]         old two-digit database values still work
  // A segment that is not a number counts as 0 rather than throwing
  static List<int> _parseVersion(String version) {
    // Drop any build metadata or pre-release suffix
    String cleaned = version.trim().split('+').first.split('-').first;

    // Convert each dot-separated segment to a number
    final List<int> parts = [];

    for (final String segment in cleaned.split('.')) {
      parts.add(int.tryParse(segment.trim()) ?? 0);
    }

    return parts;
  }
}
