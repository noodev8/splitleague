/*
API to get standings for a league
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class GetStandingsApi {
  // Get standings for a league
  static Future<Map<String, dynamic>> getStandings(dynamic leagueId) async {
    try {
      // Get token from secure storage
      final String? token = await AuthHelper.getToken();
      if (token == null) {
        return {
          'return_code': 'ERROR',
          'message': 'Authentication token not found',
        };
      }

      // Create request URL
      final url = Uri.parse('${Config.baseUrl}/get_league_table');

      // Create request body
      final body = {
        'league_id': leagueId.toString(),
      };

      // Send request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      // Parse response
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      // Check if request was successful
      if (response.statusCode == 200) {
        if (responseData['return_code'] == 'SUCCESS') {
          return {
            'return_code': 'SUCCESS',
            'standings': responseData['standings'] ?? [],
          };
        } else {
          return {
            'return_code': 'ERROR',
            'message': responseData['message'] ?? 'Failed to get standings',
          };
        }
      } else {
        return {
          'return_code': 'ERROR',
          'message': responseData['message'] ?? 'Failed to get standings',
        };
      }
    } catch (e) {
      return {
        'return_code': 'ERROR',
        'message': 'An error occurred: $e',
      };
    }
  }
}
