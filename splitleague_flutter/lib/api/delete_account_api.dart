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
      
      // TODO: Implement the actual API call when ready
      // For now, return a mock success response
      return {
        'return_code': 'SUCCESS',
        'message': 'Account successfully deleted'
      };
      
      // Uncomment this code when ready to implement the actual API call
      /*
      // Make API request
      final response = await http.post(
        Uri.parse('${Config.apiUrl}/delete_account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );
      
      // Parse response
      final responseData = jsonDecode(response.body);
      
      // Return response data
      return responseData;
      */
    } catch (e) {
      // Return error response
      return {
        'return_code': 'SERVER_ERROR',
        'message': 'An error occurred while processing your request'
      };
    }
  }
}
