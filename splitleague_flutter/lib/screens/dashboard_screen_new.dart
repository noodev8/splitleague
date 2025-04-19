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
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../styles/app_styles.dart';
import '../widgets/league_card.dart';
import 'create_league_screen.dart';
import 'fixtures_screen.dart';
import 'join_league_screen.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Selected tab index
  int _selectedIndex = 0;

  // User data is loaded but not directly used in the UI

  // Leagues data
  List<Map<String, dynamic>> _leagues = [];

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
      // Load user data (needed for authentication)
      await AuthHelper.getUserData();

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
          _leagues = leagues;
          _isLoading = false;
          _errorMessage = null;
        });
      } else {
        setState(() {
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
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SplitLeague'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildCurrentTab(),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Leagues',
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
      case 1:
        return _buildCreateTab();
      case 2:
        return _buildJoinTab();
      case 3:
        return _buildProfileTab();
      default:
        return _buildLeaguesTab();
    }
  }

  Widget _buildLeaguesTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: SmartRefresher(
        controller: _refreshController,
        onRefresh: _onRefresh,
        header: const WaterDropHeader(
          waterDropColor: AppStyles.primaryColor,
          complete: Icon(Icons.check, color: AppStyles.successColor),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => FixturesScreen(
                              league: _leagues[index],
                            ),
                          ),
                        ).then((_) => _loadData());
                      },
                      onRemove: _handleRemoveLeague,
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a League',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set up a new league and invite players',
              style: TextStyle(
                fontSize: 14,
                color: AppStyles.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const CreateLeagueScreen(),
                  ),
                ).then((_) => _loadData());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Create New League', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Join a League',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter a league code to join an existing league',
              style: TextStyle(
                fontSize: 14,
                color: AppStyles.secondaryTextColor,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => JoinLeagueScreen(
                      onLeagueJoined: () {
                        _loadData();
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppStyles.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Join Existing League', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Center(
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const ProfileScreen(),
              ),
            );
          },
          icon: const Icon(Icons.account_circle),
          label: const Text('View Profile'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppStyles.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}
