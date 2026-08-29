/*
Sharing a league link

One place that builds the shared message, so the invite an organiser sends from the league
details screen and the one they send from the player list cannot drift apart.

The link is always the read-only web page at /l/<code> - standings and fixtures, no login and
no app install needed. On a phone that has the app, the operating system opens it in the app
instead of a browser and the join code is filled in automatically.
*/

import 'package:share_plus/share_plus.dart';

import 'config.dart';

class ShareHelper {
  // Share a league, wording it for what the recipient can actually do
  //
  // The same link does two different jobs depending on whether the league has started:
  //
  //   Not started - an INVITATION. There is no table worth looking at yet; what the organiser
  //                 needs is players.
  //   Started     - a SCOREBOARD. Nobody new can join once fixtures exist (join_league.js
  //                 returns FIXTURES_EXIST), so inviting somebody at that point would walk
  //                 them through install and register only to be refused at the end.
  //
  // Built from Config.baseUrl, so a debug build pointed at the test VPS shares a test link
  // rather than a production one.
  static Future<void> shareLeague({
    required String? code,
    required String? name,
    required bool hasFixtures,
  }) async {
    final String leagueCode = code?.toString() ?? '';
    final String leagueName = name?.toString() ?? 'our league';

    // Nothing sensible to share without a code
    if (leagueCode.isEmpty) {
      return;
    }

    final String url = '${Config.baseUrl}/l/$leagueCode';

    final String message = hasFixtures
        ? '$leagueName - live table and results:\n$url'
        : 'Join my league on SplitLeague - $leagueName:\n$url';

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        subject: leagueName,
      ),
    );
  }
}
