/*
The league table.

The shell only - the table itself is widgets/standings_tab_content.dart. Like the other
league screens it is now just the shared header plus its content, so the four views of a
league differ only in what they show.

The one addition is the share button in the header, and it is here on purpose: the table
is the thing people want to send to the group, and this is the screen they are looking at
when they want to send it.
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/league_provider.dart';
import '../widgets/standings_tab_content.dart';
import '../helpers/auth_helper.dart';
import '../helpers/league_stage.dart';
import '../helpers/share_helper.dart';
import '../styles/app_palette.dart';
import '../widgets/sl_league_header.dart';
import '../widgets/sl_segmented.dart';
import 'fixtures_screen.dart';
import 'league_details_screen.dart';
import 'dashboard_screen.dart';

class StandingsScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const StandingsScreen({super.key, required this.league});

  @override
  State<StandingsScreen> createState() => _StandingsScreenState();
}

class _StandingsScreenState extends State<StandingsScreen> {
  // Reference to the league provider
  late LeagueProvider _leagueProvider;

  // Flag to track if we're disposing
  bool _isDisposing = false;

  // The logged-in user's id, so their row in the table can be marked.
  int? _currentUserId;

  @override
  void initState() {
    super.initState();

    // Defer provider setup until after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDisposing) return;

      _leagueProvider = Provider.of<LeagueProvider>(context, listen: false);

      // 1) Kick off all our loads immediately (creator=false for now)
      _leagueProvider.initLeague(widget.league['league_id'], false);

      // 2) Then load real creator-flag asynchronously
      AuthHelper.getUserData().then((userData) {
        if (!mounted || _isDisposing) return;

        final isCreator =
            userData != null &&
            widget.league['creator_id'] != null &&
            userData['id'].toString() == widget.league['creator_id'].toString();
        _leagueProvider.setCreator(isCreator);

        setState(() {
          _currentUserId =
              userData?['id'] is int
                  ? userData!['id']
                  : int.tryParse(userData?['id']?.toString() ?? '');
        });
      });
    });
  }

  @override
  void dispose() {
    // Mark as disposing to prevent further updates
    _isDisposing = true;
    // Don't clear the provider data to preserve filter states
    // This allows filters to persist when returning to the fixtures screen
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

  // A sideways move to another view of the same league. Replaces rather than pushes,
  // so Back still means "leave this league". See docs/next-league-flow.md.
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
    return Scaffold(
      backgroundColor: AppPalette.chalk,
      body: Column(
        children: [
          SlLeagueHeader(
            leagueName: widget.league['name'] ?? 'League',
            // You only reach the table from a league that has started.
            stage: LeagueStage.inPlay,
            selectedIndex: 1,
            segments: [
              SlSegment(
                label: 'Fixtures',
                onTap:
                    () => _replaceWith(FixturesScreen(league: widget.league)),
              ),
              const SlSegment(label: 'Table'),
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
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: StandingsTabContent(
                    isLoadingStandings: leagueProvider.isLoadingStandings,
                    standings: leagueProvider.standings,
                    standingsErrorMessage: leagueProvider.standingsErrorMessage,
                    winType: leagueProvider.leagueInfo['win_type'],
                    onLoadStandings: leagueProvider.loadStandings,
                    currentUserId: _currentUserId,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
