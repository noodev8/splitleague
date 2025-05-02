/*
API service for deleting a user account
Handles the API call to delete the user's account and all associated data
*/

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../helpers/auth_helper.dart';
import '../helpers/config.dart';

class DeleteAccountApi {
  // Delete user account
  static Future<Map<String, dynamic>> deleteAccount({String? reason}) async {
    try {
      // Get the JWT token
      String? token = await AuthHelper.getToken();

      if (token == null) {
        return {
          'return_code': 'UNAUTHORIZED',
          'message': 'You are not authorized to perform this action'
        };
      }

      // Prepare request body
      Map<String, dynamic> requestBody = {};

      // Add reason if provided
      if (reason != null && reason.isNotEmpty) {
        requestBody['reason'] = reason;
      }

      // Create request URL
      final url = Uri.parse('${Config.baseUrl}/delete_account');

      // Make API request
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      // Check if response is successful
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Parse response
        final responseData = jsonDecode(response.body);

        // Return response data
        return responseData;
      } else {
        // Try to parse error message from response if possible
        try {
          final Map<String, dynamic> errorData = jsonDecode(response.body);
          return {
            'return_code': errorData['return_code'] ?? 'HTTP_ERROR',
            'message': errorData['message'] ?? 'Server returned error code: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'return_code': 'HTTP_ERROR',
            'message': 'Server returned error code: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      // Return error response
      return {
        'return_code': 'SERVER_ERROR',
        'message': 'Failed to connect to server: ${e.toString()}'
      };
    }
  }
}
