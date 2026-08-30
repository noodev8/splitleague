/*
The fixtures of a league that is in play.

This is the shell: the shared league header, and the fixture list underneath it. The
list itself is widgets/fixtures_tab_content.dart.

The old version built its own header out of three full-width buttons and a three-line
stage banner. That is now SlLeagueHeader, which every league screen shares, so the four
views of a league differ only in their content - which is the whole idea behind them
being views of one thing.

The navigation between those views is deliberately unchanged: sideways moves replace
rather than push, so Back always means "leave this league". See docs/next-league-flow.md;
it is subtle and it was hard won.
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/league_provider.dart';
import '../widgets/fixtures_tab_content.dart';
import '../helpers/auth_helper.dart';
import '../helpers/league_stage.dart';
import '../helpers/share_helper.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import '../widgets/sl_league_header.dart';
import '../widgets/sl_segmented.dart';
import 'update_score_screen.dart';
import 'standings_screen.dart';
import 'league_details_screen.dart';
import 'dashboard_screen.dart';

class FixturesScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const FixturesScreen({super.key, required this.league});

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
    final creatorId =
        widget.league['creator_id'] ?? widget.league['created_by'];
    final isCreator =
        userData != null &&
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
        builder:
            (context) => UpdateScoreScreen(
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

  // Choose whose fixtures to show.
  //
  // A sheet rather than a menu because a league can have a lot of players, and a
  // sheet can scroll. "Everyone" is first and separated, so clearing the filter is
  // always the first thing under your thumb.
  Future<void> _showFilterMenu(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(sheetContext).size.height * 0.8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 8, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Show fixtures for',
                          style: AppType.t(AppType.titleSmall),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppPalette.slate),
                        tooltip: 'Close',
                        onPressed: () => Navigator.of(sheetContext).pop(),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                  thickness: 1,
                  color: AppPalette.hairline,
                ),

                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    children: [
                      ListTile(
                        title: Text('Everyone', style: AppType.b(AppType.name)),
                        onTap: () {
                          _leagueProvider.clearFilter();
                          Navigator.of(sheetContext).pop();
                        },
                      ),

                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: AppPalette.hairline,
                      ),

                      ...List.generate(_leagueProvider.leagueMembers.length, (
                        index,
                      ) {
                        final member = _leagueProvider.leagueMembers[index];
                        final memberId = member['id'].toString();
                        final String rawMemberName =
                            member['nickname'] ??
                            member['name'] ??
                            'Unknown player';

                        // Guests are stored with a "guest_" prefix on the nickname.
                        final String memberName =
                            rawMemberName.startsWith('guest_')
                                ? rawMemberName.substring(6)
                                : rawMemberName;

                        return ListTile(
                          title: Text(
                            memberName,
                            style: AppType.b(AppType.name),
                          ),
                          onTap: () {
                            // Pass the formatted name for display but keep the
                            // original ID for filtering.
                            _leagueProvider.applyFilter(memberId, memberName);
                            Navigator.of(sheetContext).pop();
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
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

  void _leaveLeague() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  const DashboardScreen(),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );
    }
  }

  // A sideways move to another view of the same league. Replaces rather than pushes.
  void _replaceWith(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  Future<void> _shareLeague() async {
    await ShareHelper.shareLeague(
      shareSlug: widget.league['share_slug']?.toString(),
      name: widget.league['name']?.toString(),
      hasFixtures: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Force rebuild when filter status changes by listening to the provider
    Provider.of<LeagueProvider>(context, listen: true);

    return Scaffold(
      backgroundColor: AppPalette.chalk,
      body: Column(
        children: [
          SlLeagueHeader(
            leagueName: widget.league['name'] ?? 'League',
            // Always in play here - you only reach this screen once fixtures exist.
            stage: LeagueStage.inPlay,
            selectedIndex: 0,
            segments: [
              const SlSegment(label: 'Fixtures'),
              SlSegment(
                label: 'Table',
                onTap:
                    () => _replaceWith(StandingsScreen(league: widget.league)),
              ),
              SlSegment(
                label: 'Details',
                onTap:
                    () => _replaceWith(
                      LeagueDetailsScreen(
                        league: widget.league,
                        hasFixtures: true,
                      ),
                    ),
              ),
            ],
            onBack: _leaveLeague,
            actionIcon: Icons.ios_share,
            actionTooltip: 'Share this league',
            onAction: _shareLeague,
          ),

          Expanded(
            child: Consumer<LeagueProvider>(
              builder: (context, leagueProvider, _) {
                return FixturesTabContent(
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
                    // so the highlight does not persist forever.
                    leagueProvider.loadFixtures().then((_) {
                      if (leagueProvider.lastUpdatedFixtureId != null) {
                        Future.delayed(const Duration(seconds: 2), () {
                          leagueProvider.clearLastUpdatedFixtureId();
                        });
                      }
                    });
                  },
                  onShowFilterMenu: _showFilterMenu,
                  onNavigateToUpdateScore: _navigateToUpdateScore,
                  onClearFilter: leagueProvider.clearFilter,
                  onApplyPlayedStatusFilter:
                      leagueProvider.applyPlayedStatusFilter,
                  onClearPlayedStatusFilter:
                      leagueProvider.clearPlayedStatusFilter,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
