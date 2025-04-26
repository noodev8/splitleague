/*
Show the standings for a league
This screen shows the league standings
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/league_provider.dart';
import '../widgets/standings_tab_content.dart';
import '../helpers/auth_helper.dart';
import '../styles/app_styles.dart';
import 'fixtures_screen.dart';
import 'league_details_screen.dart';

class StandingsScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const StandingsScreen({
    super.key,
    required this.league,
  });

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  // Reference to the league provider
  late LeagueProvider _leagueProvider;

  // Flag to track if we're disposing
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    // Start initialization after the first build
    Future.microtask(() {
      if (mounted) {
        _initializeLeagueProvider();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Store reference to the provider without resetting it
    // This preserves filter states when navigating between screens
    _leagueProvider = Provider.of<LeagueProvider>(context, listen: false);
  }

  // Initialize the league provider with the current league
  Future<void> _initializeLeagueProvider() async {
    if (_isDisposing) return;  // Don't initialize if disposing

    // Check if current user is the creator
    final userData = await AuthHelper.getUserData();
    final isCreator = userData != null &&
        widget.league['creator_id'] != null &&
        userData['id'].toString() == widget.league['creator_id'].toString();

    // Initialize the league provider
    if (!_isDisposing) {  // Check again before updating
      _leagueProvider.initLeague(widget.league['league_id'], isCreator);

      // Load standings specifically
      _leagueProvider.loadStandings();
    }
  }

  @override
  void dispose() {
    // Mark as disposing to prevent further updates
    _isDisposing = true;
    // Don't clear the provider data to preserve filter states
    // This allows filters to persist when returning to the fixtures screen
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.league['name']}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Consumer<LeagueProvider>(
        builder: (context, leagueProvider, _) {
          return Container(
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
                                    MaterialPageRoute(
                                      builder: (context) => FixturesScreen(
                                        league: widget.league,
                                      ),
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
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.sports_soccer, color: AppStyles.primaryColor, size: 18),
                                      const SizedBox(width: 6),
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
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => LeagueDetailsScreen(
                                        league: widget.league,
                                      ),
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
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.info_outline, color: AppStyles.primaryColor, size: 18),
                                      const SizedBox(width: 6),
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

                  // Standings content - takes remaining space
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: StandingsTabContent(
                        isLoadingStandings: leagueProvider.isLoadingStandings,
                        standings: leagueProvider.standings,
                        standingsErrorMessage: leagueProvider.standingsErrorMessage,
                        winType: leagueProvider.leagueInfo['win_type'],
                        onLoadStandings: leagueProvider.loadStandings,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}



