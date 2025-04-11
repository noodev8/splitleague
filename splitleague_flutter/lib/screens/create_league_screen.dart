/*
Show the create league screen allowing users to create a new league
This screen allows users to enter league details and create a new league
Once created, it returns to the dashboard screen
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/create_league_api.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';
import 'dashboard_screen.dart';

class CreateLeagueScreen extends StatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  State<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _nameController = TextEditingController();
  final _pointsForWinController = TextEditingController(text: '3');
  final _pointsForDrawController = TextEditingController(text: '1');
  final _pointsForWinMarginController = TextEditingController(text: '0');
  final _pointsForCloseLossController = TextEditingController(text: '0');
  final _winMarginThresholdController = TextEditingController(text: '15');
  final _playEachOtherController = TextEditingController(text: '2');

  // Win Only points controller (separate to maintain different default)
  final _winOnlyPointsController = TextEditingController(text: '1');

  // Win type selection
  String _selectedWinType = 'PTS'; // Default to Points-based scoring

  // Loading state
  bool _isLoading = false;

  // Error message
  String? _errorMessage;

  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _pointsForWinController.dispose();
    _pointsForDrawController.dispose();
    _pointsForWinMarginController.dispose();
    _pointsForCloseLossController.dispose();
    _winMarginThresholdController.dispose();
    _playEachOtherController.dispose();
    _winOnlyPointsController.dispose();
    super.dispose();
  }

  // Show dialog with league code
  void _showLeagueCodeDialog(String leagueCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('League Created!'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Your league has been created successfully. Share this code with others so they can join:',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                decoration: BoxDecoration(
                  color: AppStyles.primaryColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppStyles.primaryColor.withAlpha(100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      leagueCode,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                        color: AppStyles.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.copy, color: AppStyles.primaryColor),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: leagueCode)).then((_) {
                          ErrorHelper.showSuccessToast('Code copied to clipboard');
                        });
                      },
                      tooltip: 'Copy code',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Players can join your league by entering this code in the Join League screen.',
                style: TextStyle(fontSize: 14, color: AppStyles.secondaryTextColor),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Continue to Dashboard'),
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const DashboardScreen()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  // Handle create league button press
  Future<void> _handleCreateLeague() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get form values - remove the ?? defaults since we want to send actual form values
      String name = _nameController.text.trim();
      int pointsForWin = _selectedWinType == 'WIN'
          ? int.parse(_winOnlyPointsController.text)
          : int.parse(_pointsForWinController.text);
      int pointsForDraw = int.parse(_pointsForDrawController.text);
      int pointsForWinMargin = int.parse(_pointsForWinMarginController.text);
      int pointsForCloseLoss = int.parse(_pointsForCloseLossController.text);
      int winMarginThreshold = int.parse(_winMarginThresholdController.text);
      int playEachOther = int.parse(_playEachOtherController.text);

      // Call create league API with required values
      Map<String, dynamic> response = await CreateLeagueApi.createLeague(
        name: name,
        winType: _selectedWinType,
        pointsForWin: pointsForWin,
        pointsForDraw: pointsForDraw,
        pointsForWinMargin: pointsForWinMargin,
        pointsForCloseLoss: pointsForCloseLoss,
        winMarginThreshold: winMarginThreshold,
        playEachOther: playEachOther,
      );

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Extract league data from response
        final leagueData = response['league'] as Map<String, dynamic>;
        final leagueCode = leagueData['public_code'] as String?;

        // Show success message with code
        ErrorHelper.showSuccessToast('League "$name" created successfully!');

        // Show dialog with league code
        if (mounted && leagueCode != null) {
          _showLeagueCodeDialog(leagueCode);
        } else {
          // Navigate back to dashboard if no code available
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const DashboardScreen()),
            );
          }
        }
      } else {
        // Show error message
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to create league';
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
        title: const Text('Create League'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // League name field
                TextFormField(
                  controller: _nameController,
                  decoration: AppStyles.inputDecoration(
                    'League Name',
                    prefixIcon: const Icon(Icons.sports_soccer),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a league name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Win Type Selection
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWinType = 'PTS';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _selectedWinType == 'PTS'
                              ? AppStyles.selectedCardDecoration
                              : AppStyles.selectionCardDecoration,
                          child: Column(
                            children: [
                              Icon(
                                Icons.sports_score,
                                size: 32,
                                color: _selectedWinType == 'PTS' ? AppStyles.primaryColor : AppStyles.secondaryTextColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Points',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedWinType == 'PTS' ? AppStyles.primaryColor : AppStyles.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedWinType = 'WIN';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: _selectedWinType == 'WIN'
                              ? AppStyles.selectedCardDecoration
                              : AppStyles.selectionCardDecoration,
                          child: Column(
                            children: [
                              Icon(
                                Icons.emoji_events,
                                size: 32,
                                color: _selectedWinType == 'WIN' ? AppStyles.primaryColor : AppStyles.secondaryTextColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Win Only',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedWinType == 'WIN' ? AppStyles.primaryColor : AppStyles.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedWinType = 'WDL';
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _selectedWinType == 'WDL'
                        ? AppStyles.selectedCardDecoration
                        : AppStyles.selectionCardDecoration,
                    child: Row(
                      children: [
                        Icon(
                          Icons.sports_soccer,
                          size: 32,
                          color: _selectedWinType == 'WDL' ? AppStyles.primaryColor : AppStyles.secondaryTextColor,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Win/Draw/Loss',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _selectedWinType == 'WDL' ? AppStyles.primaryColor : AppStyles.textColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Points section
                const Text(
                  'Points System',
                  style: AppStyles.subheadingStyle,
                ),
                const SizedBox(height: 16),

                // Points for win field
                TextFormField(
                  controller: _selectedWinType == 'WIN' ? _winOnlyPointsController : _pointsForWinController,
                  decoration: AppStyles.inputDecoration('Points for Win'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Required';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Enter a number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Points for Draw - visible for PTS and WDL types
                Visibility(
                  visible: _selectedWinType != 'WIN',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _pointsForDrawController,
                        decoration: AppStyles.inputDecoration('Points for Draw'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter a number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Bonus points section - only visible for PTS type
                Visibility(
                  visible: _selectedWinType == 'PTS',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Win Margin Bonus
                      TextFormField(
                        controller: _pointsForWinMarginController,
                        decoration: AppStyles.inputDecoration('Win Margin Bonus'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter a number';
                          }
                          return null;
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 12, top: 4),
                        child: Text(
                          'Beat your opponent by the win threshold amount or more, to get the bonus',
                          style: TextStyle(fontSize: 12, color: AppStyles.secondaryTextColor),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Lose within margin Bonus
                      TextFormField(
                        controller: _pointsForCloseLossController,
                        decoration: AppStyles.inputDecoration('Lose within margin Bonus'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Required';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Enter a number';
                          }
                          return null;
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 12, top: 4),
                        child: Text(
                          'If you lose but manage to stay under the win margin threshold, you get the bonus',
                          style: TextStyle(fontSize: 12, color: AppStyles.secondaryTextColor),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Win margin threshold field
                      TextFormField(
                        controller: _winMarginThresholdController,
                        decoration: AppStyles.inputDecoration('Win Margin Threshold'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a threshold value';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 12, top: 4),
                        child: Text(
                          'The points at which any win bonuses are determined at',
                          style: TextStyle(fontSize: 12, color: AppStyles.secondaryTextColor),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),

                // Play each other field
                TextFormField(
                  controller: _playEachOtherController,
                  decoration: AppStyles.inputDecoration(
                    'Play Each Other',
                    hint: 'Number of times each player plays each other',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a value';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    if (int.tryParse(value)! < 1) {
                      return 'Value must be at least 1';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

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

                // Create league button
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleCreateLeague,
                  style: AppStyles.primaryButtonStyle,
                  child: _isLoading
                      ? const SpinKitThreeBounce(
                          color: Colors.white,
                          size: 24,
                        )
                      : const Text(
                          'Create League',
                          style: TextStyle(fontSize: 16),
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
