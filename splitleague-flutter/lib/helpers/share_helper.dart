/*
Sharing a league link

One place that builds the shared message, so the invite an organiser sends from the league
details screen and the one they send from the player list cannot drift apart.

The link is always the read-only web page at /l/<share_slug> - standings and fixtures, no login
and no app install needed. On a phone that has the app, the operating system opens it in the app
instead of a browser, and the app takes the person straight to the invite.

Why the slug and not the 4-digit code:

  The code is what people say out loud - "join with 1231" - and it is rotated when a league is
  reset, so it is not a stable address. The share slug is generated once when the league is
  created and never changes, so a link sent in a group chat months ago still resolves to the
  right league. The code is also only 4 digits, which made every league page guessable; the slug
  is not. See splitleague-server/utils/share_slug_utils.js.
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
    required String? shareSlug,
    required String? name,
    required bool hasFixtures,
  }) async {
    final String slug = shareSlug?.toString() ?? '';
    final String leagueName = name?.toString() ?? 'our league';

    // Nothing sensible to share without a slug
    //
    // Every league has one - the column is NOT NULL - so an empty slug here means the league
    // details in hand came from somewhere that did not ask the server for it. Sharing the
    // 4-digit code instead would look like it worked while quietly handing out the fragile
    // link the slug exists to replace, so it is better to do nothing at all.
    if (slug.isEmpty) {
      return;
    }

    final String url = '${Config.baseUrl}/l/$slug';

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
