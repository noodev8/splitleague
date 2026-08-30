/*
Signing in.

The first thing anybody sees, so it says what the app is for before it asks for anything.
The old screen led with a translucent "SL" tile on a teal gradient and the line "Track
scores, anytime, anywhere" - which describes a category of app rather than this one, and
tells somebody who has just been sent a league link nothing about what they are signing
in to.

It now says it in the words the app uses everywhere else: fixtures, results, a table. One
sentence, then the form.

Everything is on the dark ground, with no white card floating on it. The card was there to
hold the form together against a gradient that had nothing to do with the form; without
the gradient it is not needed, and losing it lets the sign-in button be the only filled
thing on the screen.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/login_user_api.dart';
import '../api/forgot_password_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import '../widgets/sl_button.dart';
import '../widgets/sl_dark_field.dart';
import 'dashboard_screen.dart' as dashboard;
import 'developer_screen.dart';
import 'register_user_screen.dart' as register;

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

  // Variables for developer mode tap detection
  int _tapCount = 0;
  DateTime? _lastTapTime;

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
      Map<String, dynamic> response = await LoginUserApi.loginUser(
        email,
        password,
      );

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Save token and user data
        await AuthHelper.saveToken(response['token']);
        await AuthHelper.saveUserData(response['user']);

        // Navigate to dashboard with a clean slate
        if (mounted) {
          // Use pushAndRemoveUntil to clear the navigation stack
          // This ensures the dashboard is recreated from scratch
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const dashboard.DashboardScreen(),
            ),
            (route) => false, // Remove all previous routes
          );
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
        _errorMessage = 'Could not sign you in. Try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Dark ground, so the system clock and battery have to be asked for in white.
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppPalette.deep,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // The five taps that open the developer screen still live on the
                    // app's name, as they always have.
                    GestureDetector(
                      onTap: _handleTitleTap,
                      child: Text(
                        'Split League',
                        style: AppType.t(
                          AppType.display,
                          color: AppPalette.onDark,
                          size: 34,
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Set up a league, add the players, and keep the table as the '
                      'games get played.',
                      style: AppType.b(
                        AppType.body,
                        color: AppPalette.onDark.withValues(alpha: 0.75),
                      ),
                    ),

                    const SizedBox(height: 40),

                    SlDarkField(
                      controller: _emailController,
                      label: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter the email you signed up with';
                        }
                        if (!value.contains('@')) {
                          return 'That does not look like an email address';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    SlDarkField(
                      controller: _passwordController,
                      label: 'Password',
                      obscure: true,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        FocusScope.of(context).unfocus();
                        _handleLogin();
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Enter your password';
                        }
                        return null;
                      },
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordDialog,
                        style: TextButton.styleFrom(
                          foregroundColor: AppPalette.onDark.withValues(
                            alpha: 0.85,
                          ),
                        ),
                        child: Text(
                          'Forgotten your password?',
                          style: AppType.b(
                            AppType.meta,
                            color: AppPalette.onDark.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppPalette.clayTint,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: AppType.b(
                            AppType.body,
                            color: AppPalette.clay,
                            size: 14,
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    SlButton.primary(
                      label: _isLoading ? 'Signing in' : 'Sign in',
                      busy: _isLoading,
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                FocusScope.of(context).unfocus();
                                _handleLogin();
                              },
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'New here? ',
                          style: AppType.b(
                            AppType.body,
                            color: AppPalette.onDark.withValues(alpha: 0.75),
                            size: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const register.RegisterUserScreen(),
                              ),
                            );
                          },
                          child: Text(
                            'Create an account',
                            style: AppType.b(
                              AppType.action,
                              color: AppPalette.onDark,
                              size: 14,
                            ).copyWith(decoration: TextDecoration.underline),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 36),

                    // The legal links. Quiet, and at the bottom where they belong -
                    // they used to sit between the sign-in button and the register
                    // link, splitting the two things a person is actually choosing
                    // between.
                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          'By signing in you agree to the ',
                          style: _legalStyle(false),
                        ),
                        GestureDetector(
                          onTap:
                              () => _launchURL(
                                'https://www.noodev8.com/splitleague-terms-and-conditions/',
                              ),
                          child: Text('terms', style: _legalStyle(true)),
                        ),
                        Text(' and ', style: _legalStyle(false)),
                        GestureDetector(
                          onTap:
                              () => _launchURL(
                                'https://www.noodev8.com/privacy-policy/',
                              ),
                          child: Text(
                            'privacy policy',
                            style: _legalStyle(true),
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
    );
  }

  TextStyle _legalStyle(bool link) {
    return AppType.b(
      AppType.meta,
      color: AppPalette.onDark.withValues(alpha: link ? 0.9 : 0.6),
      size: 12,
    ).copyWith(decoration: link ? TextDecoration.underline : null);
  }

  // Launch URL in browser

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ErrorHelper.showErrorToast('Could not launch $url');
    }
  }

  // Handle title tap for developer mode
  void _handleTitleTap() {
    final now = DateTime.now();

    // Check if this is a consecutive tap (within 2 seconds)
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds < 2) {
      // Increment tap count
      _tapCount++;

      // Check if we've reached 5 taps
      if (_tapCount == 5) {
        // Reset tap count
        _tapCount = 0;

        // Navigate to developer screen
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const DeveloperScreen()),
        );
      }
    } else {
      // Reset tap count if too much time has passed
      _tapCount = 1;
    }

    // Update last tap time
    _lastTapTime = now;
  }

  // Handle guest access
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
    // Get the bottom inset (keyboard height)
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return AlertDialog(
      title: const Text('Reset your password'),
      content: Padding(
        // Add padding at the bottom to account for keyboard
        padding: EdgeInsets.only(bottom: bottomInset > 0 ? 8.0 : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'We will email you a link to set a new one.',
              style: AppType.b(AppType.body),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.emailController,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
              // Auto-focus the text field
              autofocus: true,
              // Handle submit action
              onSubmitted: (_) => _isLoading ? null : _handleForgotPassword(),
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              _isLoading
                  ? null
                  : () {
                    Navigator.of(context).pop();
                  },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: _isLoading ? null : _handleForgotPassword,
          child: const Text('Send the link'),
        ),
      ],
    );
  }

  Future<void> _handleForgotPassword() async {
    final email = widget.emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ErrorHelper.showErrorToast('Enter a valid email address');
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
        ErrorHelper.showSuccessToast('Check your inbox for the reset link');
      } else if (response['return_code'] == 'EMAIL_NOT_FOUND') {
        setState(() {
          _isLoading = false;
        });
        ErrorHelper.showErrorToast('No account uses that email address');
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
      ErrorHelper.showErrorToast('Could not send the reset email. Try again.');
    }
  }
}
