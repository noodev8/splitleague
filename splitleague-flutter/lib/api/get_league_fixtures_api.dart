/*
API service for retrieving league fixtures
Fetches all fixtures for a specific league
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class GetLeagueFixturesApi {
  // Get all fixtures for a league
  static Future<Map<String, dynamic>> getLeagueFixtures(int leagueId) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/get_league_fixtures');

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
          'league_id': leagueId, // This parameter name stays the same as it matches the server API
        }),
      );

      // Parse the response body (works for both success and error responses)
      try {
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        // Return the parsed response (contains return_code from server)
        return responseData;
      } catch (e) {
        // If we can't parse the JSON, return a generic error
        return {
          'return_code': 'PARSE_ERROR',
          'message': 'Failed to parse server response: ${e.toString()}',
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
