/*
Screen for updating fixture scores
Allows users to enter and submit scores for a fixture
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/update_fixture_score_api.dart';
import '../api/void_fixture_api.dart';
import '../helpers/auth_helper.dart';
//import '../helpers/error_helper.dart';
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

  // Loading states
  bool _isSubmitting = false;
  bool _isVoiding = false;

  // Error message
  String? _errorMessage;

  // Win type from the league
  String? _winType;

  // User data
  Map<String, dynamic>? _userData;

  // Authorization flags
  bool _isAuthorized = false;
  bool _isCreator = false;

  @override
  void initState() {
    super.initState();
    // Initialize win type from fixture data
    _winType = widget.fixture['win_type'];
    
    // Initialize scores if they exist
    if (widget.fixture['played'] == true) {
      if (_winType == 'PTS') {
        _player1ScoreController.text = widget.fixture['player_1_score']?.toString() ?? '';
        _player2ScoreController.text = widget.fixture['player_2_score']?.toString() ?? '';
      } else {
        // For WIN/WDL types, set the selected result based on scores
        final p1Score = widget.fixture['player_1_score'];
        final p2Score = widget.fixture['player_2_score'];
        
        if (p1Score == 1 && p2Score == 0) {
          _selectedResult = 'WIN_1';
        } else if (p1Score == 0 && p2Score == 1) {
          _selectedResult = 'WIN_2';
        } else if (p1Score == 1 && p2Score == 1) {
          _selectedResult = 'DRAW';
        }
      }
    }
    
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    _userData = await AuthHelper.getUserData();

    if (mounted) {
      setState(() {
        if (_userData != null) {
          final int userId = _userData!['id'];
          final int player1Id = widget.fixture['player_1_id'];
          final int player2Id = widget.fixture['player_2_id'];
          final bool isCreator = widget.fixture['is_creator'] ?? false;

          // User is authorized if they are the league creator or one of the players
          _isAuthorized = isCreator || userId == player1Id || userId == player2Id;
          
          // Set creator flag (only league creators can void fixtures)
          _isCreator = isCreator;
        }
      });
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
        // Call onScoreUpdated callback if provided
        if (widget.onScoreUpdated != null) {
          widget.onScoreUpdated!();
        }

        // Pop screen with result=true to indicate success
        if (mounted) {
          Navigator.of(context).pop(true);
        }

        // Remove the success toast since we're already showing feedback
        // ErrorHelper.showSuccessToast(response['message'] ?? 'Score updated successfully');
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

  // Handle void fixture
  Future<void> _handleVoidFixture() async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Void Fixture'),
        content: const Text(
          'Are you sure you want to void this fixture? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Void Fixture'),
          ),
        ],
      ),
    );

    // If user cancels, do nothing
    if (confirm != true) {
      return;
    }

    // Set loading state
    setState(() {
      _isVoiding = true;
      _errorMessage = null;
    });

    try {
      // Call void fixture API
      final response = await VoidFixtureApi.voidFixture(widget.fixture['id']);

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Call onScoreUpdated callback if provided (to refresh fixtures list)
        if (widget.onScoreUpdated != null) {
          widget.onScoreUpdated!();
        }

        // Pop screen with result=true to indicate success
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        // Show error message
        setState(() {
          _isVoiding = false;
          _errorMessage = response['message'];
        });
      }
    } catch (e) {
      // Show error message
      setState(() {
        _isVoiding = false;
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
        title: const Text('Update Score', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
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
        ),
      ),
      body: Container(
        color: AppStyles.backgroundColor,
        child: SafeArea(
          bottom: false,
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(13),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
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
                                    width: 90,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppStyles.primaryColor.withAlpha(100), width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withAlpha(30),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 1),
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
                                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                                    width: 90,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppStyles.primaryColor.withAlpha(100), width: 1),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.grey.withAlpha(30),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 1),
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
                                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: AppStyles.cardDecoration,
                      child: Column(
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
                    ),

                  const SizedBox(height: 24),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting || _isVoiding || !_isAuthorized ? null : _handleSubmit,
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

                  // Void fixture button (only for league creators)
                  if (_isCreator) ...[
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: _isSubmitting || _isVoiding ? null : _handleVoidFixture,
                        icon: Icon(
                          Icons.remove_circle_outline,
                          size: 16,
                          color: Colors.grey[700],
                        ),
                        label: Text(
                          'Void Fixture',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

