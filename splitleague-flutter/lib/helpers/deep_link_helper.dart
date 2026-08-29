/*
Deep link handling for the SplitLeague application

Turns a shared league link - https://splitleague.noodev8.com/l/<share_slug> - into a screen
inside the app, instead of dumping the person into a browser.

Nothing here looks at the SHAPE of what comes after /l/. It used to assume four digits, because
the join code was the thing in the URL; it is now a ten character share slug, and old links
carrying a code still exist and still have to work. So the segment is carried through as an
opaque "league key" and the server decides what it is. Do not reintroduce a length check here -
that assumption is what tied joining a league to typing a fourth digit.

Two cases have to be handled, and they are genuinely different:

  1. COLD START. The app was not running. Android hands us the link once, at launch, through
     getInitialLink(). Miss it and it is gone.
  2. ALREADY RUNNING. The app is open in the background. The link arrives on a stream instead.
     The activity is launchMode="singleTop", so Android delivers it to the existing screen
     rather than starting a second copy of the app.

The link may also arrive before the person has logged in, so the key is parked in _pendingKey
and picked up later, once there is somebody to join the league AS.

Nothing here joins a league on its own. A link only ever opens the join screen showing the
league it points at - the person still presses Join. Joining is a real action, and it should not
happen just because somebody tapped a link in a group chat.
*/

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';

import '../screens/join_league_screen.dart';
import 'auth_helper.dart';

class DeepLinkHelper {
  // Navigator key from MaterialApp, so a link can drive navigation from outside the widget tree
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  // The app_links instance, kept alive for the life of the app
  static AppLinks? _appLinks;

  // A league key that arrived before we could act on it - usually because nobody was logged in yet
  static String? _pendingKey;

  // Whether the dashboard is on screen
  //
  // This is what tells us it is safe to push a screen. The splash screen finishes with
  // Navigator.pushReplacement, which replaces whatever is on TOP of the stack - so anything
  // pushed before the splash has finished gets silently swallowed by the dashboard replacing
  // it. That is a real bug that shipped once already: the join screen appeared for a moment,
  // vanished, and the league was never joined.
  static bool _dashboardReady = false;

  // What to run after a league is joined from a link
  //
  // The dashboard registers its own reload here. Without it a league joined from a link does
  // not appear until the list is pulled to refresh - the dashboard sits underneath the join
  // screen and never hears that anything happened.
  static VoidCallback? _onLeagueJoined;

  // The only host we accept links from
  //
  // Deliberately NOT built from Config.baseUrl. The base URL can be pointed at a test VPS or a
  // local machine from the developer screen, and a link should never become openable just
  // because somebody switched environments.
  static const String _linkHost = 'splitleague.noodev8.com';

  // Start listening for links. Called once, from main().
  static Future<void> initialise() async {
    _appLinks = AppLinks();

    // Case 1: the app was launched by a link
    //
    // This runs before runApp, so there is no navigator yet and the splash screen is about to
    // take over the stack. Park the key and let the dashboard collect it - do NOT try to
    // navigate from here.
    try {
      final Uri? initialUri = await _appLinks!.getInitialLink();

      if (initialUri != null) {
        final key = extractLeagueKey(initialUri);

        if (key != null) {
          _pendingKey = key;
        }
      }
    } catch (e) {
      // A malformed launch URI must never stop the app from starting
      debugPrint('Error reading initial deep link: $e');
    }

    // Case 2: the app was already running
    _appLinks!.uriLinkStream.listen(
      (uri) => _handleUri(uri),
      onError: (e) => debugPrint('Error on deep link stream: $e'),
    );
  }

  // Pull the league key out of a link, or return null if this is not a league link
  //
  // The key is whatever sits after /l/ - a ten character share slug in any link built today, a
  // 4-digit code in a link shared before the slug existed. It is passed through untouched and
  // the server decides which it is, so a third shape in future needs no change here.
  //
  // Anything unexpected returns null rather than throwing. These URIs come from outside the
  // app and cannot be trusted to be well formed.
  static String? extractLeagueKey(Uri uri) {
    if (uri.host != _linkHost) {
      return null;
    }

    final segments = uri.pathSegments;

    // We want exactly /l/<key>
    if (segments.length < 2 || segments[0] != 'l') {
      return null;
    }

    final key = segments[1].trim();

    return key.isEmpty ? null : key;
  }

  // Act on a link
  static Future<void> _handleUri(Uri uri) async {
    final key = extractLeagueKey(uri);

    if (key == null) {
      return;
    }

    // Park it first. If anything below cannot run yet, the key survives until the
    // dashboard asks for it after login.
    _pendingKey = key;

    final bool isLoggedIn = await AuthHelper.isLoggedIn();

    if (!isLoggedIn) {
      // Leave it pending - the login flow lands on the dashboard, which will collect it
      return;
    }

    final navigator = navigatorKey.currentState;

    if (navigator == null || !_dashboardReady) {
      // Still starting up, or the splash screen is still on top and about to replace whatever
      // sits above it. Either way the dashboard will collect this in a moment.
      return;
    }

    _openJoinScreen(navigator);
  }

  // Told by the dashboard when it comes and goes
  //
  // Nothing may be pushed before this is true - see the note on _dashboardReady.
  static void setDashboardReady(bool ready) {
    _dashboardReady = ready;
  }

  // Register what should happen once a league is joined from a link
  static void setOnLeagueJoined(VoidCallback? callback) {
    _onLeagueJoined = callback;
  }

  // Take any key that arrived earlier and act on it now
  //
  // Called from the dashboard, which is where both routes into the app end up - a cold start
  // through the splash screen, and a fresh login. Safe to call every time the dashboard
  // builds: the key is cleared as it is used, so it never fires twice.
  static void handlePendingLink(BuildContext context) {
    if (_pendingKey == null) {
      return;
    }

    // Wait for the current build to finish before navigating
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navigator = Navigator.of(context);

      _openJoinScreen(navigator);
    });
  }

  // Push the join screen for the league the link pointed at
  static void _openJoinScreen(NavigatorState navigator) {
    final key = _pendingKey;

    if (key == null) {
      return;
    }

    // Clear before navigating, so a failure here cannot leave the app in a loop
    _pendingKey = null;

    // arrivedFromLink is what turns the join screen from a keypad into an invitation. The
    // person did not type anything to get here and has no code to check, so the screen shows
    // the league instead of asking them for an identifier they never saw.
    navigator.push(
      MaterialPageRoute(
        builder: (context) => JoinLeagueScreen(
          leagueKey: key,
          onLeagueJoined: _onLeagueJoined,
        ),
      ),
    );
  }
}
