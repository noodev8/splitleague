/*
Error handling helper for the SplitLeague application
Provides functions to display error messages and handle API errors
*/

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../styles/app_styles.dart';

class ErrorHelper {
  // Show error toast message
  static void showErrorToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: AppStyles.errorColor,
      textColor: Colors.white,
      fontSize: 16.0
    );
  }
  
  // Show success toast message
  static void showSuccessToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: AppStyles.successColor,
      textColor: Colors.white,
      fontSize: 16.0
    );
  }
  
  // Handle API error response
  static String getErrorMessage(Map<String, dynamic> response) {
    // Get the return code from the response
    String returnCode = response['return_code'] ?? 'UNKNOWN_ERROR';
    
    // Map return codes to user-friendly messages
    switch (returnCode) {
      case 'MISSING_FIELDS':
        return 'Please fill in all required fields.';
      case 'INVALID_CREDENTIALS':
        return 'Invalid email or password.';
      case 'EMAIL_ALREADY_EXISTS':
        return 'An account with this email already exists.';
      case 'SERVER_ERROR':
        return 'Server error. Please try again later.';
      case 'UNAUTHORIZED':
        return 'You are not authorized to perform this action.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
