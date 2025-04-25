/*
Helper class for version-related functionality
Provides methods to check if the current app version meets the minimum required version
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

      // Get the minimum required version from the server
      final response = await GetAppVersionApi.getAppVersion(platform);

      // Check if the request was successful
      if (response['return_code'] == 'SUCCESS') {
        // Get the minimum required version
        final String minimumVersion = response['minimum_version'];
        
        // Get the current app version
        final String currentVersion = Config.appVersion;

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

  // Compare two version strings
  // Returns:
  //  1 if version1 > version2
  //  0 if version1 == version2
  // -1 if version1 < version2
  static int _compareVersions(String version1, String version2) {
    // Split versions into parts
    final List<String> v1Parts = version1.split('.');
    final List<String> v2Parts = version2.split('.');

    // Get the maximum length
    final int maxLength = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    // Compare each part
    for (int i = 0; i < maxLength; i++) {
      // Get the parts, defaulting to 0 if not present
      final int v1Part = i < v1Parts.length ? int.parse(v1Parts[i]) : 0;
      final int v2Part = i < v2Parts.length ? int.parse(v2Parts[i]) : 0;

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
}
