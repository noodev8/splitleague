/*
The dashboard: every league you are in, and what each of them wants from you.

This is the screen people were leaving from, so it is the screen that changed most.

What was wrong with it. The old dashboard was a full-page teal gradient with white cards
floating on it, a list of league names with a player count, and a four-item bottom
navigation bar. Three of those four items - Create, Join, Profile - were not tabs at all;
they pushed a screen and then the bar snapped back to Home. So the app's most prominent
piece of navigation was lying about what it did, while the actual next step for a new user
was not on the screen anywhere.

What it is now.

  * The header answers "does anything need me?" before you read a single league name.
    That is the whole job of a dashboard and the old one never did it.

  * The list is a to-do list. Each card carries the next step for that league in
    words - see helpers/league_prompt.dart - and the ones that want something carry a
    coloured rule.

  * The two things a person actually comes here to do that are not "open a league" -
    start a new one, join someone else's - are a fixed bar at the bottom, ranked.
    One filled teal button for the common case, one text link for the other.

  * The bottom navigation bar is gone. Profile moved to the avatar in the header,
    which is where people look for it anyway.

The empty state is treated as the most important screen in the app rather than as a grey
apology, because for a new user it IS the app.

Navigation behaviour underneath is deliberately unchanged - the dashboard still opens a
league with `push` and refreshes on `didPopNext`. See docs/next-league-flow.md for why
both of those matter; they are subtle and they were hard won.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import '../api/get_user_leagues_api.dart';
import '../api/update_last_accessed_api.dart';
import '../api/deactivate_league_membership_api.dart';
import '../api/get_fixtures_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/deep_link_helper.dart';
import '../helpers/error_helper.dart';
import '../helpers/league_prompt.dart';
import '../helpers/route_observer.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import '../widgets/league_card.dart';
import '../widgets/sl_button.dart';
import 'create_league_screen.dart';
import 'fixtures_screen.dart';
import 'join_league_screen.dart';
import 'login_user_screen.dart';
import 'player_list_screen.dart';
import 'profile_screen.dart';
import 'register_user_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with RouteAware {
  // Leagues data
  List<Map<String, dynamic>> _leagues = [];

  // User data
  Map<String, dynamic>? _userData;

  // Loading states
  bool _isLoading = true;

  // Error message for leagues
  String? _errorMessage;

  // Refresh controller for pull-to-refresh
  final RefreshController _refreshController = RefreshController(
    initialRefresh: false,
  );

  @override
  void initState() {
    super.initState();
    _loadData();

    // The dashboard being on screen is what makes it safe for a link to push a screen -
    // before this, the splash screen's pushReplacement would swallow anything we pushed.
    DeepLinkHelper.setDashboardReady(true);

    // So a league joined from a link shows up here without a manual refresh
    DeepLinkHelper.setOnLeagueJoined(_loadData);

    // Pick up a league link that arrived before there was anyone logged in to use it.
    // Both ways into the app land here - a cold start via the splash screen, and a fresh
    // login - so this is the one place that has to ask.
    DeepLinkHelper.handlePendingLink(context);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Listen for the league screens above us being popped, so we can refresh - see
    // _openLeague for why awaiting the push is not enough.
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  // Called when a screen pushed on top of the dashboard is popped and the dashboard is
  // visible again. Anything could have changed while the user was inside a league - most
  // obviously its stage - so reload rather than show a stale card.
  @override
  void didPopNext() {
    _loadData();
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);

    // Logging out tears the dashboard down, and a link must not push onto a stack that is
    // being replaced by the login screen.
    DeepLinkHelper.setDashboardReady(false);
    DeepLinkHelper.setOnLeagueJoined(null);

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

      // Check if user is logged in
      final isLoggedIn = await AuthHelper.isLoggedIn();

      if (isLoggedIn) {
        // User is logged in, load leagues
        final response = await GetUserLeaguesApi.getUserLeagues();

        // Check if response is unauthorized (expired/invalid token)
        final wasUnauthorized = await AuthHelper.handleUnauthorizedResponse(
          response,
        );
        if (wasUnauthorized) {
          // Token was invalid/expired, logout and redirect to login
          if (mounted) {
            ErrorHelper.showErrorToast(
              'Your session has expired. Please log in again.',
            );
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const LoginUserScreen()),
              (route) => false,
            );
          }
          return;
        }

        if (response['return_code'] == 'SUCCESS') {
          // Get leagues from response
          final List<dynamic> leaguesData = response['leagues'] ?? [];

          // Convert to List<Map<String, dynamic>>
          final leagues =
              leaguesData
                  .map((league) => league as Map<String, dynamic>)
                  .toList();

          _sortLeagues(leagues);

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
            _errorMessage =
                response['message'] ?? 'Could not load your leagues';
          });
        }
      } else {
        // User is not logged in (guest mode)
        setState(() {
          _userData = {'nickname': 'Guest'};
          _leagues = [];
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Could not load your leagues. Pull down to try again.';
      });
    }
  }

  // Order the list so that the leagues wanting something come first.
  //
  // This changed with the redesign. It used to be most-recently-opened first, full stop,
  // which meant a league you had just looked at outranked one with six results waiting.
  // Now attention wins, and recency breaks the tie inside each group - so the order is
  // still stable and familiar within a group, but the top of the list is always the work.
  void _sortLeagues(List<Map<String, dynamic>> leagues) {
    leagues.sort((a, b) {
      final bool attentionA = LeaguePrompt.needsAttention(a);
      final bool attentionB = LeaguePrompt.needsAttention(b);

      if (attentionA != attentionB) {
        return attentionA ? -1 : 1;
      }

      final DateTime? lastA = _parseDate(a['last_accessed']);
      final DateTime? lastB = _parseDate(b['last_accessed']);

      if (lastA != null && lastB != null) return lastB.compareTo(lastA);
      if (lastA != null) return -1;
      if (lastB != null) return 1;
      return 0;
    });
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  // Open a league.
  //
  // Which screen you land on is the league's stage: a league still being set up opens on
  // the player list, a league in play opens on the fixtures.
  //
  // Two things matter about how this navigates.
  //
  // First, `push` - not `pushReplacement`. The dashboard has to stay underneath, because
  // every screen inside a league swaps sideways with pushReplacement (players <-> fixtures
  // <-> standings <-> details). With the dashboard destroyed there was nothing left to go
  // back to, so Back could only rebuild a fresh dashboard from scratch - and `popUntil
  // (route.isFirst)`, which several screens use to get home, had no first route to find.
  // Keeping the dashboard at the bottom of the stack makes Back mean "leave this league"
  // from anywhere inside it.
  //
  // Second, the stage now comes from the league list itself - get_user_leagues sends
  // has_fixtures - so opening a league is instant. The API call is only a fallback for a
  // league map that predates that field.
  Future<void> _openLeague(Map<String, dynamic> league) async {
    bool hasFixtures;

    if (league.containsKey('has_fixtures') && league['has_fixtures'] != null) {
      hasFixtures = league['has_fixtures'] == true;
    } else {
      try {
        final fixturesResponse = await GetFixturesApi.getFixtures(
          league['league_id'],
        );
        hasFixtures =
            fixturesResponse['return_code'] == 'SUCCESS' &&
            (fixturesResponse['fixtures'] as List?)?.isNotEmpty == true;
      } catch (e) {
        if (!mounted) return;
        ErrorHelper.showErrorToast('Could not open that league');
        return;
      }
    }

    if (!mounted) return;

    // Hand the stage down with the league, so the screen we open does not have to
    // re-derive it and cannot disagree with what the dashboard just showed.
    final leagueWithStage = Map<String, dynamic>.from(league);
    leagueWithStage['has_fixtures'] = hasFixtures;

    // Not awaited to trigger a refresh. `pushReplacement` - which is how the screens
    // inside a league move between each other - completes this future the moment the user
    // taps a tab in there, long before they come back out. The refresh happens in
    // didPopNext instead, which fires when the league is actually left.
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) =>
                hasFixtures
                    ? FixturesScreen(league: leagueWithStage)
                    : PlayerListScreen(league: leagueWithStage),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  // Take a league off this dashboard.
  //
  // Asks first, and always has - the menu item used to remove on a single tap, which is
  // one slip away from a league vanishing.
  //
  // The wording says "Remove" and warns that the league is deleted later. What the code
  // does is still only deactivate_league_membership: the row survives and the other
  // players keep the league. The deleting is done by hand from the admin tool, so the
  // copy is a promise the app itself does not keep - if that plan changes, change this
  // text with it.
  Future<void> _handleRemoveLeague(int leagueId) async {
    final Map<String, dynamic> league = _leagues.firstWhere(
      (l) => l['league_id'] == leagueId,
      orElse: () => <String, dynamic>{},
    );

    final String name =
        league['name'] != null ? league['name'].toString() : 'this league';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('Remove this league?'),
            content: Text(
              '$name will be removed from your competitions and deleted after a '
              'period of time.',
              style: AppType.b(AppType.body),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Keep it'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppPalette.clay),
                child: const Text('Remove'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      final response =
          await DeactivateLeagueMembershipApi.deactivateLeagueMembership(
            leagueId,
          );

      if (response['return_code'] == 'SUCCESS') {
        _loadData();
      } else {
        if (mounted) {
          ErrorHelper.showErrorToast(
            response['message'] ?? 'Could not hide that league',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHelper.showErrorToast('Could not hide that league');
      }
    }
  }

  // Helper method to get initials from nickname
  String _getInitials(String nickname) {
    if (nickname.isEmpty) return '';

    List<String> nicknameParts = nickname.split(' ');
    if (nicknameParts.length > 1) {
      return nicknameParts[0][0].toUpperCase() +
          nicknameParts[1][0].toUpperCase();
    } else {
      return nickname[0].toUpperCase();
    }
  }

  bool get _isGuest => _userData != null && _userData!['nickname'] == 'Guest';

  void _openProfile() {
    if (_isGuest) {
      _showGuestLoginDialog();
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const ProfileScreen()));
  }

  void _openCreateLeague() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const CreateLeagueScreen()),
        )
        .then((_) => _loadData());
  }

  void _openJoinLeague() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => JoinLeagueScreen(onLeagueJoined: _loadData),
      ),
    );
  }

  // Show login/register dialog for guest users
  void _showGuestLoginDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign in to keep your leagues'),
          content: Text(
            'Signing in saves your leagues to your account, so they follow you '
            'to a new phone.',
            style: AppType.b(AppType.body),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Not now'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const RegisterUserScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text('Register'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginUserScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text('Sign in'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // The header is dark, and this is the only screen in the app where it is. The
    // status bar is drawn by the system over the top of it, so its icons have to be
    // asked for in white - otherwise the clock and the battery are dark grey on dark
    // teal, which is how the first build of this screen looked.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: _buildScaffold(),
    );
  }

  Widget _buildScaffold() {
    return Scaffold(
      backgroundColor: AppPalette.deep,
      body: Column(
        children: [
          _buildHeader(),

          // The content sits on a chalk sheet with rounded top corners, lifting off
          // the deep header. One shape change carries the whole "the app is the dark
          // band, the leagues are the paper" idea, so no other screen needs a gradient.
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppPalette.chalk,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              clipBehavior: Clip.antiAlias,
              child:
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _buildBody(),
            ),
          ),
        ],
      ),

      // The two actions that are not "open a league", ranked rather than stacked.
      bottomNavigationBar: _isLoading ? null : _buildActionBar(),
    );
  }

  // The header: who you are, and whether anything needs you.
  Widget _buildHeader() {
    final String userName =
        _userData != null ? _userData!['nickname'] ?? 'there' : 'there';

    // The one line that makes this a dashboard rather than a list. It is counted
    // from the same rule that colours the cards, so the number and the rules can
    // never disagree.
    final int waiting = _leagues.where(LeaguePrompt.needsAttention).length;

    final String subtitle =
        _isLoading
            ? ''
            : _leagues.isEmpty
            ? 'Set up your first league'
            : waiting == 0
            ? 'Nothing waiting on you'
            : waiting == 1
            ? '1 league needs you'
            : '$waiting leagues need you';

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 16, 22),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your leagues',
                    style: AppType.t(AppType.display, color: AppPalette.onDark),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      style: AppType.b(
                        AppType.meta,
                        color: AppPalette.onDark.withValues(alpha: 0.75),
                        size: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Profile. It used to be a bottom navigation item that was not a tab;
            // the avatar is where people look for their account anyway.
            Semantics(
              button: true,
              label: 'Your profile, $userName',
              excludeSemantics: true,
              child: Material(
                color: AppPalette.onDark.withValues(alpha: 0.16),
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: _openProfile,
                  child: SizedBox(
                    width: 46,
                    height: 46,
                    child: Center(
                      child: Text(
                        _getInitials(userName),
                        style: AppType.t(
                          AppType.titleSmall,
                          color: AppPalette.onDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    return SmartRefresher(
      controller: _refreshController,
      onRefresh: _onRefresh,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      header: const ClassicHeader(
        refreshStyle: RefreshStyle.Behind,
        height: 60.0,
        completeText: '',
        refreshingText: 'Updating',
        releaseText: '',
        idleText: '',
        textStyle: TextStyle(color: AppPalette.slate, fontSize: 12),
        failedIcon: Icon(
          Icons.error_outline,
          color: AppPalette.clay,
          size: 18.0,
        ),
        completeIcon: Icon(Icons.check, color: AppPalette.pitch, size: 18.0),
        idleIcon: SizedBox.shrink(),
        releaseIcon: SizedBox.shrink(),
        refreshingIcon: SizedBox(
          width: 18.0,
          height: 18.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            valueColor: AlwaysStoppedAnimation<Color>(AppPalette.teal),
          ),
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        children: [
          if (_errorMessage != null) _buildError(),
          if (_leagues.isEmpty && _errorMessage == null) _buildEmptyState(),

          for (final league in _leagues)
            LeagueCard(
              league: league,
              onTap: () {
                UpdateLastAccessedApi.updateLastAccessed(league['league_id']);
                _openLeague(league);
              },
              onRemove: _handleRemoveLeague,
            ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppPalette.clayTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppPalette.clay, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: AppType.b(AppType.meta, color: AppPalette.clay),
            ),
          ),
        ],
      ),
    );
  }

  // Nothing here yet.
  //
  // For a brand new user this is the app, so it gets the display face and says
  // what a league actually is in one sentence. The old version was two lines of
  // grey text apologising, with the real actions hidden in a navigation bar.
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 40, 4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No leagues yet', style: AppType.t(AppType.display)),
          const SizedBox(height: 10),
          Text(
            'A league is a group of people who play each other and keep a table. '
            'Set one up, add the players, and start entering results.',
            style: AppType.b(AppType.body, color: AppPalette.slate),
          ),
          const SizedBox(height: 28),

          // The three steps, as a numbered sequence - which is honest here, because
          // this genuinely is an order: you cannot enter a result before there are
          // fixtures, and there are no fixtures until there are players.
          _step('1', 'Name your league and pick how points work'),
          _step('2', 'Add the players, or share a link to let them join'),
          _step('3', 'Start it, then enter results as games are played'),
        ],
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 26,
            child: Text(
              number,
              style: AppType.t(AppType.figure, color: AppPalette.teal),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppType.b(AppType.body, color: AppPalette.slate),
            ),
          ),
        ],
      ),
    );
  }

  // The fixed bar at the bottom.
  //
  // One filled button and one text link, never two filled buttons - creating a league
  // is what most people opening this app are here to do, and joining one is the
  // occasional case. Ranking them is the point.
  Widget _buildActionBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppPalette.chalk,
        border: Border(top: BorderSide(color: AppPalette.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: SlButton.primary(
                  label: 'New league',
                  icon: Icons.add,
                  onPressed: _openCreateLeague,
                ),
              ),
              const SizedBox(width: 8),
              SlButton.quiet(
                label: 'Join with a code',
                onPressed: _openJoinLeague,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
