/*
What a league wants from you, in one short line.

This exists because of a specific observed problem: people register, create a league, and
leave. Looking at the old dashboard explains why. A league card said the name and "1
player", and that was all - so a brand new league, which is the exact moment somebody
needs telling what to do, said nothing at all.

Every card now carries a line derived from the league's actual state, and it always names
the next step rather than describing the situation. "1 player · invite people to join"
rather than "1 player". The list then reads as a set of things to do, which is what it
really is.

The wording is deliberately different for the organiser and for everybody else, because
the next step genuinely is different: only the organiser can start a league, so telling a
member to start one would be a dead end.

`unplayed_count` comes from get_user_leagues. An app talking to a server that predates the
field gets null, and the line falls back to the player count - so this is safe whichever
order the two sides deploy in.
*/

import 'league_stage.dart';

class LeaguePrompt {
  // The line shown under the league name on a dashboard card.
  static String forLeague(Map<String, dynamic> league) {
    final LeagueStage stage = LeagueStageInfo.fromLeague(league);
    final int players = _asInt(league['player_count']) ?? 0;
    final bool isCreator = league['is_creator'] == true;

    final String playerText = players == 1 ? '1 player' : '$players players';

    if (stage == LeagueStage.setup) {
      // A league of one is a league that has not really been created yet. This is
      // the drop-off point, so the line is an instruction, not a description.
      if (players <= 1) {
        return isCreator
            ? 'Just you so far · invite people'
            : 'Waiting for players';
      }

      return isCreator
          ? '$playerText · ready to start'
          : '$playerText · waiting to start';
    }

    // In play. The useful number is how many games still need a result.
    final int? unplayed = _asInt(league['unplayed_count']);

    if (unplayed == null) {
      // Older server. Say something true rather than guessing.
      return playerText;
    }

    if (unplayed == 0) {
      return '$playerText · all results in';
    }

    return unplayed == 1 ? '1 result to enter' : '$unplayed results to enter';
  }

  // True when the league is actively asking for something. The dashboard uses this
  // to mark the card, so a glance down the list finds the ones that need attention.
  static bool needsAttention(Map<String, dynamic> league) {
    final LeagueStage stage = LeagueStageInfo.fromLeague(league);
    final bool isCreator = league['is_creator'] == true;

    if (stage == LeagueStage.setup) {
      // Only the organiser can do anything about a league still being set up.
      return isCreator;
    }

    final int? unplayed = _asInt(league['unplayed_count']);
    return unplayed != null && unplayed > 0;
  }

  // The API sends these as numbers, but a league map assembled locally as the user
  // navigates can carry a string. Parse defensively rather than crash a list.
  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
