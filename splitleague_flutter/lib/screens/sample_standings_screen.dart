/*
Sample standings screen for guest users
Shows a sample league with standings without making API calls
*/

import 'package:flutter/material.dart';
import '../models/sample_league.dart';
import '../styles/app_styles.dart';
import 'dashboard_screen.dart';
import 'sample_fixtures_screen.dart';
import 'login_user_screen.dart';
import 'register_user_screen.dart';

class SampleStandingsScreen extends StatefulWidget {
  const SampleStandingsScreen({super.key});

  @override
  State<SampleStandingsScreen> createState() => _SampleStandingsScreenState();
}

class _SampleStandingsScreenState extends State<SampleStandingsScreen> {
  // Sample data
  final Map<String, dynamic> _league = SampleLeague.getSampleLeague();
  final List<Map<String, dynamic>> _standings = SampleLeague.getSampleStandings();

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
                        // Fixtures button
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                PageRouteBuilder(
                                  pageBuilder: (context, animation, secondaryAnimation) => const SampleFixturesScreen(),
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
                                  Icon(Icons.sports_soccer, color: AppStyles.primaryColor, size: 18),
                                  SizedBox(width: 6),
                                  Text(
                                    'Fixtures',
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
                        // Standings label (current screen)
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
                                Icon(Icons.leaderboard, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Standings',
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

              // Standings content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildStandingsTable(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Build standings table
  Widget _buildStandingsTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table header
            _buildTableHeader(),
            const SizedBox(height: 8),
            // Table rows
            ...List.generate(
              _standings.length,
              (index) => _buildTableRow(_standings[index], index + 1),
            ),

            // Note for guest users
            const Padding(
              padding: EdgeInsets.only(top: 24.0),
              child: Text(
                'Note: This is a sample league table. Create your own league to track real scores!',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build table header
  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade300,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Position
          const SizedBox(
            width: 30,
            child: Text(
              '#',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          // Player name
          const Expanded(
            flex: 3,
            child: Text(
              'Player',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          // Played
          SizedBox(
            width: 30,
            child: Text(
              'P',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Won
          SizedBox(
            width: 30,
            child: Text(
              'W',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Drawn
          SizedBox(
            width: 30,
            child: Text(
              'D',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Lost
          SizedBox(
            width: 30,
            child: Text(
              'L',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Points
          SizedBox(
            width: 30,
            child: Text(
              'Pts',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Build table row
  Widget _buildTableRow(Map<String, dynamic> player, int position) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Position
          SizedBox(
            width: 30,
            child: Text(
              position.toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: position <= 3 ? AppStyles.primaryColor : Colors.grey.shade700,
              ),
            ),
          ),
          // Player name
          Expanded(
            flex: 3,
            child: Text(
              player['nickname'] ?? 'Player',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          // Played
          SizedBox(
            width: 30,
            child: Text(
              player['played'].toString(),
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Won
          SizedBox(
            width: 30,
            child: Text(
              player['won'].toString(),
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Drawn
          SizedBox(
            width: 30,
            child: Text(
              player['drawn'].toString(),
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Lost
          SizedBox(
            width: 30,
            child: Text(
              player['lost'].toString(),
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Points
          SizedBox(
            width: 30,
            child: Text(
              player['points'].toString(),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
