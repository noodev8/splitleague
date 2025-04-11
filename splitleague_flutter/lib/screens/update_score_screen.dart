/*
Screen for updating fixture scores
Allows users to enter and submit scores for a fixture
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/update_fixture_score_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';

class UpdateScoreScreen extends StatefulWidget {
  final Map<String, dynamic> fixture;
  final Function? onScoreUpdated;

  const UpdateScoreScreen({
    super.key,
    required this.fixture,
    this.onScoreUpdated,
  });

  @override
  State<UpdateScoreScreen> createState() => _UpdateScoreScreenState();
}

class _UpdateScoreScreenState extends State<UpdateScoreScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _player1ScoreController = TextEditingController();
  final _player2ScoreController = TextEditingController();

  // Result selection for WIN/WDL win types
  String? _selectedResult;

  // Loading state
  bool _isSubmitting = false;

  // Error message
  String? _errorMessage;

  // Win type from the league
  String? _winType;

  // User data
  Map<String, dynamic>? _userData;

  // Authorization flag
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();

    // Get the win type from the fixture
    _winType = widget.fixture['win_type'] ?? 'PTS';

    // Pre-fill scores if they exist
    if (widget.fixture['played'] == true) {
      if (_winType == 'PTS') {
        _player1ScoreController.text = widget.fixture['player_1_score']?.toString() ?? '';
        _player2ScoreController.text = widget.fixture['player_2_score']?.toString() ?? '';
      } else {
        // For WIN or WDL types, determine the result from the scores
        final player1Score = widget.fixture['player_1_score'] ?? 0;
        final player2Score = widget.fixture['player_2_score'] ?? 0;

        if (player1Score > player2Score) {
          _selectedResult = 'WIN_1';
        } else if (player2Score > player1Score) {
          _selectedResult = 'WIN_2';
        } else if (player1Score == 1 && player2Score == 1) {
          _selectedResult = 'DRAW';
        }
      }
    }

    // Load user data and check authorization
    _loadUserDataAndCheckAuth();
  }

  // Load user data and check if user is authorized to update this fixture
  Future<void> _loadUserDataAndCheckAuth() async {
    try {
      // Load user data from secure storage
      _userData = await AuthHelper.getUserData();

      if (_userData != null) {
        final int userId = _userData!['id'];
        final int player1Id = widget.fixture['player_1_id'];
        final int player2Id = widget.fixture['player_2_id'];
        final bool isCreator = widget.fixture['is_creator'] ?? false;

        // User is authorized if they are the league creator or one of the players
        _isAuthorized = isCreator || userId == player1Id || userId == player2Id;
      }

      // Update UI
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Handle error silently
      // This is not critical functionality
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    _player1ScoreController.dispose();
    _player2ScoreController.dispose();
    super.dispose();
  }

  // Handle form submission
  Future<void> _handleSubmit() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Set loading state
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      Map<String, dynamic> response;

      // Call appropriate API based on win type
      if (_winType == 'PTS') {
        // For points-based leagues, send actual scores
        final player1Score = int.parse(_player1ScoreController.text);
        final player2Score = int.parse(_player2ScoreController.text);

        response = await UpdateFixtureScoreApi.updateFixtureScore(
          widget.fixture['id'],
          player1Score,
          player2Score,
        );
      } else {
        // For WIN or WDL leagues, send the result
        if (_selectedResult == null) {
          setState(() {
            _isSubmitting = false;
            _errorMessage = 'Please select a result';
          });
          return;
        }

        response = await UpdateFixtureScoreApi.updateFixtureResult(
          widget.fixture['id'],
          _selectedResult!,
        );
      }

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Show success message
        ErrorHelper.showSuccessToast(response['message'] ?? 'Score updated successfully');

        // Call onScoreUpdated callback if provided
        if (widget.onScoreUpdated != null) {
          widget.onScoreUpdated!();
        }

        // Pop screen
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Show error message
        setState(() {
          _isSubmitting = false;
          _errorMessage = response['message'];
        });
      }
    } catch (e) {
      // Show error message
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get player names
    final player1Name = widget.fixture['player_1_nickname']?.isNotEmpty == true
        ? widget.fixture['player_1_nickname']
        : widget.fixture['player_1_name'];

    final player2Name = widget.fixture['player_2_nickname']?.isNotEmpty == true
        ? widget.fixture['player_2_nickname']
        : widget.fixture['player_2_name'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Score'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reduced space at the top
                const SizedBox(height: 8),

                // Different UI based on win type
                if (_winType == 'PTS')
                  // Points-based score entry - modernized UI
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        // Player names in a row
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppStyles.primaryColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  player1Name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppStyles.primaryColor,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                decoration: BoxDecoration(
                                  color: AppStyles.accentColor.withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  player2Name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: AppStyles.accentColor,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Score inputs in a row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Player 1 score
                            Column(
                              children: [
                                const SizedBox(height: 4),
                                Container(
                                  width: 100,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withAlpha(40),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
                                    controller: _player1ScoreController,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),

                            // VS indicator
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Text(
                                  'VS',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppStyles.secondaryTextColor,
                                  ),
                                ),
                              ),
                            ),

                            // Player 2 score
                            Column(
                              children: [
                                const SizedBox(height: 4),
                                Container(
                                  width: 100,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withAlpha(40),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: TextFormField(
                                    controller: _player2ScoreController,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                    ),
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(3),
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),

                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppStyles.errorColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppStyles.errorColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppStyles.errorColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (_errorMessage != null) const SizedBox(height: 24),

                // Win/Draw/Loss selection for WIN or WDL types
                if (_winType == 'WIN' || _winType == 'WDL')
                  Column(
                    children: [

                      // Result selection cards - Winners in a row
                      Row(
                        children: [
                          // Player 1 wins
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedResult = 'WIN_1';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: _selectedResult == 'WIN_1'
                                    ? AppStyles.selectedCardDecoration
                                    : AppStyles.selectionCardDecoration,
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      size: 32,
                                      color: _selectedResult == 'WIN_1' ? AppStyles.primaryColor : AppStyles.secondaryTextColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Winner',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _selectedResult == 'WIN_1' ? AppStyles.primaryColor : AppStyles.textColor,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      player1Name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _selectedResult == 'WIN_1' ? AppStyles.primaryColor : AppStyles.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),

                          // Player 2 wins
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedResult = 'WIN_2';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: _selectedResult == 'WIN_2'
                                    ? AppStyles.selectedCardDecoration
                                    : AppStyles.selectionCardDecoration,
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.emoji_events,
                                      size: 32,
                                      color: _selectedResult == 'WIN_2' ? AppStyles.primaryColor : AppStyles.secondaryTextColor,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Winner',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _selectedResult == 'WIN_2' ? AppStyles.primaryColor : AppStyles.textColor,
                                      ),
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      player2Name,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _selectedResult == 'WIN_2' ? AppStyles.primaryColor : AppStyles.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Draw option below (only for WDL type)
                      if (_winType == 'WDL') ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedResult = 'DRAW';
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: _selectedResult == 'DRAW'
                                ? AppStyles.selectedCardDecoration
                                : AppStyles.selectionCardDecoration,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.handshake,
                                  size: 32,
                                  color: _selectedResult == 'DRAW' ? AppStyles.primaryColor : AppStyles.secondaryTextColor,
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Draw',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _selectedResult == 'DRAW' ? AppStyles.primaryColor : AppStyles.textColor,
                                      ),
                                    ),
                                    // Removed 'Equal Score' text as requested
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),

                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting || !_isAuthorized ? null : _handleSubmit,
                    style: AppStyles.primaryButtonStyle,
                    child: _isSubmitting
                        ? const SpinKitThreeBounce(
                            color: Colors.white,
                            size: 24,
                          )
                        : Text(_winType == 'PTS' ? 'Submit Score' : 'Submit Result'),
                  ),
                ),

                // Note
                const SizedBox(height: 16),
                const Text(
                  'Note: Scores can only be updated by the league organiser or the players involved in the match.',
                  style: TextStyle(
                    color: AppStyles.secondaryTextColor,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
