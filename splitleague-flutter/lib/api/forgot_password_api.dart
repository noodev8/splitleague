/*
API service for forgot password functionality
Handles the API call to request a password reset email
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';

class ForgotPasswordApi {
  // Request password reset email
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/forgot_password');
    
    try {
      // Send POST request to the server
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'email': email,
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
