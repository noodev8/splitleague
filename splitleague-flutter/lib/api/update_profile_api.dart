/*
API service for updating user profile information
Handles the API call to update name and nickname
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';
import '../helpers/config.dart';

class UpdateProfileApi {
  // Update user profile with name and nickname
  static Future<Map<String, dynamic>> updateProfile(String name, String nickname) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/update_profile');
    
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
          'name': name,
          'nickname': nickname,
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
