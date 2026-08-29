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
import 'package:flutter_spinkit/flutter_spinkit.dart';
import '../api/join_league_api.dart';
import '../api/get_league_preview_api.dart';
import '../helpers/auth_helper.dart';
import '../widgets/pin_input.dart';
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

  const JoinLeagueScreen({
    super.key,
    this.onLeagueJoined,
    this.leagueKey,
  });

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
          _invitePlayerCount = response['player_count'] is int
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
        _errorMessage = 'Please enter a valid 4-digit code';
      });
      return;
    }

    // Check if user is in guest mode
    final isGuest = await AuthHelper.getUserData().then((userData) =>
      userData == null || userData['nickname'] == 'Guest');

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
            'Registration is free and only takes a minute.'
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
                  MaterialPageRoute(builder: (context) => const LoginUserScreen()),
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
                  MaterialPageRoute(builder: (context) => const RegisterUserScreen()),
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

    return 'Join a League';
  }

  // The line under the title
  Widget _buildSubtitle() {
    // We know the league - say what it is and who runs it
    if (_inviteLeagueName != null) {
      return Column(
        children: [
          Text(
            _inviteLeagueName!,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005F8A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            [
              if (_inviteOrganiser != null) 'Organised by $_inviteOrganiser',
              if (_invitePlayerCount != null)
                '$_invitePlayerCount ${_invitePlayerCount == 1 ? 'player' : 'players'} so far',
            ].join('\n'),
            style: const TextStyle(
              fontSize: 15,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    // Still looking it up - say nothing rather than flash a message and replace it
    if (_loadingPreview) {
      return const SizedBox(
        height: 24,
        child: SpinKitThreeBounce(color: Colors.blue, size: 18),
      );
    }

    // Arrived by link but the lookup failed. The Join button still works - the league key came
    // from the link, not from the lookup - so say what we can and let them press it.
    if (_arrivedFromLink) {
      return const Text(
        'Tap Join League to join the league you were invited to.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
        textAlign: TextAlign.center,
      );
    }

    // The typed route
    return const Text(
      'Enter the 4-digit code provided by the league creator to join.',
      style: TextStyle(fontSize: 16, color: Colors.grey),
      textAlign: TextAlign.center,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the bottom inset (keyboard height)
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // The Join button is live when there is something to join with, and no join is already
    // running. On the typed route that means four digits; on the link route the identifier was
    // there before the screen was, so the only question is whether the league can be joined.
    final bool canPressJoin = !_isLoading &&
        _canJoin &&
        (_arrivedFromLink ? !_loadingPreview : _typedCode.length == 4);

    return Scaffold(
      // This ensures the body resizes when the keyboard appears
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF005F8A),
        elevation: 0,
        title: const Text('Join League'),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
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
        child: SafeArea(
          bottom: false, // Allow content to extend to the bottom edge
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              // Add padding at the bottom to ensure content is visible above keyboard
              padding: EdgeInsets.fromLTRB(
                16.0,
                24.0,
                16.0,
                bottomInset > 0 ? bottomInset + 20 : 24.0
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Card for join league content
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 32,
                    ),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            // Icon in a circle
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.blue.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.group_add,
                                size: 40,
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            Text(
                              _title,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            _buildSubtitle(),

                            const SizedBox(height: 40),

                            // The code boxes, on the typed route ONLY
                            //
                            // Somebody who followed a link has no code and never needs one, so
                            // there is nothing here for them to look at or get wrong. This is
                            // the difference the share slug was built to make.
                            if (!_arrivedFromLink) ...[
                              PinInput(
                                onCompleted: _onPinCompleted,
                                pinLength: 4,
                                autoFocus: true,
                              ),
                              const SizedBox(height: 32),
                            ],

                            // A league that has already started cannot be joined
                            //
                            // Say so plainly instead of offering a button that the server will
                            // refuse. This is the same wording as the public web page.
                            if (!_canJoin) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _inviteOrganiser != null
                                      ? 'This league has already started, so new players cannot join. Ask $_inviteOrganiser.'
                                      : 'This league has already started, so new players cannot join. Ask the organiser.',
                                  style: const TextStyle(color: Colors.black87),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Join button
                            //
                            // Disabled until there is something to join with, and while a join
                            // is in flight, so it cannot be pressed twice.
                            if (_canJoin)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: canPressJoin ? _handleJoinLeague : null,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF005F8A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    _inviteIsMember ? 'Open League' : 'Join League',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 24),

                            // Error message
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.withAlpha(25),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_errorMessage != null) const SizedBox(height: 24),

                            // Loading indicator
                            if (_isLoading)
                              Container(
                                margin: const EdgeInsets.only(top: 24),
                                child: const SpinKitThreeBounce(
                                  color: Colors.blue,
                                  size: 24,
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
          ),
        ),
      ),
    );
  }
}
