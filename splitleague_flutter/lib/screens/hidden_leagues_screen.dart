/*
Screen to display hidden leagues with option to restore them to the dashboard
*/

import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/get_hidden_leagues_api.dart';
import '../api/reactivate_league_membership_api.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';

class HiddenLeaguesScreen extends StatefulWidget {
  const HiddenLeaguesScreen({super.key});

  @override
  State<HiddenLeaguesScreen> createState() => _HiddenLeaguesScreenState();
}

class _HiddenLeaguesScreenState extends State<HiddenLeaguesScreen> {
  // Hidden leagues data
  List<Map<String, dynamic>> _hiddenLeagues = [];

  // Loading state
  bool _isLoading = true;

  // Error message
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHiddenLeagues();
  }

  // Load hidden leagues from the API
  Future<void> _loadHiddenLeagues() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Call the API to get hidden leagues
      final response = await GetHiddenLeaguesApi.getHiddenLeagues();

      if (response['return_code'] == 'SUCCESS') {
        // Convert the leagues data to a list of maps
        final List<dynamic> leaguesData = response['leagues'] ?? [];
        final List<Map<String, dynamic>> leagues = leaguesData
            .map((league) => Map<String, dynamic>.from(league as Map))
            .toList();

        setState(() {
          _hiddenLeagues = leagues;
          _isLoading = false;
        });
      } else {
        // Handle error
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'] ?? 'Failed to load hidden leagues';
        });
      }
    } catch (e) {
      // Handle exception
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred while loading hidden leagues';
      });
    }
  }

  // Handle restoring a league to the dashboard
  Future<void> _handleRestoreLeague(int leagueId) async {
    // Show confirmation dialog
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Restore League'),
          content: const Text('Are you sure you want to add this league back to your dashboard?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: AppStyles.primaryColor),
              child: const Text('Restore'),
            ),
          ],
        );
      },
    );

    // If user cancelled, do nothing
    if (confirm != true) return;

    try {
      // Call the API to reactivate league membership
      final response = await ReactivateLeagueMembershipApi.reactivateLeagueMembership(leagueId);

      if (response['return_code'] == 'SUCCESS') {
        // Show success message
        if (mounted) {
          ErrorHelper.showSuccessToast(response['message'] ?? 'League added back to dashboard');
        }

        // Reload the hidden leagues list
        _loadHiddenLeagues();
      } else {
        // Show error message
        if (mounted) {
          ErrorHelper.showErrorToast(
            response['message'] ?? 'Failed to restore league',
          );
        }
      }
    } catch (e) {
      // Show error message for exceptions
      if (mounted) {
        ErrorHelper.showErrorToast('An error occurred while restoring the league');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hidden Leagues'),
      ),
      body: _isLoading
          ? const Center(
              child: SpinKitCircle(
                color: AppStyles.primaryColor,
                size: 50.0,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHiddenLeagues,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Error message
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
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

                    // No hidden leagues message
                    if (_hiddenLeagues.isEmpty && _errorMessage == null)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.visibility_off,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No Hidden Leagues',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Leagues you remove from your dashboard will appear here',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withAlpha(30),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.amber.withAlpha(100)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 20,
                                      color: Colors.amber.shade800,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Non-accessed leagues are permanently deleted after 30 days',
                                        style: TextStyle(
                                          color: Colors.amber.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Warning message for non-empty list
                    if (_hiddenLeagues.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.amber.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withAlpha(100)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              size: 20,
                              color: Colors.amber.shade800,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Non-accessed leagues are permanently deleted after 30 days',
                                style: TextStyle(
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Hidden leagues list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _hiddenLeagues.length,
                        itemBuilder: (context, index) {
                          final league = _hiddenLeagues[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 1,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // League name
                                    Text(
                                      league['name'] ?? 'Unnamed League',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // League details
                                    Row(
                                      children: [
                                        // Player count
                                        Icon(
                                          Icons.people,
                                          size: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${league['player_count'] ?? 0} players',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                        const SizedBox(width: 16),

                                        // Creator badge
                                        if (league['is_creator'] == true)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppStyles.primaryColor.withAlpha(30),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Organiser',
                                              style: TextStyle(
                                                color: AppStyles.primaryColor,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),

                                    // Restore button
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _handleRestoreLeague(league['league_id']),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppStyles.primaryColor,
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: const Icon(Icons.visibility, size: 18),
                                        label: const Text('Add to Dashboard'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
