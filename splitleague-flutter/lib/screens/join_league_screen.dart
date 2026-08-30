/*
Show the join league screen

There are two completely different ways to arrive here, and the screen is two different things
depending on which one it was:

  TYPED    Somebody was told a code - "join with 1231" - and tapped Join League on the dashboard.
           They get the four boxes, type the code, and press Join. This is the original screen.

  BY LINK  Somebody was sent a link and tapped it. The app opened here with the league already
           identified by its share slug. They never typed anything, they have no code, and there
           is nothing for them to check - so there are NO code boxes at all. They get the league
           name, who is running it, how many players are in, and one button.

That second case is the whole point of the share slug. A slug is ten characters and nobody is
going to type it, so a screen that asks for input would be a wall rather than an invitation. It
also means nothing on this screen may assume the identifier is four characters long.

Once joined, it returns to the dashboard screen.
*/

import 'package:flutter/material.dart';
import '../api/join_league_api.dart';
import '../api/get_league_preview_api.dart';
import '../helpers/auth_helper.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import '../widgets/pin_input.dart';
import '../widgets/sl_button.dart';
import 'login_user_screen.dart';
import 'register_user_screen.dart';

class JoinLeagueScreen extends StatefulWidget {
  final Function? onLeagueJoined;

  // The league this screen was opened FOR, when it was opened by a link
  //
  // Holds whatever sat after /l/ in the link: a share slug normally, or a 4-digit code if the
  // link was shared before slugs existed. Either is passed straight to the server, which works
  // out which it is - see join_league.js.
  //
  // Null when the person opened this screen themselves and is going to type a code.
  final String? leagueKey;

  const JoinLeagueScreen({super.key, this.onLeagueJoined, this.leagueKey});

  @override
  State<JoinLeagueScreen> createState() => _JoinLeagueScreenState();
}

class _JoinLeagueScreenState extends State<JoinLeagueScreen> {
  // Loading state, while a join is in flight
  bool _isLoading = false;

  // Error message
  String? _errorMessage;

  // The code typed into the boxes, on the typed route only
  String _typedCode = '';

  // Details of the league being joined, when we arrived from an invite link
  //
  // Somebody who typed a code they were told already knows what they are joining. Somebody who
  // followed a link does not - they never typed anything - so the screen has to say what the
  // league is and who is running it, or there is nothing on screen to say yes to.
  String? _inviteLeagueName;
  String? _inviteOrganiser;
  int? _invitePlayerCount;

  // Whether the league has already started, and whether we are already in it
  //
  // A league that has fixtures cannot be joined - join_league.js returns FIXTURES_EXIST - so
  // offering a Join button would walk somebody all the way to a refusal. The honest thing is to
  // say so and name the organiser, which is exactly what the public web page does.
  bool _inviteHasFixtures = false;
  bool _inviteIsMember = false;

  bool _loadingPreview = false;

  // Did this screen open because somebody tapped a link?
  bool get _arrivedFromLink => widget.leagueKey != null;

  // Can this league be joined right now?
  //
  // Only false in the one case we actually know about: an under-way league we are not already
  // in. If the preview could not be fetched we do not know, and we let the person press the
  // button and get a real answer from the server rather than guessing at them.
  bool get _canJoin => !(_inviteHasFixtures && !_inviteIsMember);

  @override
  void initState() {
    super.initState();

    // Only look anything up when a league came in from a link
    if (widget.leagueKey != null) {
      _loadPreview(widget.leagueKey!);
    }
  }

