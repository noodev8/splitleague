/*
Sample fixtures screen for guest users
Shows a sample league with fixtures without making API calls
*/

import 'package:flutter/material.dart';
import '../models/sample_league.dart';
import '../styles/app_styles.dart';
import 'dashboard_screen.dart';
import 'sample_standings_screen.dart';
import 'login_user_screen.dart';
import 'register_user_screen.dart';

class SampleFixturesScreen extends StatefulWidget {
  const SampleFixturesScreen({super.key});

  @override
  State<SampleFixturesScreen> createState() => _SampleFixturesScreenState();
}

class _SampleFixturesScreenState extends State<SampleFixturesScreen> {
  // Sample data
  final Map<String, dynamic> _league = SampleLeague.getSampleLeague();
  final List<Map<String, dynamic>> _fixtures = SampleLeague.getSampleFixtures();

  @override
  void initState() {
    super.initState();
  }

  // Show login/register dialog for guest users
  void _showGuestLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign in or Register'),
          content: const Text(
            'To create or join a league, you need to sign in or register an account. '
            'This allows you to track scores and share leagues with friends.'
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
                // Navigate to login screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const LoginUserScreen()),
                );
              },
              child: const Text('Sign In'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to register screen
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const RegisterUserScreen()),
                );
              },
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  // Show filter info dialog
  void _showFilterInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Filter Options'),
          content: const Text(
            'In the full app, players can filter fixtures by:\n\n'
            '• Player name\n'
            '• Played games\n'
            '• Upcoming games\n\n'
            'This makes it easy to find specific matches and track your progress.'
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_league['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
              ),
            );
          },
        ),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top section with unified design
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(30),
                      spreadRadius: 0,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  children: [
                    // Navigation buttons - unified design
                    Row(
                      children: [
                        // Fixtures label (current screen)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: AppStyles.primaryColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.sports_soccer, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Fixtures',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Standings button
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => const SampleStandingsScreen(),
                                  transitionDuration: Duration.zero,
                                  reverseTransitionDuration: Duration.zero,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.leaderboard, color: AppStyles.primaryColor, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Standings',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppStyles.primaryColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Details button
                        Expanded(
                          child: InkWell(
                            onTap: _showGuestLoginDialog,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.info_outline, color: AppStyles.primaryColor, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Details',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: AppStyles.primaryColor,
                                      fontSize: 14,
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

              // Sample message banner
              Container(
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.blue.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'This is a sample display. The actual app has the latest design and features.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Filter info bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    // Filter info button
                    OutlinedButton.icon(
                      onPressed: _showFilterInfo,
                      icon: const Icon(Icons.filter_list, size: 18),
                      label: const Text('All Fixtures'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ),
              ),

              // Fixtures list
              Expanded(
                child: _buildFixturesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build fixtures list
  Widget _buildFixturesList() {
    final fixtures = _fixtures;

    if (fixtures.isEmpty) {
      return const Center(
        child: Text('No fixtures found'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: fixtures.length,
      itemBuilder: (context, index) {
        final fixture = fixtures[index];
        return _buildFixtureCard(fixture);
      },
    );
  }

  // Build fixture card
  Widget _buildFixtureCard(Map<String, dynamic> fixture) {
    final bool played = fixture['played'] ?? false;
    final player1Name = fixture['player_1_name'] ?? 'Player 1';
    final player2Name = fixture['player_2_name'] ?? 'Player 2';
    final player1Score = fixture['player_1_score'];
    final player2Score = fixture['player_2_score'];

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: _showGuestLoginDialog,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Players and scores
              Row(
                children: [
                  // Player 1
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player1Name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        if (played)
                          Text(
                            player1Score.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),

                  // VS or score separator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: played ? Colors.grey.shade200 : AppStyles.primaryColor.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      played ? 'vs' : 'vs',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: played ? Colors.grey.shade700 : AppStyles.primaryColor,
                      ),
                    ),
                  ),

                  // Player 2
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          player2Name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.right,
                        ),
                        if (played)
                          Text(
                            player2Score.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),

              // Date or status
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Status
                    Row(
                      children: [
                        Icon(
                          played ? Icons.check_circle_outline : Icons.schedule,
                          size: 16,
                          color: played ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          played ? 'Played' : 'Upcoming',
                          style: TextStyle(
                            color: played ? Colors.green : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    // Date
                    Text(
                      _getFormattedDate(fixture['updated_at']),
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Format date string
  String _getFormattedDate(String? dateString) {
    if (dateString == null) return '';

    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 0) {
        return 'Upcoming';
      } else {
        return '${difference.inDays} days ago';
      }
    } catch (e) {
      return '';
    }
  }
}
