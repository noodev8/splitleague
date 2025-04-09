/*
API service for retrieving user leagues
Fetches all leagues that the authenticated user is a member of
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class GetUserLeaguesApi {
  // Get all leagues for the authenticated user
  static Future<Map<String, dynamic>> getUserLeagues() async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/get_user_leagues');

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
        body: jsonEncode({}), // Empty body as no parameters are needed
      );

      // Check if response is successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          // Parse the response
          final Map<String, dynamic> responseData = jsonDecode(response.body);

          // Return the response data
          return responseData;
        } catch (e) {
          // Error is handled in the return statement below
          return {
            'return_code': 'PARSE_ERROR',
            'message': 'Failed to parse server response: ${e.toString()}',
          };
        }
      } else {
        // Error is handled in the return statement below
        return {
          'return_code': 'HTTP_ERROR',
          'message': 'Server returned error code: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Return error response if request fails
      return {
        'return_code': 'SERVER_ERROR',
        'message': 'Failed to connect to server: ${e.toString()}',
      };
    }
  }
}