  // Fetch the league's name and organiser so the invite can be shown properly
  //
  // A failure here does not block anything. The Join button still works, because the league key
  // came from the link and not from the preview - the person just gets a plainer screen.
  Future<void> _loadPreview(String leagueKey) async {
    setState(() {
      _loadingPreview = true;
    });

    try {
      final response = await GetLeaguePreviewApi.getLeaguePreview(leagueKey);

      if (!mounted) {
        return;
      }

      if (response['return_code'] == 'SUCCESS') {
        setState(() {
          _inviteLeagueName = response['name']?.toString();
          _inviteOrganiser = response['organiser']?.toString();
          _invitePlayerCount =
              response['player_count'] is int
                  ? response['player_count']
                  : int.tryParse(response['player_count']?.toString() ?? '');
          _inviteHasFixtures = response['has_fixtures'] == true;
          _inviteIsMember = response['is_member'] == true;
          _loadingPreview = false;
        });
      } else {
        setState(() {
          _loadingPreview = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loadingPreview = false;
        });
      }
    }
  }

  // Handle join league button press
  Future<void> _handleJoinLeague() async {
    // Which identifier are we joining with?
    //
    // The link's key if there was one, otherwise whatever was typed. Nothing below cares which
    // it is or how long it is.
    final String leagueKey = widget.leagueKey ?? _typedCode;

    // Only the typed route can produce an incomplete identifier
    if (!_arrivedFromLink && _typedCode.length != 4) {
      setState(() {
        _errorMessage = 'A join code is four digits';
      });
      return;
    }

    // Check if user is in guest mode
    final isGuest = await AuthHelper.getUserData().then(
      (userData) => userData == null || userData['nickname'] == 'Guest',
    );

    if (isGuest) {
      // Show registration dialog for guest users
      _showGuestRegistrationDialog();
      return;
    }

    // Set loading state
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Call join league API
      Map<String, dynamic> response = await JoinLeagueApi.joinLeague(leagueKey);

      // Check response
      if (response['return_code'] == 'SUCCESS') {
        // Stop loading
        setState(() {
          _isLoading = false;
          _errorMessage = null;
        });

        // Call the callback if provided
        if (widget.onLeagueJoined != null) {
          widget.onLeagueJoined!();
        }

        // No success toast - the league appearing on the dashboard says it already.
        // onLeagueJoined above refreshes that list before we pop back to it.

        // Navigate back immediately
        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        // Show error message
        setState(() {
          _isLoading = false;
          _errorMessage = response['message'];
        });
      }
    } catch (e) {
      // Show error message
      setState(() {
        _isLoading = false;
        _errorMessage = 'An error occurred. Please try again.';
      });
    }
  }

  // Show guest registration dialog
  void _showGuestRegistrationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Registration Required'),
          content: const Text(
            'To join a league, you need to register an account or sign in. '
            'This allows you to track scores and participate in leagues with friends.\n\n'
            'Registration is free and only takes a minute.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to login screen with a clean slate
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const LoginUserScreen(),
                  ),
                  (route) => false, // Remove all previous routes
                );
              },
              child: const Text('Sign In'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                // Navigate to register screen with a clean slate
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const RegisterUserScreen(),
                  ),
                  (route) => false, // Remove all previous routes
                );
              },
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  // Handle PIN code completion, on the typed route only
  //
  // This only records the code and closes the keyboard. It deliberately does NOT join - joining
  // is a deliberate press of the button, never a side effect of finishing typing.
  void _onPinCompleted(String pin) {
    setState(() {
      _typedCode = pin;
      _errorMessage = null;
    });

    // Close the keyboard so the Join button is visible
    if (pin.length == 4) {
      FocusScope.of(context).unfocus();
    }
  }

  // What the screen says at the top
  //
  // An invitation when we know what league it is and it can be joined; instructions when the
  // person has to type. A league that has already started is NOT an invitation - saying "You've
  // been invited" above a message explaining that they cannot join would be a small lie, and
  // this is the first thing the person reads.
  String get _title {
    if (!_canJoin) {
      return 'Already under way';
    }

    // Following your own league's link is a normal thing to do - it is the same link you sent
    // everybody else. Do not greet somebody who is already in with an invitation.
    if (_inviteIsMember) {
      return "You're already in";
    }

    if (_inviteLeagueName != null) {
      return "You've been invited";
    }

    if (_arrivedFromLink) {
      return 'Join this league';
    }

    return 'Join a league';
  }

  // The line under the title.
  //
  // On the link route this is the whole reason the screen is worth showing: the person
  // tapped a link out of a group chat and wants to know what they are about to join
  // before they join it. So it is the league's name, in the display face, with who runs
  // it and how many are already in.
  Widget _buildSubtitle() {
    if (_inviteLeagueName != null) {
      final List<String> facts = [
        if (_inviteOrganiser != null) 'Organised by $_inviteOrganiser',
        if (_invitePlayerCount != null)
          '$_invitePlayerCount ${_invitePlayerCount == 1 ? 'player' : 'players'} so far',
      ];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_inviteLeagueName!, style: AppType.t(AppType.display)),
          if (facts.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              facts.join(' · '),
              style: AppType.b(AppType.body, color: AppPalette.slate),
            ),
          ],
        ],
      );
    }

    // Still looking it up. Say nothing rather than flash a message and replace it.
    if (_loadingPreview) {
      return const SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    // Arrived by link but the lookup failed. The Join button still works - the league
    // key came from the link, not from the lookup - so say what we can and let them
    // press it.
    if (_arrivedFromLink) {
      return Text(
        'We could not load the details, but the invitation is good. Tap Join.',
        style: AppType.b(AppType.body, color: AppPalette.slate),
      );
    }

    return Text(
      'Ask whoever set it up for the four-digit code.',
      style: AppType.b(AppType.body, color: AppPalette.slate),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The Join button is live when there is something to join with, and no join is
    // already running. On the typed route that means four digits; on the link route the
    // identifier was there before the screen was, so the only question is whether the
    // league can be joined at all.
    final bool canPressJoin =
        !_isLoading &&
        _canJoin &&
        (_arrivedFromLink ? !_loadingPreview : _typedCode.length == 4);

    return Scaffold(
      backgroundColor: AppPalette.chalk,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('Join a league'),
        backgroundColor: AppPalette.surface,
        shape: const Border(bottom: BorderSide(color: AppPalette.hairline)),
      ),

      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
          children: [
            Text(_title, style: AppType.b(AppType.eyebrow)),
            const SizedBox(height: 10),

            _buildSubtitle(),

            // The code boxes, on the typed route ONLY.
            //
            // Somebody who followed a link has no code and never needs one, so there is
            // nothing here for them to look at or get wrong. This is the difference the
            // share slug was built to make.
            if (!_arrivedFromLink) ...[
              const SizedBox(height: 32),
              PinInput(
                onCompleted: _onPinCompleted,
                pinLength: 4,
                autoFocus: true,
              ),
            ],

            // A league that has already started cannot be joined. Say so plainly
            // instead of offering a button the server will refuse.
            if (!_canJoin) ...[
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppPalette.amberTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _inviteOrganiser != null
                      ? 'This league has already started, so nobody else can join. '
                          'Ask $_inviteOrganiser to add you next time.'
                      : 'This league has already started, so nobody else can join. '
                          'Ask the organiser to add you next time.',
                  style: AppType.b(
                    AppType.body,
                    color: AppPalette.amber,
                    size: 14,
                  ),
                ),
              ),
            ],

            if (_errorMessage != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppPalette.clayTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _errorMessage!,
                  style: AppType.b(
                    AppType.body,
                    color: AppPalette.clay,
                    size: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),

      // The button sits in a fixed bar rather than in the scroll, so that on the link
      // route - where the screen is three lines long - it is under the thumb instead of
      // floating in the middle of an empty card.
      bottomNavigationBar:
          !_canJoin
              ? null
              : Container(
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
                          _isLoading
                              ? 'Joining'
                              : (_inviteIsMember ? 'Open the league' : 'Join'),
                      busy: _isLoading,
                      onPressed: canPressJoin ? _handleJoinLeague : null,
                    ),
                  ),
                ),
              ),
    );
  }
}
