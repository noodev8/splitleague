/*
API client for getting the minimum required app version for a specific platform
This API does not require authentication
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';

class GetAppVersionApi {
  // Base URL from config
  static final String baseUrl = Config.baseUrl;

  // Get minimum app version for a platform
  static Future<Map<String, dynamic>> getAppVersion(String platform) async {
    try {
      // Prepare request URL
      final url = Uri.parse('$baseUrl/get_app_version');

      // Prepare request body
      final body = jsonEncode({
        'platform': platform,
      });

      // Make POST request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      // Parse response
      final responseData = jsonDecode(response.body);

      // Return response data
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
