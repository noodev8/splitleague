/*
Screen for updating fixture scores
Allows users to enter and submit scores for a fixture
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/update_fixture_score_api.dart';
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
  
  // Loading state
  bool _isSubmitting = false;
  
  // Error message
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    
    // Pre-fill scores if they exist
    if (widget.fixture['played'] == true) {
      _player1ScoreController.text = widget.fixture['player_1_score']?.toString() ?? '';
      _player2ScoreController.text = widget.fixture['player_2_score']?.toString() ?? '';
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
    
    // Get scores from controllers
    final player1Score = int.parse(_player1ScoreController.text);
    final player2Score = int.parse(_player2ScoreController.text);
    
    // Set loading state
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    
    try {
      // Call API to update fixture score
      final response = await UpdateFixtureScoreApi.updateFixtureScore(
        widget.fixture['id'],
        player1Score,
        player2Score,
      );
      
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
                // Title
                const Text(
                  'Enter Match Result',
                  style: AppStyles.headingStyle,
                ),
                const SizedBox(height: 24),
                
                // Players and score inputs
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Player 1
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Player 1 name
                          Text(
                            player1Name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          
                          // Player 1 score input
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              controller: _player1ScoreController,
                              decoration: const InputDecoration(
                                labelText: 'Score',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
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
                    ),
                    
                    // VS
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: AppStyles.secondaryTextColor,
                        ),
                      ),
                    ),
                    
                    // Player 2
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Player 2 name
                          Text(
                            player2Name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          
                          // Player 2 score input
                          SizedBox(
                            width: 80,
                            child: TextFormField(
                              controller: _player2ScoreController,
                              decoration: const InputDecoration(
                                labelText: 'Score',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
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
                    ),
                  ],
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
                
                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    style: AppStyles.primaryButtonStyle,
                    child: _isSubmitting
                        ? const SpinKitThreeBounce(
                            color: Colors.white,
                            size: 24,
                          )
                        : const Text('Submit Score'),
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
