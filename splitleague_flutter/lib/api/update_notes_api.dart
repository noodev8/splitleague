/*
API service for updating organizer notes for a league member
Allows a league organizer to add/update notes for a specific member
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class UpdateNotesApi {
  // Update notes for a league member
  static Future<Map<String, dynamic>> updateNotes({
    required int leagueId,
    required int userId,
    required String notes,
  }) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/update_notes');

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
          'user_id': userId,
          'notes': notes,
        }),
      );

      // Parse response
      final responseData = jsonDecode(response.body);
      return responseData;
    } catch (e) {
      // Return error response
      return {
        'return_code': 'SERVER_ERROR',
        'message': 'Failed to connect to server: $e',
      };
    }
  }
}
