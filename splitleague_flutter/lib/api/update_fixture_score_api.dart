/*
API service for updating fixture scores
Allows users to submit scores for fixtures they're involved in
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class UpdateFixtureScoreApi {
  // Update score for a fixture with points
  static Future<Map<String, dynamic>> updateFixtureScore(
    int fixtureId,
    int player1Score,
    int player2Score
  ) async {
    return _updateFixture(fixtureId, player1Score: player1Score, player2Score: player2Score);
  }

  // Update score for a fixture with result (WIN/DRAW)
  static Future<Map<String, dynamic>> updateFixtureResult(
    int fixtureId,
    String result
  ) async {
    return _updateFixture(fixtureId, result: result);
  }

  // Private method to handle both types of updates
  static Future<Map<String, dynamic>> _updateFixture(
    int fixtureId, {
    int? player1Score,
    int? player2Score,
    String? result
  }) async {
    final url = Uri.parse('${Config.baseUrl}/update_fixture_score');

    try {
      // Get the JWT token
      final token = await AuthHelper.getToken();

      if (token == null) {
        return {
          'return_code': 'UNAUTHORIZED',
          'message': 'Authentication token not found',
        };
      }

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'fixture_id': fixtureId,
      };

      // Add either scores or result based on what was provided
      if (player1Score != null && player2Score != null) {
        requestBody['player_1_score'] = player1Score;
        requestBody['player_2_score'] = player2Score;
      } else if (result != null) {
        requestBody['result'] = result;
      }

      // Send POST request to the server
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
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
