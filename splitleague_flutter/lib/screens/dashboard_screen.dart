/*
Show the leagues dashboard screen after user login
Displays a list of leagues the user is a member of
Provides options to create or join leagues
*/

import 'package:flutter/material.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../api/get_user_leagues_api.dart';
import '../api/update_last_accessed_api.dart';
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
  // User data
  Map<String, dynamic>? _userData;

  // Leagues data
  List<Map<String, dynamic>> _leagues = [];

  // Loading states
  bool _isLoadingUser = true;
  bool _isLoadingLeagues = true;

  // Error message for leagues
  String? _leaguesErrorMessage;

  // Refresh controller for pull-to-refresh
  final RefreshController _refreshController = RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadUserLeagues();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  // Handle refresh
  void _onRefresh() async {
    await _loadUserLeagues();
    _refreshController.refreshCompleted();
  }

  // Load user data from secure storage
  Future<void> _loadUserData() async {
    try {
      Map<String, dynamic>? userData = await AuthHelper.getUserData();

      setState(() {
        _userData = userData;
        _isLoadingUser = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingUser = false;
      });
      ErrorHelper.showErrorToast('Failed to load user data');
    }
  }

  // Load user leagues from API
  Future<void> _loadUserLeagues() async {
    try {
      // Call the API to get user leagues
      final response = await GetUserLeaguesApi.getUserLeagues();


      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Get leagues from response
        final List<dynamic> leaguesData = response['leagues'] ?? [];

        // Convert to List<Map<String, dynamic>>
        final leagues = leaguesData.map((league) => league as Map<String, dynamic>).toList();

        // Sort leagues by last_accessed date (most recent first)
        leagues.sort((a, b) {
          final DateTime? lastAccessedA = a['last_accessed'] != null
              ? DateTime.parse(a['last_accessed'])
              : null;
          final DateTime? lastAccessedB = b['last_accessed'] != null
              ? DateTime.parse(b['last_accessed'])
              : null;

          // If both have last_accessed dates, compare them
          if (lastAccessedA != null && lastAccessedB != null) {
            return lastAccessedB.compareTo(lastAccessedA); // Descending order
          }
          // If only one has a last_accessed date, prioritize the one with a date
          else if (lastAccessedA != null) {
            return -1; // A comes first
          }
          else if (lastAccessedB != null) {
            return 1; // B comes first
          }
          // If neither has a last_accessed date, sort by joined_at date
          else {
            final DateTime joinedAtA = a['joined_at'] != null
                ? DateTime.parse(a['joined_at'])
                : DateTime(1970);
            final DateTime joinedAtB = b['joined_at'] != null
                ? DateTime.parse(b['joined_at'])
                : DateTime(1970);
            return joinedAtB.compareTo(joinedAtA); // Descending order
          }
        });

        setState(() {
          _leagues = leagues;
          _isLoadingLeagues = false;
          _leaguesErrorMessage = null;
        });
      } else {
        // Handle error
        setState(() {
          _isLoadingLeagues = false;
          _leaguesErrorMessage = response['message'] ?? 'Failed to load leagues';
        });
      }
    } catch (e) {
      // Handle exception
      setState(() {
        _isLoadingLeagues = false;
        _leaguesErrorMessage = 'An error occurred while loading leagues';
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SplitLeague'),
        actions: [
          // Profile button
          IconButton(
            icon: const Icon(Icons.account_circle),
            tooltip: 'Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: (_isLoadingUser || _isLoadingLeagues)
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _userData == null
              ? const Center(
                  child: Text('No user data found'),
                )
              : SmartRefresher(
                  controller: _refreshController,
                  onRefresh: _onRefresh,
                  header: const WaterDropHeader(
                    waterDropColor: AppStyles.primaryColor,
                    complete: Icon(Icons.check, color: AppStyles.successColor),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // League action buttons - more subtle design
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            // Create league button
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const CreateLeagueScreen(),
                                    ),
                                  ).then((_) => _loadUserLeagues()); // Reload leagues after returning
                                },
                                style: AppStyles.subtleButtonStyle,
                                icon: const Icon(Icons.add_circle_outline, size: 20),
                                label: const Text('Create'),
                              ),
                            ),
                            // Divider
                            Container(
                              height: 24,
                              width: 1,
                              color: Colors.grey.shade300,
                            ),
                            // Join league button
                            Expanded(
                              child: TextButton.icon(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => JoinLeagueScreen(
                                        onLeagueJoined: () {
                                          // Reload leagues when a league is joined
                                          _loadUserLeagues();
                                        },
                                      ),
                                    ),
                                  );
                                },
                                style: AppStyles.subtleButtonStyle,
                                icon: const Icon(Icons.group_add_outlined, size: 20),
                                label: const Text('Join'),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Error message
                      if (_leaguesErrorMessage != null)
                        Container(
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
                                  _leaguesErrorMessage!,
                                  style: const TextStyle(
                                    color: AppStyles.errorColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (_leaguesErrorMessage != null) const SizedBox(height: 16),

                      // Leagues list
                      if (_leagues.isEmpty && _leaguesErrorMessage == null)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'You are not a member of any leagues yet.',
                              style: AppStyles.bodyStyle,
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          // Disable scrolling on the inner ListView
                          physics: const NeverScrollableScrollPhysics(),
                          // Shrink the ListView to fit its content
                          shrinkWrap: true,
                          itemCount: _leagues.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 4),
                          itemBuilder: (context, index) {
                            return LeagueCard(
                              league: _leagues[index],
                              onTap: () async {
                                // Update the last_accessed timestamp
                                final leagueId = _leagues[index]['league_id'];

                                // Call the API to update last_accessed (don't wait for response)
                                UpdateLastAccessedApi.updateLastAccessed(leagueId);

                                // Navigate to fixtures screen with league_id instead of id
                                if (mounted) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => FixturesScreen(
                                        league: _leagues[index],
                                      ),
                                    ),
                                  ).then((_) {
                                    // Reload leagues when returning from fixtures screen
                                    _loadUserLeagues();
                                  });
                                }
                              },
                            );
                          },
                        ),

                      // Add some padding at the bottom
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
    );
  }
}
