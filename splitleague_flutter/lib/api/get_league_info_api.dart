/*
API service for retrieving league information
Fetches detailed information about a specific league
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class GetLeagueInfoApi {
  // Get league information
  static Future<Map<String, dynamic>> getLeagueInfo(int leagueId) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/get_league_info');
    
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
          'league_id': leagueId,
        }),
      );
      
      // Check if response is successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        try {
          // Parse the response
          final Map<String, dynamic> responseData = jsonDecode(response.body);
          
          // Return the response data
          return responseData;
        } catch (e) {
          // Handle JSON parsing error
          return {
            'return_code': 'PARSE_ERROR',
            'message': 'Failed to parse server response: ${e.toString()}',
          };
        }
      } else {
        // Try to parse error message from response if possible
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return {
            'return_code': errorData['return_code'] ?? 'HTTP_ERROR',
            'message': errorData['message'] ?? 'Server returned error code: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'return_code': 'HTTP_ERROR',
            'message': 'Server returned error code: ${response.statusCode}',
          };
        }
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
