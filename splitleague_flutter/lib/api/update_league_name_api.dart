/*
API service for updating league name
Handles the API call to update the name of a league
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';
import '../helpers/config.dart';

class UpdateLeagueNameApi {
  // Update league name
  static Future<Map<String, dynamic>> updateLeagueName(int leagueId, String name) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/update_league_name');
    
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
          'name': name,
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
          // Error parsing response
          return {
            'return_code': 'PARSE_ERROR',
            'message': 'Failed to parse server response: ${e.toString()}',
          };
        }
      } else {
        // HTTP error
        return {
          'return_code': 'HTTP_ERROR',
          'message': 'Server returned error code: ${response.statusCode}',
        };
      }
    } catch (e) {
      // Network or other error
      return {
        'return_code': 'SERVER_ERROR',
        'message': 'Failed to connect to server: ${e.toString()}',
      };
    }
  }
}
