/*
The players in a league that has not started yet.

This is where a new organiser lands straight after creating a league, so it is the second
screen in the drop-off. It has one job: get more people into this league, then start it.

What was wrong with it. There were three identical blue buttons - "Invite players", "Add
Guest", "Generate Fixtures" - plus a heading repeating the tab name, plus a three-line
stage banner, plus a bordered panel containing a paragraph explaining fixtures and an
italic note underneath. Every action looked equally urgent, so none of them read as the
next step, and the explanation of the one-way door was buried in a wall of text nobody
reads twice.

What it is now. The screen is a list of who is in, and the two actions are ranked against
each other:

    Invite players    filled teal - the thing we want, because a real player who
                      joins is worth more than a guest name typed by the organiser
    Add a guest       outlined - a real action, just not the one being pushed

Starting the league is a fixed bar at the bottom that only appears once there are enough
players to have a fixture at all. That is the sequence made physical: fill the list, then
the way forward appears. The consequences of starting stay in the confirmation dialog,
where they are read once at the moment they matter, instead of in a panel that is on
screen the whole time.
*/

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/get_league_members_api.dart';
import '../api/remove_player_from_league_api.dart';
import '../api/add_guest_player_api.dart';
import '../helpers/auth_helper.dart';
import '../helpers/error_helper.dart';
import '../helpers/league_stage.dart';
import '../helpers/share_helper.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import '../widgets/sl_button.dart';
import '../widgets/sl_league_header.dart';
import '../widgets/sl_segmented.dart';
import '../providers/league_provider.dart';
import 'fixtures_screen.dart';
import 'dashboard_screen.dart';
import 'league_details_screen.dart';

class PlayerListScreen extends StatefulWidget {
  final Map<String, dynamic> league;

  const PlayerListScreen({super.key, required this.league});

  @override
  State<PlayerListScreen> createState() => _PlayerListScreenState();
}

class _PlayerListScreenState extends State<PlayerListScreen> {
  // List of league members
  List<Map<String, dynamic>> _members = [];

  // Loading state
  bool _isLoading = true;

  // Error message
  String? _errorMessage;

  // Flag to track if current user is the creator
  bool _isCreator = false;

  // Flag to track if fixtures exist
  bool _hasFixtures = false;

  // Generate fixtures state
  bool _isGeneratingFixtures = false;
  String? _generateErrorMessage;

