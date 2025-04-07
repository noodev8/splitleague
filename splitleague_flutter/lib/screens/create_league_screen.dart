/*
Show the create league screen allowing users to create a new league
This screen allows users to enter league details and create a new league
Once created, it returns to the dashboard screen
*/

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:intl/intl.dart';
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
  final _pointsForWinMarginController = TextEditingController(text: '1');
  final _pointsForCloseLossController = TextEditingController(text: '1');
  final _winMarginThresholdController = TextEditingController(text: '15');
  
  // Date controllers
  DateTime? _startDate;
  DateTime? _endDate;
  
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
    super.dispose();
  }

  // Format date for display
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  // Show date picker
  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? (_startDate ?? DateTime.now()) : (_endDate ?? DateTime.now().add(const Duration(days: 90))),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // If end date is before start date, update end date
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = _startDate!.add(const Duration(days: 90));
          }
        } else {
          _endDate = picked;
        }
      });
    }
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
      String name = _nameController.text.trim();
      int pointsForWin = int.tryParse(_pointsForWinController.text) ?? 3;
      int pointsForDraw = int.tryParse(_pointsForDrawController.text) ?? 1;
      int pointsForWinMargin = int.tryParse(_pointsForWinMarginController.text) ?? 1;
      int pointsForCloseLoss = int.tryParse(_pointsForCloseLossController.text) ?? 1;
      int winMarginThreshold = int.tryParse(_winMarginThresholdController.text) ?? 15;
      
      // Format dates if provided
      String? startDate = _startDate != null ? _formatDate(_startDate!) : null;
      String? endDate = _endDate != null ? _formatDate(_endDate!) : null;
      
      // Call create league API
      Map<String, dynamic> response = await CreateLeagueApi.createLeague(
        name: name,
        pointsForWin: pointsForWin,
        pointsForDraw: pointsForDraw,
        pointsForWinMargin: pointsForWinMargin,
        pointsForCloseLoss: pointsForCloseLoss,
        winMarginThreshold: winMarginThreshold,
        startDate: startDate,
        endDate: endDate,
      );
      
      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Show success message
        ErrorHelper.showSuccessToast('League created successfully!');
        
        // Navigate back to dashboard
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardScreen()),
          );
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
                
                // Points section
                const Text(
                  'Points System',
                  style: AppStyles.subheadingStyle,
                ),
                const SizedBox(height: 16),
                
                // Points for win field
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _pointsForWinController,
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Bonus points section
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
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
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _pointsForCloseLossController,
                        decoration: AppStyles.inputDecoration('Close Loss Points'),
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
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Win margin threshold field
                TextFormField(
                  controller: _winMarginThresholdController,
                  decoration: AppStyles.inputDecoration(
                    'Win Margin Threshold',
                    hint: 'Points difference to qualify for bonus',
                  ),
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
                const SizedBox(height: 24),
                
                // Dates section
                const Text(
                  'League Dates (Optional)',
                  style: AppStyles.subheadingStyle,
                ),
                const SizedBox(height: 16),
                
                // Start date picker
                InkWell(
                  onTap: () => _selectDate(context, true),
                  child: InputDecorator(
                    decoration: AppStyles.inputDecoration(
                      'Start Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _startDate != null ? _formatDate(_startDate!) : 'Select start date',
                      style: _startDate != null ? AppStyles.bodyStyle : AppStyles.captionStyle,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // End date picker
                InkWell(
                  onTap: () => _selectDate(context, false),
                  child: InputDecorator(
                    decoration: AppStyles.inputDecoration(
                      'End Date',
                      prefixIcon: const Icon(Icons.calendar_today),
                    ),
                    child: Text(
                      _endDate != null ? _formatDate(_endDate!) : 'Select end date',
                      style: _endDate != null ? AppStyles.bodyStyle : AppStyles.captionStyle,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Error message
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppStyles.errorColor.withOpacity(0.1),
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
