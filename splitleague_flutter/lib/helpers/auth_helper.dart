/*
Authentication helper for the SplitLeague application
Handles JWT token storage, retrieval, and validation
*/

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class AuthHelper {
  // Create storage
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  
  // Key for storing the JWT token
  static const String _tokenKey = 'jwt_token';
  
  // Key for storing user data
  static const String _userDataKey = 'user_data';
  
  // Save JWT token to secure storage
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }
  
  // Get JWT token from secure storage
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }
  
  // Delete JWT token from secure storage (logout)
  static Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
  
  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    String? token = await getToken();
    return token != null && token.isNotEmpty;
  }
  
  // Save user data to secure storage
  static Future<void> saveUserData(Map<String, dynamic> userData) async {
    String userDataJson = jsonEncode(userData);
    await _storage.write(key: _userDataKey, value: userDataJson);
  }
  
  // Get user data from secure storage
  static Future<Map<String, dynamic>?> getUserData() async {
    String? userDataJson = await _storage.read(key: _userDataKey);
    if (userDataJson != null) {
      return jsonDecode(userDataJson);
    }
    return null;
  }
  
  // Delete user data from secure storage (logout)
  static Future<void> deleteUserData() async {
    await _storage.delete(key: _userDataKey);
  }
  
  // Perform logout (clear all auth data)
  static Future<void> logout() async {
    await deleteToken();
    await deleteUserData();
  }

  // Check if response indicates unauthorized access
  static bool isUnauthorizedResponse(Map<String, dynamic> response) {
    final returnCode = response['return_code'];
    return returnCode == 'UNAUTHORIZED' || returnCode == 'INVALID_TOKEN';
  }

  // Handle unauthorized response - clears auth data and returns true if unauthorized
  static Future<bool> handleUnauthorizedResponse(Map<String, dynamic> response) async {
    if (isUnauthorizedResponse(response)) {
      await logout();
      return true;
    }
    return false;
  }
}
