/*
Show the leagues dashboard screen after user login
Displays a list of leagues the user is a member of
Provides options to create or join leagues
*/

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../api/get_user_leagues_api.dart';
import '../api/update_last_accessed_api.dart';
import '../api/deactivate_league_membership_api.dart';
import '../api/get_fixtures_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';
import '../widgets/league_card.dart';
import 'create_league_screen.dart';
//import 'developer_screen.dart';
import 'fixtures_screen.dart';
import 'join_league_screen.dart';
import 'player_list_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Selected tab index
  int _selectedIndex = 0;

  // Leagues data
  List<Map<String, dynamic>> _leagues = [];

  // User data
  Map<String, dynamic>? _userData;

  // Loading states
  bool _isLoading = true;

  // Error message for leagues
  String? _errorMessage;

  // Refresh controller for pull-to-refresh
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  // Variables for developer mode tap detection
  // int _tapCount = 0;
  // DateTime? _lastTapTime;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  // Handle refresh
  void _onRefresh() async {
    await _loadData();
    _refreshController.refreshCompleted();
  }

  // Load user data and leagues
  Future<void> _loadData() async {
    try {
      // Load user data
      final userData = await AuthHelper.getUserData();

      // Load leagues
      final response = await GetUserLeaguesApi.getUserLeagues();

      if (response['return_code'] == 'SUCCESS') {
        // Get leagues from response
        final List<dynamic> leaguesData = response['leagues'] ?? [];

        // Convert to List<Map<String, dynamic>>
        final leagues = leaguesData.map((league) => league as Map<String, dynamic>).toList();

        // Sort by last_accessed (most recent first)
        leagues.sort((a, b) {
          final DateTime? lastAccessedA = a['last_accessed'] != null
              ? DateTime.parse(a['last_accessed'])
              : null;
          final DateTime? lastAccessedB = b['last_accessed'] != null
              ? DateTime.parse(b['last_accessed'])
              : null;

          if (lastAccessedA != null && lastAccessedB != null) {
            return lastAccessedB.compareTo(lastAccessedA);
          } else if (lastAccessedA != null) {
            return -1;
          } else if (lastAccessedB != null) {
            return 1;
          } else {
            return 0;
          }
        });

        setState(() {
          _userData = userData;
          _leagues = leagues;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
          _userData = userData;
          _isLoading = false;
          _errorMessage = response['message'] ?? 'Failed to load leagues';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred while loading data';
      });
    }
  }

  // Check if league has fixtures and navigate to appropriate screen
  Future<void> _checkFixturesAndNavigate(Map<String, dynamic> league) async {
    final leagueId = league['league_id'];

    try {
      // Check if league has fixtures
      final fixturesResponse = await GetFixturesApi.getFixtures(leagueId);
      final hasFixtures = fixturesResponse['return_code'] == 'SUCCESS' &&
                        (fixturesResponse['fixtures'] as List?)?.isNotEmpty == true;

      if (!mounted) return;

      if (hasFixtures) {
        // Navigate to fixtures screen if fixtures exist
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => FixturesScreen(
              league: league,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      } else {
        // Navigate to player list screen if no fixtures
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => PlayerListScreen(
              league: league,
            ),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // If there's an error, default to fixtures screen
      ErrorHelper.showErrorToast('Error checking league status');
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => FixturesScreen(
            league: league,
          ),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  // Handle removing a league
  Future<void> _handleRemoveLeague(int leagueId) async {
    try {
      final response = await DeactivateLeagueMembershipApi.deactivateLeagueMembership(leagueId);

      if (response['return_code'] == 'SUCCESS') {
        if (mounted) {
          ErrorHelper.showSuccessToast(response['message'] ?? 'League removed');
        }
        _loadData();
      } else {
        if (mounted) {
          ErrorHelper.showErrorToast(response['message'] ?? 'Failed to remove league');
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHelper.showErrorToast('An error occurred');
      }
    }
  }

  // Helper method to get initials from nickname
  String _getInitials(String nickname) {
    if (nickname.isEmpty) return '';

    List<String> nicknameParts = nickname.split(' ');
    if (nicknameParts.length > 1) {
      return nicknameParts[0][0].toUpperCase() + nicknameParts[1][0].toUpperCase();
    } else {
      return nickname[0].toUpperCase();
    }
  }

  // Navigate to selected tab
  void _onTabTapped(int index) {
    if (index == 1) {
      // Go directly to Create League screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const CreateLeagueScreen(),
        ),
      ).then((_) => _loadData());
    } else if (index == 2) {
      // Go directly to Join League screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => JoinLeagueScreen(
            onLeagueJoined: () {
              _loadData();
            },
          ),
        ),
      );
    } else if (index == 3) {
      // Go directly to Profile screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => const ProfileScreen(),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  // Handle title tap for developer mode
  // void _handleTitleTap() {
  //   final now = DateTime.now();

  //   // Check if this is a consecutive tap (within 2 seconds)
  //   if (_lastTapTime != null &&
  //       now.difference(_lastTapTime!).inSeconds < 2) {
  //     // Increment tap count
  //     _tapCount++;

  //     // Check if we've reached 5 taps
  //     if (_tapCount == 5) {
  //       // Reset tap count
  //       _tapCount = 0;

  //       // Navigate to developer screen
  //       Navigator.of(context).push(
  //         MaterialPageRoute(
  //           builder: (context) => const DeveloperScreen(),
  //         ),
  //       );
  //     }
  //   } else {
  //     // Reset tap count if too much time has passed
  //     _tapCount = 1;
  //   }

  //   // Update last tap time
  //   _lastTapTime = now;
  // }

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Scaffold(
        backgroundColor: Colors.transparent,  // Make scaffold background transparent
        appBar: AppBar(
          backgroundColor: Colors.transparent, // Make AppBar background transparent
          elevation: 0,
          toolbarHeight: 10,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildCurrentTab(),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppStyles.primaryColor,
          unselectedItemColor: AppStyles.secondaryTextColor,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline),
              activeIcon: Icon(Icons.add_circle),
              label: 'Create',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_add_outlined),
              activeIcon: Icon(Icons.group_add),
              label: 'Join',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_circle_outlined),
              activeIcon: Icon(Icons.account_circle),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onTabTapped,
        ),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedIndex) {
      case 0:
        return _buildLeaguesTab();
      default:
        return _buildLeaguesTab();
    }
  }

  Widget _buildLeaguesTab() {
    // Get user's name from userData
    final String userName = _userData != null ? _userData!['nickname'] ?? 'User' : 'User';

    return Container(
      width: double.infinity,
      height: double.infinity,
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
      child: Column(
        children: [
          // Top section with user info
          Container(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32.0, 8.0, 32.0, 16.0),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withAlpha(50),
                        child: Text(
                          _getInitials(userName),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your Leagues',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          userName,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SmartRefresher(
              controller: _refreshController,
              onRefresh: _onRefresh,
              header: const WaterDropHeader(
                waterDropColor: AppStyles.primaryColor,
                complete: Icon(Icons.check, color: AppStyles.successColor),
              ),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0), // Reduced vertical padding from 16.0 to 8.0
                children: [
                  // Error message
                  if (_errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8.0), // Reduced from 16.0
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
                              style: const TextStyle(color: AppStyles.errorColor),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Empty state
                  if (_leagues.isEmpty && _errorMessage == null)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 16),
                            const Text(
                              'You are not a member of any leagues yet.',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create or join a league to get started',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Leagues list
                  if (_leagues.isNotEmpty)
                    ...List.generate(
                      _leagues.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 2.0), // Reduced from 4.0 to 2.0
                        child: LeagueCard(
                          league: _leagues[index],
                          onTap: () {
                            final leagueId = _leagues[index]['league_id'];
                            UpdateLastAccessedApi.updateLastAccessed(leagueId);
                            final league = _leagues[index];
                            _checkFixturesAndNavigate(league);
                          },
                          onRemove: _handleRemoveLeague,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


