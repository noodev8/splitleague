/*
Show the create league screen allowing users to create a new league
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/create_league_api.dart';
import '../api/update_last_accessed_api.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';

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
  final _playEachOtherController = TextEditingController(text: '1');

  // Loading state
  bool _isLoading = false;

  // Error message
  String? _errorMessage;

  // Allow code share setting
  bool _allowCodeShare = true; // Default to true

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
    _playEachOtherController.dispose();
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
      int winMarginBonus = int.tryParse(_winMarginBonusController.text) ?? 0;
      int loseMarginBonus = int.tryParse(_loseMarginBonusController.text) ?? 0;
      int winMarginThreshold = int.tryParse(_winMarginThresholdController.text) ?? 0;
      int playEachOther = int.tryParse(_playEachOtherController.text) ?? 1;

      // Debug print to verify the value
      print('Creating league with allow_code_share: $_allowCodeShare');

      // Call create league API
      Map<String, dynamic> response = await CreateLeagueApi.createLeague(
        name: leagueName,
        winType: winType,
        pointsForWin: winPoints,
        pointsForDraw: drawPoints,
        pointsForWinMargin: winMarginBonus,
        pointsForCloseLoss: loseMarginBonus,
        winMarginThreshold: winMarginThreshold,
        playEachOther: playEachOther,
        allowCodeShare: _allowCodeShare,
      );

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Get league ID and public code from the nested league object
        final leagueId = response['league']['id'];
        final publicCode = response['league']['public_code'];

        if (leagueId != null) {
          await UpdateLastAccessedApi.updateLastAccessed(leagueId);
        }

        // Set loading state to false
        setState(() {
          _isLoading = false;
        });

        // Show the league PIN dialog
        if (mounted) {
          _showLeaguePinDialog(publicCode, leagueId);
        }
      } else {
        // Show error message with more detail
        setState(() {
          _errorMessage = ErrorHelper.getErrorMessage(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      // Show detailed error message
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }



  // Show league PIN dialog
  void _showLeaguePinDialog(String pin, int leagueId) {

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'League created successfully!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Share this code with others to join your league:',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 20),

                // More prominent PIN display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade100, Colors.blue.shade50],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withAlpha(51), // 0.2 opacity (51/255)
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        pin,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.copy, size: 18),
                        label: const Text('Copy Code'),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: pin));
                          ErrorHelper.showSuccessToast('PIN copied to clipboard');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blue,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: Colors.blue.shade200),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Close button
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    // Use popUntil to ensure we go back to the dashboard
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // When dialog is dismissed (by any means), navigate back to previous screen
      if (mounted) {
        // Use popUntil to ensure we go back to the dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create League',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          )
        ),
        backgroundColor: AppStyles.primaryColor,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: _isLoading
                ? const SpinKitThreeBounce(
                    color: Colors.white,
                    size: 24,
                  )
                : TextButton(
                    onPressed: _handleCreateLeague,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check, size: 20),
                        SizedBox(width: 4),
                        Text(
                          'Create',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      body: Container(
        color: AppStyles.backgroundColor,
        child: SafeArea(
          bottom: false,
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
                            'Name',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _leagueNameController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: AppStyles.inputDecoration(
                              'Max 30 chars',
                              prefixIcon: const Icon(Icons.sports_soccer),
                            ),
                            maxLength: 30,
                            buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                            // Validate on change to clear error message immediately
                            onChanged: (value) {
                              // Only validate if there was an error before
                              if (_formKey.currentState != null) {
                                // This will trigger validation and clear the error if valid
                                _formKey.currentState!.validate();
                              }
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


                          // Win type selection
                          const Text(
                            'Scoring System',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Scoring system cards - horizontal layout
                          Column(
                            children: [
                              // WIN option
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedWinType = 'WIN';
                                    // Set default values for WIN
                                    _winPointsController.text = '1';
                                    _drawPointsController.text = '0';
                                    _losePointsController.text = '0';
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedWinType == 'WIN' ? Colors.blue.shade50 : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedWinType == 'WIN' ? Colors.blue : Colors.grey.shade300,
                                      width: _selectedWinType == 'WIN' ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _selectedWinType == 'WIN' ? Colors.blue.withAlpha(30) : Colors.grey.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.emoji_events,
                                            size: 24,
                                            color: _selectedWinType == 'WIN' ? Colors.blue : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Win Only',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: _selectedWinType == 'WIN' ? Colors.blue : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // WDL option
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedWinType = 'WDL';
                                    // Set default values for WDL
                                    _winPointsController.text = '3';
                                    _drawPointsController.text = '1';
                                    _losePointsController.text = '0';
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: _selectedWinType == 'WDL' ? Colors.blue.shade50 : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedWinType == 'WDL' ? Colors.blue : Colors.grey.shade300,
                                      width: _selectedWinType == 'WDL' ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _selectedWinType == 'WDL' ? Colors.blue.withAlpha(30) : Colors.grey.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.sports_soccer,
                                            size: 24,
                                            color: _selectedWinType == 'WDL' ? Colors.blue : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Win/Draw/Lose',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: _selectedWinType == 'WDL' ? Colors.blue : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              // PTS option
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedWinType = 'PTS';
                                    // Set default values for PTS
                                    _winPointsController.text = '2';
                                    _drawPointsController.text = '1';
                                    _losePointsController.text = '0';
                                  });
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: _selectedWinType == 'PTS' ? Colors.blue.shade50 : Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: _selectedWinType == 'PTS' ? Colors.blue : Colors.grey.shade300,
                                      width: _selectedWinType == 'PTS' ? 2 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(10),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _selectedWinType == 'PTS' ? Colors.blue.withAlpha(30) : Colors.grey.shade100,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(
                                            Icons.leaderboard,
                                            size: 24,
                                            color: _selectedWinType == 'PTS' ? Colors.blue : Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          'Points',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: _selectedWinType == 'PTS' ? Colors.blue : Colors.black87,
                                          ),
                                        ),
                                      ],
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

                  // Play each other section
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
                            'Fixtures',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Play each other
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: const Text('Times to play each other:'),
                              ),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _playEachOtherController,
                                  decoration: AppStyles.inputDecoration(''),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  // Validate on change to clear error message immediately
                                  onChanged: (value) {
                                    if (_formKey.currentState != null) {
                                      _formKey.currentState!.validate();
                                    }
                                  },
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Required';
                                    }
                                    if (int.tryParse(value) == 0) {
                                      return 'Min 1';
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
                                    // Validate on change to clear error message immediately
                                    onChanged: (value) {
                                      if (_formKey.currentState != null) {
                                        _formKey.currentState!.validate();
                                      }
                                    },
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
                                    // Validate on change to clear error message immediately
                                    onChanged: (value) {
                                      if (_formKey.currentState != null) {
                                        _formKey.currentState!.validate();
                                      }
                                    },
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
                                    // Validate on change to clear error message immediately
                                    onChanged: (value) {
                                      if (_formKey.currentState != null) {
                                        _formKey.currentState!.validate();
                                      }
                                    },
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

                  const SizedBox(height: 16),

                  // Code sharing settings section
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
                            'Privacy Settings',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Allow code sharing toggle
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Allow players to see and share league code',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'When disabled, only you can see and share the league code',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: _allowCodeShare,
                                onChanged: (value) {
                                  setState(() {
                                    _allowCodeShare = value;
                                  });
                                },
                                activeColor: AppStyles.primaryColor,
                              ),
                            ],
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

                  // Remove these lines
                  // if (_leagueCode == null) const SizedBox(height: 16),

                  // Remove the Create button section
                  // if (_leagueCode == null)
                  //   ElevatedButton(
                  //     onPressed: _isLoading ? null : _handleCreateLeague,
                  //     style: AppStyles.primaryButtonStyle,
                  //     child: _isLoading
                  //         ? const SpinKitThreeBounce(
                  //             color: Colors.white,
                  //             size: 24,
                  //           )
                  //         : const Text(
                  //             'Create League',
                  //             style: TextStyle(fontSize: 16),
                  //           ),
                  //   ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}








