/*
API service for creating a new league
Handles league creation with the server and returns the response
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class CreateLeagueApi {
  // Create a new league
  static Future<Map<String, dynamic>> createLeague({
    required String name,
    int? pointsForWin,
    int? pointsForDraw,
    int? pointsForWinMargin,
    int? pointsForCloseLoss,
    int? winMarginThreshold,
    int? playEachOther,
  }) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/create_league');

    try {
      // Get the JWT token
      final token = await AuthHelper.getToken();

      if (token == null) {
        return {
          'return_code': 'UNAUTHORIZED',
          'message': 'Authentication token not found',
        };
      }

      // Prepare request body as a Map<String, dynamic> to handle different types
      final Map<String, dynamic> body = {
        'name': name,
      };

      // Add optional parameters if provided
      if (pointsForWin != null) body['points_for_win'] = pointsForWin;
      if (pointsForDraw != null) body['points_for_draw'] = pointsForDraw;
      if (pointsForWinMargin != null) body['points_for_win_margin'] = pointsForWinMargin;
      if (pointsForCloseLoss != null) body['points_for_close_loss'] = pointsForCloseLoss;
      if (winMarginThreshold != null) body['win_margin_threshold'] = winMarginThreshold;
      if (playEachOther != null) body['play_each_other'] = playEachOther;

      // Send POST request to the server
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
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
