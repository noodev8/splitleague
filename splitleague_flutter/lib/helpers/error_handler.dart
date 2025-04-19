/*
Centralized error handling for the SplitLeague app
Provides consistent error handling, display, and recovery mechanisms
*/

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:async';

enum ErrorSeverity {
  info,
  warning,
  error,
  critical,
}

class ErrorHandler {
  // Singleton instance
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  // Error callback for global error handling
  static Function(String, ErrorSeverity)? onError;

  // Show a toast message
  static Future<bool?> showToast({
    required String message,
    Color backgroundColor = Colors.red,
    Color textColor = Colors.white,
    ToastGravity gravity = ToastGravity.BOTTOM,
    Toast length = Toast.LENGTH_LONG,
  }) {
    return Fluttertoast.showToast(
      msg: message,
      toastLength: length,
      gravity: gravity,
      timeInSecForIosWeb: 3,
      backgroundColor: backgroundColor,
      textColor: textColor,
      fontSize: 16.0,
    );
  }

  // Show an error toast
  static Future<bool?> showErrorToast(String message) {
    // Log the error
    _logError(message, ErrorSeverity.error);

    // Show toast
    return showToast(
      message: message,
      backgroundColor: Colors.red.shade700,
    );
  }

  // Show a warning toast
  static Future<bool?> showWarningToast(String message) {
    // Log the warning
    _logError(message, ErrorSeverity.warning);

    // Show toast
    return showToast(
      message: message,
      backgroundColor: Colors.orange.shade700,
    );
  }

  // Show a success toast
  static Future<bool?> showSuccessToast(String message) {
    return showToast(
      message: message,
      backgroundColor: Colors.green.shade700,
    );
  }

  // Show an info toast
  static Future<bool?> showInfoToast(String message) {
    return showToast(
      message: message,
      backgroundColor: Colors.blue.shade700,
    );
  }

  // Show a snackbar
  static void showSnackBar(
    BuildContext context, {
    required String message,
    Color backgroundColor = Colors.red,
    Color textColor = Colors.white,
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final snackBar = SnackBar(
      content: Text(
        message,
        style: TextStyle(color: textColor),
      ),
      backgroundColor: backgroundColor,
      duration: duration,
      action: action,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  // Show an error dialog
  static Future<void> showErrorDialog(
    BuildContext context, {
    required String title,
    required String message,
    String primaryButtonText = 'OK',
    String? secondaryButtonText,
    VoidCallback? onPrimaryButtonPressed,
    VoidCallback? onSecondaryButtonPressed,
  }) async {
    // Log the error
    _logError(message, ErrorSeverity.error);

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: <Widget>[
            if (secondaryButtonText != null)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (onSecondaryButtonPressed != null) {
                    onSecondaryButtonPressed();
                  }
                },
                child: Text(secondaryButtonText),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (onPrimaryButtonPressed != null) {
                  onPrimaryButtonPressed();
                }
              },
              child: Text(primaryButtonText),
            ),
          ],
        );
      },
    );
  }

  // Show a retry dialog
  static Future<bool> showRetryDialog(
    BuildContext context, {
    required String title,
    required String message,
    String retryButtonText = 'Retry',
    String cancelButtonText = 'Cancel',
  }) async {
    // Log the error
    _logError(message, ErrorSeverity.warning);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(message),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelButtonText),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: Text(retryButtonText),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // Handle API errors
  static String handleApiError(Map<String, dynamic> response, String defaultMessage) {
    // Special case for 'No fixtures' - don't treat as an error
    if (response['return_code'] == 'NO_FIXTURES') {
      return '';
    }

    if (response['message'] != null) {
      return response['message'];
    }

    return defaultMessage;
  }

  // Handle exceptions
  static String handleException(dynamic exception, String defaultMessage) {
    // Log the exception
    _logError(exception.toString(), ErrorSeverity.error);

    if (exception is TimeoutException) {
      return 'The operation timed out. Please check your internet connection and try again.';
    } else if (exception.toString().contains('SocketException')) {
      return 'No internet connection. Please check your network settings and try again.';
    } else if (exception.toString().contains('HttpException')) {
      return 'Unable to connect to the server. Please try again later.';
    }

    return defaultMessage;
  }

  // Log error to console and call error callback if set
  static void _logError(String message, ErrorSeverity severity) {
    // In a production app, we would use a proper logging framework here
    // For now, we'll use debugPrint which is safer than print
    // debugPrint is automatically removed in release builds
    switch (severity) {
      case ErrorSeverity.info:
        debugPrint('INFO: $message');
        break;
      case ErrorSeverity.warning:
        debugPrint('WARNING: $message');
        break;
      case ErrorSeverity.error:
        debugPrint('ERROR: $message');
        break;
      case ErrorSeverity.critical:
        debugPrint('CRITICAL: $message');
        break;
    }

    // Call error callback if set
    if (onError != null) {
      onError!(message, severity);
    }
  }

  // Execute a function with error handling
  static Future<T?> executeWithErrorHandling<T>({
    required BuildContext context,
    required Future<T> Function() function,
    required String errorMessage,
    bool showLoadingIndicator = true,
    bool showErrorDialog = true,
    bool allowRetry = true,
    VoidCallback? onError,
  }) async {
    if (showLoadingIndicator) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
    }

    try {
      final result = await function();

      if (showLoadingIndicator && context.mounted) {
        Navigator.of(context).pop();
      }

      return result;
    } catch (e) {
      if (showLoadingIndicator && context.mounted) {
        Navigator.of(context).pop();
      }

      final errorMsg = handleException(e, errorMessage);

      if (context.mounted) {
        if (showErrorDialog) {
          if (allowRetry) {
            final retry = await showRetryDialog(
              context,
              title: 'Error',
              message: errorMsg,
            );

            if (retry && context.mounted) {
              return executeWithErrorHandling(
                context: context,
                function: function,
                errorMessage: errorMessage,
                showLoadingIndicator: showLoadingIndicator,
                showErrorDialog: showErrorDialog,
                allowRetry: allowRetry,
                onError: onError,
              );
            }
          } else {
            await ErrorHandler.showErrorDialog(
              context,
              title: 'Error',
              message: errorMsg,
            );
          }
        } else {
          showErrorToast(errorMsg);
        }
      }

      if (onError != null) {
        onError();
      }

      return null;
    }
  }
}
