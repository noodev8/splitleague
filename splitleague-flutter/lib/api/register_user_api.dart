/*
API service for user registration
Handles registration with the server and returns the response
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';

class RegisterUserApi {
  // Register user with name, email, and password
  static Future<Map<String, dynamic>> registerUser(String name, String nickname, String email, String password) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/register_user');

    try {
      // Send POST request to the server
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'name': name,
          'nickname': nickname,
          'email': email,
          'password': password,
        }),
      );

      // Parse the response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Return the response data
      return responseData;
    } catch (e) {
      // Return error response if request fails
      return {
        'return_code': 'SERVER_ERROR',
        'message': 'Failed to connect to server: ${e.toString()}',
      };
    }
  }
}
