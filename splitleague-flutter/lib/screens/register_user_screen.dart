/*
Creating an account.

Signing up is pure cost to the person doing it - nobody wants an account, they want a
league - so the job of this screen is to ask for as little as possible and to say why it
is asking.

Two fields came off it.

  Confirm password is gone, replaced by a reveal button on the password itself. It was
  there to catch a typo, and showing the password catches the same typo without a second
  field to fill in. A mistyped password is also recoverable from the sign-in screen,
  which a mistyped email is not - so the email is the one that still gets checked.

  Display name is still sent, because it is what appears in every league, but it now
  fills itself in from the first name as it is typed. Anybody who wants something else
  types over it and it stops following. Two name fields with no explanation was the most
  confusing thing on the old screen: nobody could tell which one other people would see.

Everything sits directly on the dark ground, matching the sign-in screen, rather than in
a white card floating on a gradient.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/register_user_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import '../widgets/sl_button.dart';
import '../widgets/sl_dark_field.dart';
import 'dashboard_screen.dart' as dashboard;

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  State<RegisterUserScreen> createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Loading state
  bool _isLoading = false;

  // Error message
  String? _errorMessage;

  // Whether the password is being shown. Replaces the confirm-password field.
  bool _showPassword = false;

  // True until the person edits the display name themselves. While it is true the
  // display name follows the first word of their real name; the moment they type in
  // it, it stops - because from then on it is their choice, not our guess.
  bool _displayNameFollowsName = true;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_syncDisplayName);
  }

  // Keep the display name in step with the first name, until it is edited.
  void _syncDisplayName() {
    if (!_displayNameFollowsName) return;

    final String first = _nameController.text.trim().split(' ').first;

    if (_nicknameController.text != first) {
      _nicknameController.value = TextEditingValue(
        text: first,
        selection: TextSelection.collapsed(offset: first.length),
      );
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_syncDisplayName);
    // Clean up controllers
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Handle register button press
  Future<void> _handleRegister() async {
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
      String name = _nameController.text.trim();
      String nickname = _nicknameController.text.trim();
      String email = _emailController.text.trim();
      String password = _passwordController.text;

      // Call register API
      Map<String, dynamic> response = await RegisterUserApi.registerUser(
        name,
        nickname,
        email,
        password,
      );

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Take the new user straight into the app
        //
        // Registration has always returned a token, but the app used to ignore it, show a
        // "check your email to verify your account" dialog and drop the user back at the
        // login screen. That step cost us 30% of everyone who signed up. Accounts are
        // created already verified now, so we save the token and go, exactly as login does.
        await AuthHelper.saveToken(response['token']);
        await AuthHelper.saveUserData(response['user']);

        // Navigate to dashboard with a clean slate
        if (mounted) {
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
        _errorMessage = 'Could not create your account. Try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppPalette.deep,
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: AppPalette.onDark,
          elevation: 0,
          title: const SizedBox.shrink(),
        ),
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create your account',
                      style: AppType.t(
                        AppType.display,
                        color: AppPalette.onDark,
                        size: 30,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'So your leagues follow you, and the people you play can find you.',
                      style: AppType.b(
                        AppType.body,
                        color: AppPalette.onDark.withValues(alpha: 0.75),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SlDarkField(
                      controller: _nameController,
                      label: 'Your name',
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Tell us your name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    SlDarkField(
                      controller: _nicknameController,
                      label: 'Name in leagues',
                      helper: 'What the other players see',
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      // Typing here means they have chosen one, so stop following
                      // the name field.
                      onChanged: (_) => _displayNameFollowsName = false,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Pick a name for the other players to see';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 14),

                    SlDarkField(
                      controller: _emailController,
                      label: 'Email',
                      helper:
                          'Used to get you back in if you forget your password',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your email address';
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
                      obscure: !_showPassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) {
                        FocusScope.of(context).unfocus();
                        _handleRegister();
                      },
                      // The reveal, which is what replaced the confirm field.
                      suffix: IconButton(
                        icon: Icon(
                          _showPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          size: 20,
                          color: AppPalette.onDark.withValues(alpha: 0.7),
                        ),
                        tooltip:
                            _showPassword ? 'Hide password' : 'Show password',
                        onPressed:
                            () =>
                                setState(() => _showPassword = !_showPassword),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Choose a password';
                        }
                        // The same minimum the app has always asked for. The
                        // reveal button is what guards against a typo now; this is
                        // not the place to quietly tighten the password policy.
                        if (value.length < 4) {
                          return 'Use at least 4 characters';
                        }
                        return null;
                      },
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
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

                    const SizedBox(height: 28),

                    SlButton.primary(
                      label:
                          _isLoading
                              ? 'Creating your account'
                              : 'Create account',
                      busy: _isLoading,
                      onPressed:
                          _isLoading
                              ? null
                              : () {
                                FocusScope.of(context).unfocus();
                                _handleRegister();
                              },
                    ),

                    const SizedBox(height: 12),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have one? ',
                          style: AppType.b(
                            AppType.body,
                            color: AppPalette.onDark.withValues(alpha: 0.75),
                            size: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Text(
                            'Sign in',
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

                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          'By registering you agree to the ',
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
}
