/*
API service for adding a guest player to a league
Allows a league organizer to add a guest player without requiring registration
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class AddGuestPlayerApi {
  // Add a guest player to a league
  static Future<Map<String, dynamic>> addGuestPlayer({
    required int leagueId,
    String? guestNickname,
  }) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/add_guest_player');

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
        'league_id': leagueId,
      };

      // Add guest nickname if provided
      if (guestNickname != null && guestNickname.isNotEmpty) {
        requestBody['guest_nickname'] = guestNickname;
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
