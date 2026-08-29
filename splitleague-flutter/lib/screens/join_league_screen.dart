/*
Show the join league screen allowing users to join an existing league
This screen allows users to enter a 4-digit code to join a league
Once joined, it returns to the dashboard screen
*/

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/join_league_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../widgets/pin_input.dart';
import 'login_user_screen.dart';
import 'register_user_screen.dart';

class JoinLeagueScreen extends StatefulWidget {
  final Function? onLeagueJoined;

  // Code carried in from a shared league link, pre-filled into the boxes
  //
  // Null when the person opened this screen themselves and is typing a code they were told.
  final String? initialCode;

  const JoinLeagueScreen({
    super.key,
    this.onLeagueJoined,
    this.initialCode,
  });

  @override
  State<JoinLeagueScreen> createState() => _JoinLeagueScreenState();
}

class _JoinLeagueScreenState extends State<JoinLeagueScreen> {
  // Loading state
  bool _isLoading = false;

  // Error message
  String? _errorMessage;

  // PIN code
  String _pinCode = '';

  // Handle join league button press
  Future<void> _handleJoinLeague() async {
    // Validate PIN code
    if (_pinCode.length != 4) {
      setState(() {
        _errorMessage = 'Please enter a valid 4-digit code';
      });
      return;
    }

    // Check if user is in guest mode
    final isGuest = await AuthHelper.getUserData().then((userData) =>
      userData == null || userData['nickname'] == 'Guest');

    if (isGuest) {
      // Show registration dialog for guest users
      _showGuestRegistrationDialog();
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call join league API
      Map<String, dynamic> response = await JoinLeagueApi.joinLeague(_pinCode);

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Stop loading
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });

        // Call the callback if provided
        if (widget.onLeagueJoined != null) {
          widget.onLeagueJoined!();
        }

        // Show success toast
        ErrorHelper.showSuccessToast(response['message'] ?? 'Successfully joined the league');

        // Navigate back immediately
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Show error message
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'];
        });
      }
    } catch (e) {
      // Show error message
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  // Show guest registration dialog
  void _showGuestRegistrationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registration Required'),
          content: const Text(
            'To join a league, you need to register an account or sign in. '
            'This allows you to track scores and participate in leagues with friends.\n\n'
            'Registration is free and only takes a minute.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to login screen with a clean slate
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginUserScreen()),
                  (route) => false, // Remove all previous routes
                );
              },
              child: const Text('Sign In'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to register screen with a clean slate
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const RegisterUserScreen()),
                  (route) => false, // Remove all previous routes
                );
              },
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  // Handle PIN code completion
  //
  // This only records the code and closes the keyboard. It deliberately does NOT join.
  //
  // It used to fire the join itself the moment a 4th digit arrived, which tied the act of
  // joining to the code being exactly 4 characters long. The code is going to become a longer
  // share slug, and an invite link now opens this screen with the code already filled in - so
  // joining has to be a deliberate press, not a side effect of finishing typing.
  void _onPinCompleted(String pin) {
    setState(() {
      _pinCode = pin;
      _errorMessage = null;
    });

    // Close the keyboard so the Join button is visible
    if (pin.length == 4) {
      FocusScope.of(context).unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the bottom inset (keyboard height)
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      // This ensures the body resizes when the keyboard appears
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005F8A),
        elevation: 0,
        title: const Text('Join League'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF005F8A), // Top color from logo gradient
              Color(0xFF00B3A4), // Bottom color from logo gradient
            ],
          ),
        ),
        child: SafeArea(
          bottom: false, // Allow content to extend to the bottom edge
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              // Add padding at the bottom to ensure content is visible above keyboard
              padding: EdgeInsets.fromLTRB(
                16.0,
                24.0,
                16.0,
                bottomInset > 0 ? bottomInset + 20 : 24.0
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Card for join league content
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 32,
                    ),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Icon in a circle
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.group_add,
                                size: 40,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            const Text(
                              'Join a League',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            // Description
                            const Text(
                              'Enter the 4-digit code provided by the league creator to join.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 40),

                            // PIN input
                            PinInput(
                              onCompleted: _onPinCompleted,
                              pinLength: 4,

                              // Do not steal focus when the code is already filled in from a
                              // link - popping the keyboard up over a completed form is noise.
                              autoFocus: widget.initialCode == null,
                              initialValue: widget.initialCode,
                            ),
                            const SizedBox(height: 32),

                            // Join button
                            //
                            // Disabled until there is a complete code, and while a join is in
                            // flight, so it cannot be pressed twice.
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: (_pinCode.length == 4 && !_isLoading)
                                    ? _handleJoinLeague
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF005F8A),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text(
                                  'Join League',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Error message
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_errorMessage != null) const SizedBox(height: 24),

                            // Loading indicator
                            if (_isLoading)
                              Container(
                                margin: const EdgeInsets.only(top: 24),
                                child: const SpinKitThreeBounce(
                                  color: Colors.blue,
                                  size: 24,
                                ),
                              ),
                          ],
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


