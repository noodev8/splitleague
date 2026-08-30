/*
Screen for changing user password
Allows users to update their password by providing current and new password
*/

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/change_password_api.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Password visibility
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _confirmPasswordVisible = false;

  // Loading state
  bool _isLoading = false;

  // Error message
  String? _errorMessage;

  @override
  void dispose() {
    // Clean up controllers
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Toggle password visibility
  void _toggleCurrentPasswordVisibility() {
    setState(() {
      _currentPasswordVisible = !_currentPasswordVisible;
    });
  }

  void _toggleNewPasswordVisibility() {
    setState(() {
      _newPasswordVisible = !_newPasswordVisible;
    });
  }

  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _confirmPasswordVisible = !_confirmPasswordVisible;
    });
  }

  // Handle save button press
  Future<void> _handleSave() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get form values
      String currentPassword = _currentPasswordController.text;
      String newPassword = _newPasswordController.text;

      // Call change password API
      Map<String, dynamic> response = await ChangePasswordApi.changePassword(
        currentPassword,
        newPassword,
      );

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Show success message
        ErrorHelper.showSuccessToast('Password changed');

        // Go back to profile screen
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Show error message
        setState(() {
          _errorMessage = ErrorHelper.getErrorMessage(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      // Show error message
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Change Password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        color: AppStyles.backgroundColor,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Security icon
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppStyles.primaryColor.withAlpha(40),
                      child: Icon(
                        Icons.lock_outline,
                        size: 50,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Current password field
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextFormField(
                        controller: _currentPasswordController,
                        decoration: AppStyles.inputDecoration(
                          'Current Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _currentPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: _toggleCurrentPasswordVisibility,
                          ),
                        ),
                        obscureText: !_currentPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Enter your current password';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // New password field
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextFormField(
                        controller: _newPasswordController,
                        decoration: AppStyles.inputDecoration(
                          'New Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _newPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: _toggleNewPasswordVisibility,
                          ),
                        ),
                        obscureText: !_newPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Choose a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm password field
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextFormField(
                        controller: _confirmPasswordController,
                        decoration: AppStyles.inputDecoration(
                          'Confirm New Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _confirmPasswordVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: _toggleConfirmPasswordVisibility,
                          ),
                        ),
                        obscureText: !_confirmPasswordVisible,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your new password';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error message
                  if (_errorMessage != null)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      color: AppStyles.errorColor.withAlpha(25),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: AppStyles.errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  if (_errorMessage != null) const SizedBox(height: 24),

                  // Save button
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSave,
                        style: AppStyles.primaryButtonStyle,
                        child:
                            _isLoading
                                ? const SpinKitThreeBounce(
                                  color: Colors.white,
                                  size: 24,
                                )
                                : const Text(
                                  'Change Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
