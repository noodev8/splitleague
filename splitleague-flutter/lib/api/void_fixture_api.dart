/*
API service for voiding (deleting) fixtures
Allows league organizers to remove fixtures from the system
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/config.dart';
import '../helpers/auth_helper.dart';

class VoidFixtureApi {
  // Void a fixture by its ID
  static Future<Map<String, dynamic>> voidFixture(int fixtureId) async {
    // Create the request URL
    final url = Uri.parse('${Config.baseUrl}/void_fixture');

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
        'fixture_id': fixtureId,
      };

      // Send POST request to the server
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Parse response
      final responseData = jsonDecode(response.body);

      // Return the response data
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
