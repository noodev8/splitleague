/*
API for getting league table standings
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class GetLeagueTableApi {
  static Future<Map<String, dynamic>> getLeagueTable(int leagueId) async {
    final url = Uri.parse('${Config.baseUrl}/get_league_table');

    try {
      final token = await AuthHelper.getToken();

      if (token == null) {
        return {
          'return_code': 'UNAUTHORIZED',
          'message': 'Authentication token not found',
        };
      }

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'league_id': leagueId,  // Using league_id
        }),
      );

      // Parse the response
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['return_code'] == 'SUCCESS') {
        return {
          'return_code': 'SUCCESS',
          'standings': data['standings'],
        };
      } else {
        return {
          'return_code': 'ERROR',
          'message': data['message'] ?? 'Failed to get league table',
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

