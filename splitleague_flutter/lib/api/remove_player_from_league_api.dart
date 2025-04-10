/*
API service for removing a player from a league
Allows a league organizer to remove a player from their league
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class RemovePlayerFromLeagueApi {
  // Remove a player from a league
  static Future<Map<String, dynamic>> removePlayerFromLeague(int leagueId, int playerId) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/remove_player_from_league');

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
          'player_id': playerId,
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
