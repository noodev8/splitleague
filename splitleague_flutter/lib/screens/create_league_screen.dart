/*
Show the create league screen allowing users to create a new league
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/create_league_api.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';
import 'fixtures_screen.dart';

class CreateLeagueScreen extends StatefulWidget {
  const CreateLeagueScreen({super.key});

  @override
  State<CreateLeagueScreen> createState() => _CreateLeagueScreenState();
}

class _CreateLeagueScreenState extends State<CreateLeagueScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Text controllers
  final _leagueNameController = TextEditingController();

  // Win type selection
  String _selectedWinType = 'WIN'; // Default to WIN

  // Points settings
  final _winPointsController = TextEditingController(text: '1');
  final _drawPointsController = TextEditingController(text: '0');
  final _losePointsController = TextEditingController(text: '0');
  final _winMarginBonusController = TextEditingController(text: '0');
  final _loseMarginBonusController = TextEditingController(text: '0');
  final _winMarginThresholdController = TextEditingController(text: '0');

  // Loading state
  bool _isLoading = false;

  // Error message
  String? _errorMessage;

  // League code after creation
  String? _leagueCode;

  @override
  void dispose() {
    // Clean up controllers
    _leagueNameController.dispose();
    _winPointsController.dispose();
    _drawPointsController.dispose();
    _losePointsController.dispose();
    _winMarginBonusController.dispose();
    _loseMarginBonusController.dispose();
    _winMarginThresholdController.dispose();
    super.dispose();
  }

  // Handle create league button press
  Future<void> _handleCreateLeague() async {
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
      String leagueName = _leagueNameController.text.trim();
      String winType = _selectedWinType;

      // Get points settings
      int winPoints = int.tryParse(_winPointsController.text) ?? 0;
      int drawPoints = int.tryParse(_drawPointsController.text) ?? 0;
      // Note: losePoints is not used in the API but we keep it for UI consistency
      int winMarginBonus = int.tryParse(_winMarginBonusController.text) ?? 0;
      int loseMarginBonus = int.tryParse(_loseMarginBonusController.text) ?? 0;
      int winMarginThreshold = int.tryParse(_winMarginThresholdController.text) ?? 0;

      // Call create league API
      Map<String, dynamic> response = await CreateLeagueApi.createLeague(
        name: leagueName,
        winType: winType,
        pointsForWin: winPoints,
        pointsForDraw: drawPoints,
        pointsForWinMargin: winMarginBonus,
        pointsForCloseLoss: loseMarginBonus,
        winMarginThreshold: winMarginThreshold,
      );

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Show success message
        ErrorHelper.showSuccessToast('League created successfully!');

        // Set league code
        setState(() {
          _leagueCode = response['league_code'];
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

  // Copy league code to clipboard
  void _copyLeagueCode() {
    if (_leagueCode != null) {
      Clipboard.setData(ClipboardData(text: _leagueCode!));
      ErrorHelper.showSuccessToast('League code copied to clipboard');
    }
  }

  // View league details
  void _viewLeague() {
    if (_leagueCode != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FixturesScreen(
            league: {
              'league_id': int.tryParse(_leagueCode!) ?? 0,
              'name': _leagueNameController.text.trim(),
              'is_creator': true,
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create League'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade100,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // League name section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'League Details',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _leagueNameController,
                            decoration: AppStyles.inputDecoration(
                              'League Name',
                              prefixIcon: const Icon(Icons.sports_soccer),
                            ).copyWith(
                              counterText: '${_leagueNameController.text.length}/30',
                              counterStyle: TextStyle(
                                color: _leagueNameController.text.length > 30 ? Colors.red : Colors.grey,
                                fontWeight: _leagueNameController.text.length > 30 ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            maxLength: 30,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            onChanged: (value) {
                              setState(() {}); // Refresh to update counter
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a league name';
                              }
                              if (value.length > 30) {
                                return 'League name must be 30 characters or less';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Win type section
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Scoring System',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Win type selection
                          const Text(
                            'Select a scoring system:',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Scoring system cards
                          Row(
                            children: [
                              // WIN option
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedWinType = 'WIN';
                                      // Set default values for WIN
                                      _winPointsController.text = '1';
                                      _drawPointsController.text = '0';
                                      _losePointsController.text = '0';
                                    });
                                  },
                                  child: Card(
                                    elevation: _selectedWinType == 'WIN' ? 4 : 1,
                                    color: _selectedWinType == 'WIN' ? Colors.blue.shade50 : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: _selectedWinType == 'WIN' ? Colors.blue : Colors.grey.shade300,
                                        width: _selectedWinType == 'WIN' ? 2 : 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.emoji_events,
                                            size: 32,
                                            color: _selectedWinType == 'WIN' ? Colors.blue : Colors.grey.shade600,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Win Only',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _selectedWinType == 'WIN' ? Colors.blue : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '1 point per win',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // WDL option
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedWinType = 'WDL';
                                      // Set default values for WDL
                                      _winPointsController.text = '3';
                                      _drawPointsController.text = '1';
                                      _losePointsController.text = '0';
                                    });
                                  },
                                  child: Card(
                                    elevation: _selectedWinType == 'WDL' ? 4 : 1,
                                    color: _selectedWinType == 'WDL' ? Colors.blue.shade50 : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: _selectedWinType == 'WDL' ? Colors.blue : Colors.grey.shade300,
                                        width: _selectedWinType == 'WDL' ? 2 : 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.sports_soccer,
                                            size: 32,
                                            color: _selectedWinType == 'WDL' ? Colors.blue : Colors.grey.shade600,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Win/Draw/Lose',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _selectedWinType == 'WDL' ? Colors.blue : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '3-1-0 points',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // PTS option
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedWinType = 'PTS';
                                      // Set default values for PTS
                                      _winPointsController.text = '2';
                                      _drawPointsController.text = '1';
                                      _losePointsController.text = '0';
                                    });
                                  },
                                  child: Card(
                                    elevation: _selectedWinType == 'PTS' ? 4 : 1,
                                    color: _selectedWinType == 'PTS' ? Colors.blue.shade50 : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: _selectedWinType == 'PTS' ? Colors.blue : Colors.grey.shade300,
                                        width: _selectedWinType == 'PTS' ? 2 : 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.leaderboard,
                                            size: 32,
                                            color: _selectedWinType == 'PTS' ? Colors.blue : Colors.grey.shade600,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Points',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _selectedWinType == 'PTS' ? Colors.blue : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Custom scoring',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey.shade700,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Points settings section
                  if (_selectedWinType != 'WIN')
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Points Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Win points
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: const Text('Points for Win:'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _winPointsController,
                                    decoration: AppStyles.inputDecoration(''),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
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
                            const SizedBox(height: 8),

                            // Draw points
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: const Text('Points for Draw:'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _drawPointsController,
                                    decoration: AppStyles.inputDecoration(''),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
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
                            const SizedBox(height: 8),

                            // Lose points
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: const Text('Points for Lose:'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _losePointsController,
                                    decoration: AppStyles.inputDecoration(''),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
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
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Advanced settings section
                  if (_selectedWinType == 'PTS')
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Advanced Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Win margin bonus
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: const Text('Win margin bonus:'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _winMarginBonusController,
                                    decoration: AppStyles.inputDecoration(''),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Extra points for winning by more than the threshold',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Lose margin bonus
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: const Text('Lose within margin bonus:'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _loseMarginBonusController,
                                    decoration: AppStyles.inputDecoration(''),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Extra points for losing by less than the threshold',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Win margin threshold
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: const Text('Win margin threshold:'),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _winMarginThresholdController,
                                    decoration: AppStyles.inputDecoration(''),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'The margin threshold for bonus points',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
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
                  if (_errorMessage != null) const SizedBox(height: 16),

                  // League code display
                  if (_leagueCode != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(30),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withAlpha(100)),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'League created successfully!',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Share this code with others to join your league:',
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _leagueCode!,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.copy, color: Colors.blue),
                                onPressed: _copyLeagueCode,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _viewLeague,
                            style: AppStyles.primaryButtonStyle,
                            child: const Text('View League'),
                          ),
                        ],
                      ),
                    ),

                  if (_leagueCode == null) const SizedBox(height: 16),

                  // Create button
                  if (_leagueCode == null)
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
      ),
    );
  }
}
