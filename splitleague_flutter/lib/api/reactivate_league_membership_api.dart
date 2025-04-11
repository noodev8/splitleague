/*
API service for reactivating league membership
Allows a user to add a previously hidden league back to their dashboard
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class ReactivateLeagueMembershipApi {
  // Reactivate membership in a league
  static Future<Map<String, dynamic>> reactivateLeagueMembership(int leagueId) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/reactivate_league_membership');

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
