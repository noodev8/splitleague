/*
Show the fixtures for a league
This screen shows fixtures and provides navigation to standings and details
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/league_provider.dart';
import '../widgets/fixtures_tab_content.dart';
import '../helpers/auth_helper.dart';
import 'update_score_screen.dart';
import 'standings_screen.dart';
import 'league_details_screen.dart';

class FixturesScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const FixturesScreen({
    super.key,
    required this.league,
  });

  @override
  State<FixturesScreen> createState() => _FixturesScreenState();
}

class _FixturesScreenState extends State<FixturesScreen> {
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
    // Store reference to the provider and reset it
    _leagueProvider = Provider.of<LeagueProvider>(context, listen: false);
    // Reset the provider to allow reuse
    _leagueProvider.reset();
  }

  // Initialize the league provider with the current league
  Future<void> _initializeLeagueProvider() async {
    // Check if current user is the creator
    final userData = await AuthHelper.getUserData();
    final isCreator = userData != null &&
        widget.league['creator_id'] != null &&
        userData['id'].toString() == widget.league['creator_id'].toString();

    // Initialize the league provider
    _leagueProvider.initLeague(widget.league['league_id'], isCreator);
  }

  // Navigate to update score screen
  void _navigateToUpdateScore(Map<String, dynamic> fixture) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UpdateScoreScreen(
          fixture: fixture,
          onScoreUpdated: () => true,
        ),
      ),
    );

    // If score was updated, reload fixtures
    if (result == true && mounted && !_isDisposing) {
      _leagueProvider.loadFixtures();
    }
  }

  // Show filter menu
  void _showFilterMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter Fixtures',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.people),
                title: const Text('All Fixtures'),
                onTap: () {
                  _leagueProvider.clearFilter();
                  Navigator.of(context).pop();
                },
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _leagueProvider.leagueMembers.length,
                  itemBuilder: (context, index) {
                    final member = _leagueProvider.leagueMembers[index];
                    final memberId = member['id'].toString();
                    final memberName = member['nickname'] ?? member['name'] ?? 'Unknown Player';

                    return ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(memberName),
                      onTap: () {
                        _leagueProvider.applyFilter(memberId, memberName);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    // Mark as disposing to prevent further updates
    _isDisposing = true;
    // Clear the league provider data when leaving the screen
    _leagueProvider.clearData();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.league['name']),
      ),
      body: Consumer<LeagueProvider>(
        builder: (context, leagueProvider, _) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade100,
                  Colors.white,
                ],
              ),
            ),
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row with title
                    Text(
                      'Fixtures',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Navigation buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Standings button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => StandingsScreen(
                                  league: widget.league,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.leaderboard),
                          label: const Text('Standings'),
                        ),
                        // Details button
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => LeagueDetailsScreen(
                                  league: widget.league,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                          icon: const Icon(Icons.info_outline),
                          label: const Text('Details'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Fixtures content
                    FixturesTabContent(
                      isCreator: leagueProvider.isCreator,
                      isLoadingFixtures: leagueProvider.isLoadingFixtures,
                      isLoadingMembers: leagueProvider.isLoadingMembers,
                      isGeneratingFixtures: leagueProvider.isGeneratingFixtures,
                      fixtures: leagueProvider.fixtures,
                      filteredFixtures: leagueProvider.filteredFixtures,
                      leagueMembers: leagueProvider.leagueMembers,
                      filterPlayerId: leagueProvider.filterPlayerId,
                      filterPlayerName: leagueProvider.filterPlayerName,
                      generateErrorMessage: leagueProvider.generateErrorMessage,
                      fixturesErrorMessage: leagueProvider.fixturesErrorMessage,
                      membersErrorMessage: leagueProvider.membersErrorMessage,
                      successMessage: leagueProvider.successMessage,
                      fixturesCount: leagueProvider.fixturesCount,
                      onGenerateFixtures: () => leagueProvider.generateFixtures(context),
                      onLoadFixtures: leagueProvider.loadFixtures,
                      onShowFilterMenu: _showFilterMenu,
                      onNavigateToUpdateScore: _navigateToUpdateScore,
                      onRemovePlayerFromLeague: (playerId, playerName) =>
                          leagueProvider.removePlayerFromLeague(context, playerId, playerName),
                      onClearFilter: leagueProvider.clearFilter,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
