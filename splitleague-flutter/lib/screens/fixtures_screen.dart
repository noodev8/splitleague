/*
Show the fixtures for a league
This screen shows fixtures and provides navigation to standings and details
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/league_provider.dart';
import '../widgets/fixtures_tab_content.dart';
import '../helpers/auth_helper.dart';
import '../helpers/league_stage.dart';
import '../styles/app_styles.dart';
import '../widgets/league_stage_banner.dart';
import 'update_score_screen.dart';
import 'standings_screen.dart';
import 'league_details_screen.dart';
import 'dashboard_screen.dart';

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

  // ScrollController for fixtures list
  final ScrollController _scrollController = ScrollController();

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

  // Initialize the league provider with the current league
  Future<void> _initializeLeagueProvider() async {
    // Check if current user is the creator
    final userData = await AuthHelper.getUserData();

    // Check both creator_id and created_by fields
    final creatorId = widget.league['creator_id'] ?? widget.league['created_by'];
    final isCreator = userData != null &&
                      creatorId != null &&
                      userData['id'].toString() == creatorId.toString();

    // Initialize the league provider
    _leagueProvider.initLeague(widget.league['league_id'], isCreator);
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

  // Navigate to update score screen
  void _navigateToUpdateScore(Map<String, dynamic> fixture) async {
    // Create a new map with all existing fixture data plus the creator status
    final updatedFixture = Map<String, dynamic>.from(fixture);
    updatedFixture['is_creator'] = _leagueProvider.isCreator;

    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UpdateScoreScreen(
          fixture: updatedFixture,
          onScoreUpdated: () {
            _leagueProvider.loadFixtures();
            return true;
          },
        ),
      ),
    );

    if (result == true && mounted && !_isDisposing) {
      _leagueProvider.clearSuccessMessage();
      _leagueProvider.setLastUpdatedFixtureId(fixture['id']);
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
                        final String rawMemberName = member['nickname'] ?? member['name'] ?? 'Unknown Player';

                        // Format player name to remove 'guest_' prefix
                        final String memberName = rawMemberName.startsWith('guest_')
                            ? rawMemberName.substring(6)
                            : rawMemberName;

                        return ListTile(
                          leading: const Icon(Icons.person),
                          title: Text(memberName),
                          onTap: () {
                            // Pass the formatted name for display but keep the original ID for filtering
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
    // Dispose of the scroll controller
    _scrollController.dispose();
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) => const DashboardScreen(),
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                ),
              );
            }
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
                                      pageBuilder: (context, animation, secondaryAnimation) => StandingsScreen(
                                        league: widget.league,
                                      ),
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
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.leaderboard, color: AppStyles.primaryColor, size: 18),
                                      const SizedBox(width: 6),
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
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    PageRouteBuilder(
                                      pageBuilder: (context, animation, secondaryAnimation) => LeagueDetailsScreen(
                                        league: widget.league,
                                        hasFixtures: true, // We know fixtures exist since we're on the Fixtures screen
                                      ),
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

                  // Which stage this league is in. Always in play here - you only reach
                  // the fixtures screen once fixtures exist - but it is stated in the same
                  // place and the same words as on every other league screen.
                  const LeagueStageBanner(stage: LeagueStage.inPlay),

                  // Fixtures content - takes remaining space
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: FixturesTabContent(
                      isCreator: leagueProvider.isCreator,
                      isLoadingFixtures: leagueProvider.isLoadingFixtures,
                      isLoadingMembers: leagueProvider.isLoadingMembers,
                      fixtures: leagueProvider.fixtures,
                      filteredFixtures: leagueProvider.filteredFixtures,
                      filterPlayerId: leagueProvider.filterPlayerId,
                      filterPlayerName: leagueProvider.filterPlayerName,
                      filterPlayedStatus: leagueProvider.filterPlayedStatus,
                      fixturesErrorMessage: leagueProvider.fixturesErrorMessage,
                      successMessage: leagueProvider.successMessage,
                      lastUpdatedFixtureId: leagueProvider.lastUpdatedFixtureId,
                      scrollController: _scrollController,
                      onLoadFixtures: () {
                        // Clear the last updated fixture ID after loading fixtures
                        // to prevent scrolling on subsequent loads
                        leagueProvider.loadFixtures().then((_) {
                          if (leagueProvider.lastUpdatedFixtureId != null) {
                            // Wait a bit to ensure the UI has updated before clearing
                            Future.delayed(const Duration(seconds: 1), () {
                              leagueProvider.clearLastUpdatedFixtureId();
                            });
                          }
                        });
                      },
                      onShowFilterMenu: _showFilterMenu,
                      onNavigateToUpdateScore: _navigateToUpdateScore,
                      onClearFilter: leagueProvider.clearFilter,
                      onApplyPlayedStatusFilter: leagueProvider.applyPlayedStatusFilter,
                      onClearPlayedStatusFilter: leagueProvider.clearPlayedStatusFilter,
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
