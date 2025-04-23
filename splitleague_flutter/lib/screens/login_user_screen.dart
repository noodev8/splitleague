/*
Show the login screen allowing users to log into the application
This screen also has an option to Register if the user is not already registered
Once logged in, it goes straight to the dashboard
*/

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/login_user_api.dart';
import '../api/forgot_password_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../helpers/config.dart';
import '../styles/app_styles.dart';
import 'dashboard_screen.dart' as dashboard;
import 'register_user_screen.dart' as register;
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginUserScreen extends StatefulWidget {
  const LoginUserScreen({super.key});

  @override
  State<LoginUserScreen> createState() => _LoginUserScreenState();
}

class _LoginUserScreenState extends State<LoginUserScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Loading state
  bool _isLoading = false;

  // Error message
  String? _errorMessage;

  @override
  void dispose() {
    // Clean up controllers
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle login button press
  Future<void> _handleLogin() async {
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
      String email = _emailController.text.trim();
      String password = _passwordController.text;

      // Call login API
      Map<String, dynamic> response = await LoginUserApi.loginUser(email, password);

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Save token and user data
        await AuthHelper.saveToken(response['token']);
        await AuthHelper.saveUserData(response['user']);

        // Show success message
        ErrorHelper.showSuccessToast('Login successful!');

        // Navigate to dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const dashboard.DashboardScreen()),
          );
        }
      } else if (response['return_code'] == 'EMAIL_NOT_VERIFIED') {
        // Show dialog for unverified email
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Email Not Verified'),
                content: const Text('Please verify your email address to login. Would you like us to send a new verification email?'),
                actions: [
                  TextButton(
                    child: const Text('Cancel'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                  TextButton(
                    child: const Text('Resend Email'),
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await _resendVerificationEmail(email);
                    },
                  ),
                ],
              );
            },
          );
        }
        setState(() {
          _isLoading = false;
        });
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

  // Helper function to resend verification email
  Future<void> _resendVerificationEmail(String email) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final response = await http.post(
        Uri.parse('${Config.baseUrl}/resend_verification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final responseData = jsonDecode(response.body);

      if (responseData['return_code'] == 'SUCCESS') {
        ErrorHelper.showSuccessToast('Verification email sent! Please check your inbox.');
      } else {
        ErrorHelper.showErrorToast(ErrorHelper.getErrorMessage(responseData));
      }
    } catch (e) {
      ErrorHelper.showErrorToast('Failed to send verification email. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SplitLeague',
          style: TextStyle(
            fontWeight: FontWeight.bold
          )
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          color: AppStyles.backgroundColor,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: AppStyles.cardDecoration,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        const Text(
                          'Sign in to continue',
                          style: TextStyle(color: Colors.grey, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'SplitLeague helps friends run custom leagues and track scores\n— for any game, anytime, anywhere.',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Email field
                        TextFormField(
                          controller: _emailController,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => FocusScope.of(context).nextFocus(),
                          decoration: AppStyles.inputDecoration(
                            'Email',
                            prefixIcon: const Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password field
                        TextFormField(
                          controller: _passwordController,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) {
                            FocusScope.of(context).unfocus();
                            _handleLogin();
                          },
                          decoration: AppStyles.inputDecoration(
                            'Password',
                            prefixIcon: const Icon(Icons.lock),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a password';
                            }
                            return null;
                          },
                        ),
                        // Forgot Password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              _showForgotPasswordDialog();
                            },
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: AppStyles.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Error message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppStyles.errorColor.withAlpha(25),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppStyles.errorColor,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (_errorMessage != null) const SizedBox(height: 24),

                        // Login button
                        ElevatedButton(
                          onPressed: _isLoading ? null : () {
                            FocusScope.of(context).unfocus();  // Add this line
                            _handleLogin();
                          },
                          style: AppStyles.primaryButtonStyle,
                          child: _isLoading
                              ? const SpinKitThreeBounce(
                                  color: Colors.white,
                                  size: 24,
                                )
                              : const Text(
                                  'Login',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                        const SizedBox(height: 24),

                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            children: [
                              const Text(
                                'By signing in, you agree to our ',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _launchURL('https://www.noodev8.com/splitleague-terms-and-conditions/'),
                                child: const Text(
                                  'Terms of Service',
                                  style: TextStyle(
                                    color: AppStyles.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const Text(
                                ' and ',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _launchURL('https://www.noodev8.com/privacy-policy/'),
                                child: const Text(
                                  'Privacy Policy',
                                  style: TextStyle(
                                    color: AppStyles.primaryColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Don't have an account? ",
                              style: AppStyles.bodyStyle,
                            ),
                            GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const register.RegisterUserScreen(),
                                  ),
                                );
                              },
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  color: AppStyles.primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Launch URL in browser
  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ErrorHelper.showErrorToast('Could not launch $url');
    }
  }

  // Show forgot password dialog
  void _showForgotPasswordDialog() {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return _ForgotPasswordDialog(emailController: emailController);
      },
    );
  }
}

class _ForgotPasswordDialog extends StatefulWidget {
  final TextEditingController emailController;

  const _ForgotPasswordDialog({required this.emailController});

  @override
  _ForgotPasswordDialogState createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<_ForgotPasswordDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Forgot Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your email address and we\'ll send you a link to reset your password.'),
          const SizedBox(height: 16),
          TextField(
            controller: widget.emailController,
            decoration: AppStyles.inputDecoration('Email'),
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _handleForgotPassword,
          child: const Text('Send Reset Link'),
        ),
      ],
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = widget.emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ErrorHelper.showErrorToast('Please enter a valid email address');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await ForgotPasswordApi.forgotPassword(email);

      if (!mounted) return;

      if (response['return_code'] == 'SUCCESS') {
        Navigator.of(context).pop();
        ErrorHelper.showSuccessToast('Password reset email sent! Please check your inbox.');
      } else if (response['return_code'] == 'EMAIL_NOT_FOUND') {
        setState(() {
          _isLoading = false;
        });
        ErrorHelper.showErrorToast('No account found with this email address');
      } else {
        setState(() {
          _isLoading = false;
        });
        ErrorHelper.showErrorToast(ErrorHelper.getErrorMessage(response));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      ErrorHelper.showErrorToast('Failed to send password reset email. Please try again.');
    }
  }
}

