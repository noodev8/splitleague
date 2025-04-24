/*
Show the fixtures for a league
This screen shows fixtures and provides navigation to standings and details
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/league_provider.dart';
import '../widgets/fixtures_tab_content.dart';
import '../helpers/auth_helper.dart';
import '../styles/app_styles.dart';
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
    // Store reference to the provider
    _leagueProvider = Provider.of<LeagueProvider>(context, listen: false);

    // We don't want to reset the provider here as it would clear filter states
    // Instead, we'll initialize it if it's not already initialized with this league
    if (_leagueProvider.currentLeagueId != widget.league['league_id']) {
      _leagueProvider.reset();
    }
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

  // Show filter menu for players only
  Future<void> _showFilterMenu(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.filter_list),
                    const SizedBox(width: 8),
                    const Text(
                      'Filter by Player',
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

              // Scrollable content
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // All players option
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text('All Players'),
                      onTap: () {
                        _leagueProvider.clearFilter();
                        Navigator.of(context).pop();
                      },
                    ),
                    const Divider(),

                    // Player list section
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                      child: Text(
                        'Select Player',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),

                    // Player list
                    ...List.generate(
                      _leagueProvider.leagueMembers.length,
                      (index) {
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
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );

    // Force UI refresh after bottom sheet is closed
    if (mounted) {
      setState(() {});
    }
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
    // Force rebuild when filter status changes by listening to the provider
    Provider.of<LeagueProvider>(context, listen: true);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.league['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Consumer<LeagueProvider>(
        builder: (context, leagueProvider, _) {
          return Container(
            color: AppStyles.backgroundColor,
            child: SafeArea(
              bottom: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [


                    // Navigation buttons
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Standings button
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => StandingsScreen(
                                    league: widget.league,
                                  ),
                                ),
                              ).then((_) {
                                // Force UI refresh when returning from standings
                                if (mounted) {
                                  setState(() {});
                                }
                              });
                            },
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.leaderboard, color: AppStyles.primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Standings',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppStyles.primaryColor
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Details button
                          InkWell(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => LeagueDetailsScreen(
                                    league: widget.league,
                                  ),
                                ),
                              ).then((_) {
                                // Force UI refresh when returning from details
                                if (mounted) {
                                  setState(() {});
                                }
                              });
                            },
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.info_outline, color: AppStyles.primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Details',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppStyles.primaryColor
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                      filterPlayedStatus: leagueProvider.filterPlayedStatus,
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
                      onApplyPlayedStatusFilter: leagueProvider.applyPlayedStatusFilter,
                      onClearPlayedStatusFilter: leagueProvider.clearPlayedStatusFilter,
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
