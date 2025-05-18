/*
Runtime configuration manager for the SplitLeague application
Provides dynamic configuration that can be changed at runtime
*/

import 'package:shared_preferences/shared_preferences.dart';

class RuntimeConfig {
  // Singleton instance
  static final RuntimeConfig _instance = RuntimeConfig._internal();
  
  // Factory constructor to return the singleton instance
  factory RuntimeConfig() {
    return _instance;
  }
  
  // Private constructor
  RuntimeConfig._internal();
  
  // Default base URL (used if no custom URL is set)
  // static const String defaultBaseUrl = 'https://splitleague.noodev8.com'; // Default server
  static const String defaultBaseUrl = 'http://192.168.1.88:3000'; // Default server
   
  // Available base URLs for quick selection (development environments)
  static const Map<String, String> availableBaseUrls = {
    'Default': defaultBaseUrl,
    'Home Local': 'http://192.168.1.88:3000',
    'Chippy Local': 'http://192.168.1.174:3000',
    'Grays Aunty': 'http://192.168.1.88:3000',
    'Test VPS': 'https://test.splitleague.noodev8.com',
    'Prod VPS': 'https://splitleague.noodev8.com',
  };
  
  // Current base URL (initialized with default)
  String _baseUrl = defaultBaseUrl;
  
  // Getter for base URL
  String get baseUrl => _baseUrl;
  
  // Initialize runtime config (load from shared preferences)
  // Future<void> initialize() async {
  //  final prefs = await SharedPreferences.getInstance();
    // _baseUrl = prefs.getString('baseUrl') ?? defaultBaseUrl;
  // }
  
  // Set base URL and save to shared preferences
  Future<void> setBaseUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('baseUrl', url);
  }
  
  // Reset base URL to default
  Future<void> resetBaseUrl() async {
    await setBaseUrl(defaultBaseUrl);
  }
}



