/*
API service for changing user password
Handles the API call to update password
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';
import '../helpers/config.dart';

class ChangePasswordApi {
  // Change user password
  static Future<Map<String, dynamic>> changePassword(String currentPassword, String newPassword) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/change_password');
    
    try {
      // Get the JWT token
      final token = await AuthHelper.getToken();
      
      if (token == null) {
        return {
          'return_code': 'UNAUTHORIZED',
          'message': 'Authentication token not found',
        };
      }
      
      // Send POST request to the server
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
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
