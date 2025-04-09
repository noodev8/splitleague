/*
API service for updating fixture scores
Allows users to submit scores for fixtures they're involved in
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class UpdateFixtureScoreApi {
  // Update score for a fixture
  static Future<Map<String, dynamic>> updateFixtureScore(
    int fixtureId, 
    int player1Score, 
    int player2Score
  ) async {
    // Create the request URL
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
      
      // Send POST request to the server
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fixture_id': fixtureId,
          'player_1_score': player1Score,
          'player_2_score': player2Score,
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
