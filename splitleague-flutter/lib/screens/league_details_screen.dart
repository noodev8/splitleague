/*
Everything about a league that is not its fixtures or its table: the join code, who runs
it, how points work, and the organiser's controls.

This is the screen that had four full-width filled blue buttons stacked on it - "Reset All
Scores", "Reset League", "Copy League", "Manage League Members" - two of which destroy
data. All four looked exactly like the "Invite players" button above them, so the screen
was four equally loud demands to be pressed, and the two dangerous ones were the least
distinguishable of all.

They are now rows in a section headed ORGANISER, with the destructive pair in clay text at
the bottom - see widgets/sl_action_row.dart for why that is the right treatment rather
than a red button. The content itself is widgets/details_tab_content.dart.

The navigation logic below is unchanged and is load-bearing: resetting a league is the
one-way door swinging back, so it lands on the player list rather than on a fixtures
screen with nothing left to show. See docs/next-league-flow.md.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/league_provider.dart';
import '../widgets/details_tab_content.dart';
import '../helpers/auth_helper.dart';
import '../helpers/league_stage.dart';
import '../helpers/share_helper.dart';
import '../styles/app_palette.dart';
import '../widgets/sl_league_header.dart';
import '../widgets/sl_segmented.dart';
import '../api/get_notes_api.dart';
import 'fixtures_screen.dart';
import 'standings_screen.dart';
import 'dashboard_screen.dart';
import 'player_list_screen.dart';
import 'league_members_screen.dart';

class LeagueDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> league;
  final bool? hasFixtures; // Optional parameter to avoid the visual flip

  const LeagueDetailsScreen({
    super.key,
    required this.league,
    this.hasFixtures, // Pass this from the previous screen if known
  });

  @override
  State<LeagueDetailsScreen> createState() => _LeagueDetailsScreenState();
}

class _LeagueDetailsScreenState extends State<LeagueDetailsScreen> {
  // Reference to the league provider
  late LeagueProvider _leagueProvider;

  // Flag to track if we're disposing
  bool _isDisposing = false;

  // Flag to track if fixtures exist - initialized with the passed parameter if available
  bool _hasFixtures = false;

  // Organizer notes for the current user
  String? _organizerNotes;

  @override
  void initState() {
    super.initState();

    // Initialize hasFixtures from widget parameter if provided
    if (widget.hasFixtures != null) {
      _hasFixtures = widget.hasFixtures!;
    }

    // Start initialization after the first build
    Future.microtask(() {
      if (mounted) {
        _initializeLeagueProvider();
        _loadOrganizerNotes();
      }
    });
  }

  // Load organizer notes for the current user
  Future<void> _loadOrganizerNotes() async {
    if (_isDisposing) return;

    try {
      // Get current user ID
      final userData = await AuthHelper.getUserData();
      if (userData == null || _isDisposing) return;

      final userId = userData['id'];

      // Get notes for the current user
      final response = await GetNotesApi.getNotes(
        leagueId: widget.league['league_id'],
        userId: userId,
      );

      if (response['return_code'] == 'SUCCESS' && !_isDisposing) {
        setState(() {
          _organizerNotes = response['notes'];
        });
      } else if (!_isDisposing) {
        setState(() {
          _organizerNotes = null;
        });
      }
    } catch (e) {
      if (!_isDisposing) {
        setState(() {
          _organizerNotes = null;
        });
      }
    }
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
    // Check if current user is the creator
    final userData = await AuthHelper.getUserData();
    final isCreator =
        userData != null &&
        widget.league['creator_id'] != null &&
        userData['id'].toString() == widget.league['creator_id'].toString();

    // Initialize the league provider
    _leagueProvider.initLeague(widget.league['league_id'], isCreator);

    // Load league info specifically
    _leagueProvider.loadLeagueInfo();

    // Load fixtures and update hasFixtures state if not already set from widget parameter
    if (widget.hasFixtures == null) {
      _leagueProvider.loadFixtures().then((_) {
        if (mounted && !_isDisposing) {
          setState(() {
            _hasFixtures = _leagueProvider.fixtures.isNotEmpty;
          });
        }
      });
    }
  }

  // Handle copying text to clipboard
  void _handleCopyToClipboard(String? text) {
    if (text != null && text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text)).then((_) {
        if (mounted && !_isDisposing) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Join code copied')));
        }
      });
    }
  }

  // Handle editing league name
  void _handleEditLeagueName(String newName) {
    if (mounted && !_isDisposing) {
      _leagueProvider.updateLeagueName(context, newName);
    }
  }

  // Handle resetting all scores
  Future<void> _handleResetScores() async {
    if (mounted && !_isDisposing) {
      final success = await _leagueProvider.resetLeagueScores(context);

      // Scores are gone but the fixtures are not, so the league is still in play and the
      // fixtures screen is still the right place to land.
      if (success && mounted && !_isDisposing) {
        final leagueInPlay = Map<String, dynamic>.from(widget.league);
        leagueInPlay['has_fixtures'] = true;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    FixturesScreen(league: leagueInPlay),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    }
  }

  // Handle resetting league (deleting all fixtures)
  Future<void> _handleResetLeague() async {
    if (mounted && !_isDisposing) {
      final success = await _leagueProvider.resetLeague(context);

      // Resetting the league deletes every fixture, which puts it back into setup - it is
      // the one-way door swinging back. So land on the player list, not on a fixtures
      // screen that now has nothing to show. This used to go to fixtures either way.
      if (success && mounted && !_isDisposing) {
        setState(() {
          _hasFixtures = false;
        });

        final leagueInSetup = Map<String, dynamic>.from(widget.league);
        leagueInSetup['has_fixtures'] = false;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    PlayerListScreen(league: leagueInSetup),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      }
    }
  }

  // Handle copying league
  Future<void> _handleCopyLeague() async {
    if (mounted && !_isDisposing) {
      final response = await _leagueProvider.copyLeague(context);

      // If league was copied successfully, navigate to dashboard
      if (response != null &&
          response['return_code'] == 'SUCCESS' &&
          mounted &&
          !_isDisposing) {
        // Pop to the dashboard
        Navigator.of(context).popUntil((route) => route.isFirst);

        // Show a success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Copied to a new league: ${response['new_league']['name']}',
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  // Handle viewing league members
  //
  // A real push, so Back pops straight back here. If the members screen saved notes it
  // pops `true`, and we reload so the change shows without a round trip through a
  // rebuilt screen.
  void _handleViewMembers() async {
    if (mounted && !_isDisposing) {
      final result = await Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder:
              (context, animation, secondaryAnimation) =>
                  LeagueMembersScreen(league: widget.league),
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
        ),
      );

      if (result == true && mounted && !_isDisposing) {
        _loadOrganizerNotes();
      }
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
      hasFixtures: _hasFixtures,
    );
  }

  // Which views this league has, which depends on its stage.
  //
  // A league still being set up has no fixtures and no table, so it offers Players and
  // Details. A league in play has no player list left to manage, so it offers Fixtures,
  // Table and Details. This is the same rule the dashboard uses to decide which screen
  // to open when a league is tapped.
  List<SlSegment> _segments() {
    if (!_hasFixtures) {
      final leagueInSetup = Map<String, dynamic>.from(widget.league);
      leagueInSetup['has_fixtures'] = false;

      return [
        SlSegment(
          label: 'Players',
          onTap: () => _replaceWith(PlayerListScreen(league: leagueInSetup)),
        ),
        const SlSegment(label: 'Details'),
      ];
    }

    final leagueInPlay = Map<String, dynamic>.from(widget.league);
    leagueInPlay['has_fixtures'] = true;

    return [
      SlSegment(
        label: 'Fixtures',
        onTap: () => _replaceWith(FixturesScreen(league: leagueInPlay)),
      ),
      SlSegment(
        label: 'Table',
        onTap: () => _replaceWith(StandingsScreen(league: leagueInPlay)),
      ),
      const SlSegment(label: 'Details'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppPalette.chalk,
      body: Column(
        children: [
          Consumer<LeagueProvider>(
            builder: (context, leagueProvider, _) {
              return SlLeagueHeader(
                leagueName:
                    leagueProvider.leagueInfo['name'] ??
                    widget.league['name'] ??
                    'League',
                stage: LeagueStageInfo.fromHasFixtures(_hasFixtures),
                segments: _segments(),
                // Details is always the last segment, whichever set is showing.
                selectedIndex: _hasFixtures ? 2 : 1,
                onBack: _leaveLeague,
                actionIcon: Icons.ios_share,
                actionTooltip: 'Share this league',
                onAction: _shareLeague,
              );
            },
          ),

          Expanded(
            child: Consumer<LeagueProvider>(
              builder: (context, leagueProvider, _) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  child: DetailsTabContent(
                    leagueInfo: leagueProvider.leagueInfo,
                    hasFixtures: _hasFixtures,
                    onCopyToClipboard: _handleCopyToClipboard,
                    formatDate: _formatDate,
                    getPointsTypeDisplay: _getPointsTypeDisplay,
                    onEditLeagueName: _handleEditLeagueName,
                    onResetScores: _handleResetScores,
                    onResetLeague: _handleResetLeague,
                    onCopyLeague: _handleCopyLeague,
                    onViewMembers: _handleViewMembers,
                    organizerNotes: _organizerNotes,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // "6 May 2025" rather than "6/5/2025", which is ambiguous to half the world and
  // is the format the old screen used.
  String _formatDate(String? isoDate) {
    if (isoDate == null) return 'Unknown';

    final DateTime? date = DateTime.tryParse(isoDate);
    if (date == null) return 'Unknown';

    const List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // The scoring type in the same words the organiser chose it by on the create screen.
  // They used to differ - a league created as "Win/Lose" was described here as
  // "Win Only" - which is exactly the kind of small inconsistency that makes an app
  // feel like it was assembled rather than designed.
  String _getPointsTypeDisplay(String? winType) {
    switch (winType) {
      case 'WIN':
        return 'Win or lose';
      case 'WDL':
        return 'Win, draw or lose';
      case 'PTS':
        return 'Points scored';
      default:
        return 'Win or lose';
    }
  }
}
