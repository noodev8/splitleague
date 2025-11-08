/*
Configuration file for the SplitLeague application
Contains global configuration settings like API base URL and version information
*/

import 'runtime_config.dart';

class Config {
  // Get the base URL from RuntimeConfig
  static String get baseUrl => RuntimeConfig().baseUrl;

  // App version information
  static const String appVersion = '1.10';

  // Build timestamp (for developer screen)
  static final String buildTimestamp = DateTime.now().toString();
}
