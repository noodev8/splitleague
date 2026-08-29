/*
API service for updating the user accessed timestamp
Updates when a user logs in or uses the app
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class UpdateUserAccessedApi {
  // Update the accessed timestamp for a user
  static Future<Map<String, dynamic>> updateUserAccessed() async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/update_user_accessed');

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
        body: jsonEncode({}),
      );

      // Parse the response
      final responseData = jsonDecode(response.body);

      // Return the response data
      return responseData;
    } catch (e) {
      // Return error response
      return {
        'return_code': 'ERROR',
        'message': 'An error occurred: $e',
      };
    }
  }
}
