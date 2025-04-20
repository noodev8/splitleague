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
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => FixturesScreen(
              league: league,
            ),
          ),
        ).then((_) => _loadData());
      } else {
        // Navigate to player list screen if no fixtures
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PlayerListScreen(
              league: league,
            ),
          ),
        ).then((_) => _loadData());
      }
    } catch (e) {
      if (!mounted) return;

      // If there's an error, default to fixtures screen
      ErrorHelper.showErrorToast('Error checking league status');
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => FixturesScreen(
            league: league,
          ),
        ),
      ).then((_) => _loadData());
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('SplitLeague', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade900,
            Colors.blue.shade700,
            Colors.blue.shade200,
            Colors.white,
          ],
          stops: const [0.0, 0.1, 0.3, 1.0],
        ),
      ),
      child: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        header: const WaterDropHeader(
          waterDropColor: AppStyles.primaryColor,
          complete: Icon(Icons.check, color: AppStyles.successColor),
        ),
        child: SafeArea(
          bottom: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User profile section
                Container(
                  margin: const EdgeInsets.only(bottom: 16, top: 8),  // Adjusted margin
                  child: Row(
                    children: [
                      // Profile picture (tappable)
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
                          backgroundColor: Colors.white,
                          child: const Icon(Icons.person, color: Colors.blue, size: 36),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // User name
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Error message
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
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

                // Leagues list
                if (_leagues.isEmpty && _errorMessage == null)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.sports_soccer,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'You are not a member of any leagues yet.',
                            style: AppStyles.bodyStyle,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create or join a league to get started',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppStyles.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _leagues.length,
                    itemBuilder: (context, index) {
                      return LeagueCard(
                        league: _leagues[index],
                        onTap: () {
                          final leagueId = _leagues[index]['league_id'];
                          UpdateLastAccessedApi.updateLastAccessed(leagueId);

                          // Store the league data for use in the async function
                          final league = _leagues[index];

                          // Check if league has fixtures and navigate accordingly
                          _checkFixturesAndNavigate(league);
                        },
                        onRemove: _handleRemoveLeague,
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