  // League provider
  late LeagueProvider _leagueProvider;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _checkFixtures();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize the league provider
    _leagueProvider = Provider.of<LeagueProvider>(context, listen: false);
  }

  // Check if fixtures exist for this league
  Future<void> _checkFixtures() async {
    // The dashboard hands the stage down with the league, so this is normally
    // already known and nothing has to be asked.
    if (widget.league.containsKey('has_fixtures')) {
      setState(() {
        _hasFixtures = widget.league['has_fixtures'] == true;
      });
      return;
    }

    // Nothing said. Assume not started, which is the harmless answer and is also
    // true of nearly every league that reaches this screen.
    setState(() {
      _hasFixtures = false;
    });
  }

  // Load league members
  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Check if current user is the creator
      final userData = await AuthHelper.getUserData();

      // The creator ID could be in 'creator_id', 'created_by', or the user might have 'is_creator' flag
      final creatorId =
          widget.league['creator_id'] ?? widget.league['created_by'];
      final isCreator =
          (userData != null &&
              creatorId != null &&
              userData['id'].toString() == creatorId.toString()) ||
          widget.league['is_creator'] == true;

      // Set creator flag
      setState(() {
        _isCreator = isCreator;
      });

      // Get league members
      final response = await GetLeagueMembersApi.getLeagueMembers(
        widget.league['league_id'],
      );

      if (response['return_code'] == 'SUCCESS') {
        final members = List<Map<String, dynamic>>.from(
          response['members'] ?? [],
        );

        setState(() {
          _members = members;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Could not load the players';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not load the players';
        _isLoading = false;
      });
    }
  }

  // Start the league.
  //
  // Generating fixtures is the one-way door between the two stages, and the only step in
  // the app that shuts things off: the join code stops working, nobody else can be added,
  // and players can no longer be removed. So it asks first, and says what changes rather
  // than a bare "are you sure?".
  //
  // The asking happens here rather than in the provider so that the button below only
  // reads "Starting" once something actually is.
  Future<void> _generateFixtures() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Start the league?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Everyone gets paired up and the league moves into play.',
                style: AppType.b(AppType.body),
              ),
              const SizedBox(height: 14),
              _consequence('No one else can join'),
              _consequence('Players cannot be removed'),
              _consequence('You enter results instead of adding people'),
              const SizedBox(height: 14),
              Text(
                'Details → Reset league undoes it, and deletes every fixture and score.',
                style: AppType.b(AppType.meta),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Not yet'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Start it'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isGeneratingFixtures = true;
      _generateErrorMessage = null;
    });

    try {
      // Initialize the league provider if needed
      if (_leagueProvider.currentLeagueId != widget.league['league_id']) {
        _leagueProvider.initLeague(widget.league['league_id'], _isCreator);
      }

      // Call the generate fixtures method from the provider
      final result = await _leagueProvider.generateFixtures();

      if (result) {
        setState(() {
          _isGeneratingFixtures = false;
          _hasFixtures = true;
        });

        // Through the door. Replace rather than push, because there is no going back to
        // a setup screen for a league that has started - Back should now leave the league
        // entirely and return to the dashboard sitting underneath.
        //
        // The league map is copied with has_fixtures flipped on, so the fixtures screen
        // and everything it navigates to know the stage without asking the server again.
        if (!mounted) return;
        final leagueNowInPlay = Map<String, dynamic>.from(widget.league);
        leagueNowInPlay['has_fixtures'] = true;

        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    FixturesScreen(league: leagueNowInPlay),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) => child,
            transitionDuration: Duration.zero,
          ),
        );
      } else {
        setState(() {
          _isGeneratingFixtures = false;
          _generateErrorMessage = _leagueProvider.generateErrorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _isGeneratingFixtures = false;
        _generateErrorMessage = 'Could not start the league';
      });
    }
  }

  // One consequence line in the start dialog.
  Widget _consequence(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 6, right: 10),
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: AppPalette.slate,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(child: Text(text, style: AppType.b(AppType.body, size: 14))),
        ],
      ),
    );
  }

  // Add guest player to league
  Future<void> _addGuestPlayer() async {
    if (_hasFixtures) {
      ErrorHelper.showErrorToast(
        'The league has started, so players cannot be added',
      );
      return;
    }

    final guestNickname = await _showAddGuestDialog();

    if (guestNickname == null || guestNickname.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await AddGuestPlayerApi.addGuestPlayer(
        leagueId: widget.league['league_id'],
        guestNickname: guestNickname,
      );

      if (response['return_code'] == 'SUCCESS') {
        // No success toast - the new player appearing in the list below says it already
        _loadMembers();
      } else if (response['return_code'] == 'FIXTURES_EXIST') {
        setState(() {
          _hasFixtures = true;
          _isLoading = false;
          ErrorHelper.showErrorToast(
            'The league has started, so players cannot be added',
          );
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Could not add that guest';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not add that guest';
        _isLoading = false;
      });
    }
  }

  // Capitalise the name the organiser typed
  //
  // The keyboard's own textCapitalization only shifts soft keyboards, so on desktop
  // and web a name typed as "dave smith" would go in lowercase. This does the job for
  // real: every word starts with a capital and the rest is left alone, so names people
  // deliberately write oddly - "McBride", "O'Neill" - survive untouched.
  String _capitaliseName(String value) {
    return value
        .split(' ')
        .map(
          (word) =>
              word.isEmpty ? word : word[0].toUpperCase() + word.substring(1),
        )
        .join(' ');
  }

  // Invite real players into the league
  //
  // This is the same action as "Share league" on the details screen - it opens the share
  // sheet with a link to the league's public page. It is repeated here because this is the
  // screen an organiser is actually on when they realise they are a player short.
  Future<void> _invitePlayers() async {
    await ShareHelper.shareLeague(
      shareSlug: widget.league['share_slug']?.toString(),
      name: widget.league['name']?.toString(),
      hasFixtures: _hasFixtures,
    );
  }

  // Show dialog to get guest nickname
  Future<String?> _showAddGuestDialog() async {
    final controller = TextEditingController();

    return showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add a guest'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Someone who plays but has no account. You keep their results for them.',
                  style: AppType.b(AppType.meta),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: 'Their name'),
                  autofocus: true,
                  textInputAction: TextInputAction.done,

                  // No underline under the name as it is typed
                  //
                  // The line is the keyboard's composing region - the IME marks the word it
                  // is still autocorrecting. Turning autocorrect and suggestions off removes
                  // it, which is right anyway: these are people's names, not dictionary words.
                  autocorrect: false,
                  enableSuggestions: false,

                  // Guest names are people's names, so the keyboard shifts itself for the
                  // first letter rather than leaving the organiser to type "dave".
                  textCapitalization: TextCapitalization.words,
                  onSubmitted:
                      (_) => Navigator.of(
                        context,
                      ).pop(_capitaliseName(controller.text.trim())),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed:
                    () => Navigator.of(
                      context,
                    ).pop(_capitaliseName(controller.text.trim())),
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  // Remove player from league
  Future<void> _removePlayer(int playerId, String playerName) async {
    if (_hasFixtures) {
      ErrorHelper.showErrorToast(
        'The league has started, so players cannot be removed',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Remove $playerName?'),
            content: Text(
              'They come out of this league. Nothing else about their account changes.',
              style: AppType.b(AppType.body),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Keep them'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppPalette.clay),
                child: const Text('Remove'),
              ),
            ],
          ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await RemovePlayerFromLeagueApi.removePlayerFromLeague(
        widget.league['league_id'],
        playerId,
      );

      if (response['return_code'] == 'SUCCESS') {
        // No success toast - the player vanishing from the list below says it already,
        // and the organiser has just confirmed the removal in a dialog. Errors still toast.
        _loadMembers();
      } else if (response['return_code'] == 'FIXTURES_EXIST') {
        setState(() {
          _hasFixtures = true;
          _isLoading = false;
          ErrorHelper.showErrorToast(
            'The league has started, so players cannot be removed',
          );
        });
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Could not remove that player';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not remove that player';
        _isLoading = false;
      });
    }
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

  void _openDetails() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:
            (context, animation, secondaryAnimation) => LeagueDetailsScreen(
              league: widget.league,
              hasFixtures: _hasFixtures,
            ),
        // Sideways move between two views of the same league, so it replaces rather
        // than stacks. The dashboard underneath stays put and Back still leaves the
        // league. See docs/next-league-flow.md.
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Two players is the minimum for a single fixture, so it is the point at which
    // starting the league stops being nonsense and the bottom bar appears.
    final bool canStart = _isCreator && !_hasFixtures && _members.length >= 2;

    return Scaffold(
      backgroundColor: AppPalette.chalk,
      body: Column(
        children: [
          SlLeagueHeader(
            leagueName: widget.league['name'] ?? 'League',
            stage: LeagueStageInfo.fromHasFixtures(_hasFixtures),
            selectedIndex: 0,
            segments: [
              const SlSegment(label: 'Players'),
              SlSegment(label: 'Details', onTap: _openDetails),
            ],
            onBack: _leaveLeague,
            actionIcon: Icons.ios_share,
            actionTooltip: 'Share this league',
            onAction: _invitePlayers,
          ),

          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? _buildError()
                    : _buildContent(),
          ),
        ],
      ),

      bottomNavigationBar: canStart ? _buildStartBar() : null,
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: AppType.b(AppType.body, color: AppPalette.slate),
            ),
            const SizedBox(height: 20),
            SlButton.secondary(label: 'Try again', onPressed: _loadMembers),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Once the league can be started, the start bar at the bottom holds the one
    // filled button on this screen, so these two step down a rank each. Below two
    // players there is nothing to start and getting people in is the whole job, so
    // inviting keeps the fill.
    final bool startBarShowing =
        _isCreator && !_hasFixtures && _members.length >= 2;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
      children: [
        // The two ways to get people in, ranked against each other. Inviting a real
        // person is the one pushed, because a guest is a name the organiser has to
        // keep updated by hand while a real player enters their own results.
        if (_isCreator && !_hasFixtures) ...[
          if (startBarShowing)
            SlButton.secondary(
              label: 'Invite players',
              icon: Icons.person_add_alt,
              onPressed: _invitePlayers,
              expand: true,
            )
          else
            SlButton.primary(
              label: 'Invite players',
              icon: Icons.person_add_alt,
              onPressed: _invitePlayers,
            ),

          const SizedBox(height: 10),

          if (startBarShowing)
            SlButton.quiet(
              label: 'Add a guest',
              icon: Icons.person_outline,
              onPressed: _addGuestPlayer,
              expand: true,
            )
          else
            SlButton.secondary(
              label: 'Add a guest',
              icon: Icons.person_outline,
              onPressed: _addGuestPlayer,
              expand: true,
            ),

          const SizedBox(height: 26),
        ],

        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            _members.length == 1
                ? 'IN THIS LEAGUE · 1'
                : 'IN THIS LEAGUE · ${_members.length}',
            style: AppType.b(AppType.eyebrow),
          ),
        ),

        Container(
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < _members.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 60,
                    color: AppPalette.hairline,
                  ),
                _buildMemberRow(_members[i]),
              ],
            ],
          ),
        ),

        if (_generateErrorMessage != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppPalette.clayTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _generateErrorMessage!,
              style: AppType.b(AppType.meta, color: AppPalette.clay),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMemberRow(Map<String, dynamic> member) {
    final memberId = member['id'];
    final memberName = member['nickname'] ?? member['name'] ?? 'Unknown player';
    final isOrganiser =
        member['is_creator'] == true ||
        member['is_organiser'] == true ||
        member['is_organizer'] == true;

    // Guests are rows in app_user with a nickname of the form "guest_Dave". The
    // prefix is storage, not something to show anybody.
    final isGuest = memberName.toString().startsWith('guest_');
    final displayName =
        isGuest ? memberName.toString().substring(6) : memberName.toString();

    final String? role = isOrganiser ? 'Organiser' : (isGuest ? 'Guest' : null);
    final Color roleColour =
        isOrganiser ? AppPalette.tealDeep : AppPalette.guest;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // The initial in a tinted disc. Guests are warm, everybody else is teal,
          // which is the only place the guest/member difference is shown as colour.
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isGuest ? AppPalette.guestTint : AppPalette.tealTint,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              displayName.isEmpty
                  ? '?'
                  : displayName.substring(0, 1).toUpperCase(),
              style: AppType.t(
                AppType.figure,
                color: isGuest ? AppPalette.guest : AppPalette.tealDeep,
                size: 14,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Text(
              displayName,
              style: AppType.b(AppType.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          if (role != null)
            Text(
              role,
              style: AppType.b(AppType.meta, color: roleColour, size: 12),
            ),

          if (_isCreator && !isOrganiser && !_hasFixtures)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppPalette.slate),
              tooltip: 'Remove $displayName',
              onPressed: () => _removePlayer(memberId, displayName),
            ),
        ],
      ),
    );
  }

  // The way forward, once there is somebody to play.
  //
  // A fixed bar rather than a panel in the scroll, because it is the conclusion of
  // the screen and it should not be something you have to scroll past a list to find.
  Widget _buildStartBar() {
    return Container(
      decoration: const BoxDecoration(
        color: AppPalette.chalk,
        border: Border(top: BorderSide(color: AppPalette.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: SlButton.primary(
            label:
                _isGeneratingFixtures
                    ? 'Starting'
                    : 'Start with ${_members.length} players',
            busy: _isGeneratingFixtures,
            onPressed: _isGeneratingFixtures ? null : _generateFixtures,
          ),
        ),
      ),
    );
  }
}
