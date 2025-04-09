/*
API for getting league table standings
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

Future<Map<String, dynamic>> getLeagueTable(int leagueId) async {
  try {
    // Get the auth token
    final token = await AuthHelper.getToken();

    if (token == null) {
      return {
        'success': false,
        'message': 'Authentication token not found',
      };
    }

    // Prepare the request
    final url = Uri.parse('${Config.baseUrl}/get_league_table');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = jsonEncode({
      'league_id': leagueId,
    });

    // Make the API call
    final response = await http.post(url, headers: headers, body: body);

    // Parse the response
    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['return_code'] == 'SUCCESS') {
      return {
        'success': true,
        'standings': data['standings'],
      };
    } else {
      return {
        'success': false,
        'message': data['message'] ?? 'Failed to get league table',
      };
    }
  } catch (e) {
    return {
      'success': false,
      'message': 'An error occurred: $e',
    };
  }
}
