/*
API service for joining a league

The league is identified by its "league key", which is one of two things and the app does not
have to know which it is holding:

  a share slug   ten characters from an invite link, e.g. "7jwpbsz5ym"
  a public code  the 4 digits somebody was told out loud

The server works out which shape it has been given. That is what lets somebody who followed a
link join without ever being shown a code.
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class JoinLeagueApi {
  // Join a league using either a share slug or a 4-digit public code
  static Future<Map<String, dynamic>> joinLeague(String leagueKey) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/join_league');

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
          'league_key': leagueKey,
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
          // Error is handled in the return statement below
          return {
            'return_code': 'PARSE_ERROR',
            'message': 'Failed to parse server response: ${e.toString()}',
          };
        }
      } else {
        // Error is handled in the return statement below

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
