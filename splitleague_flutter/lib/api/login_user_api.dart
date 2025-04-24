/*
API service for user login
Handles authentication with the server and returns the response
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';

class LoginUserApi {
  // Login user with email and password
  static Future<Map<String, dynamic>> loginUser(String email, String password) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/login_user');

    try {
      // Send POST request to the server
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
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
