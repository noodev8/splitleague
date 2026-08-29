/*
The strip that sits directly under the tab row on every league screen and says, in plain
words, which stage the league is in and what you can do in it.

Every league screen shows the same strip in the same place, so wherever you land - players,
fixtures, standings, details - the answer to "where am I in this league?" is in one fixed
spot and phrased identically.
*/

import 'package:flutter/material.dart';
import '../helpers/league_stage.dart';

class LeagueStageBanner extends StatelessWidget {
  final LeagueStage stage;

  const LeagueStageBanner({
    super.key,
    required this.stage,
  });

  @override
  Widget build(BuildContext context) {
    final Color colour = LeagueStageInfo.colour(stage);
    final Color background = LeagueStageInfo.background(stage);
    final String label = LeagueStageInfo.label(stage);
    final String description = LeagueStageInfo.description(stage);

    return Semantics(
      label: 'League stage: $label. $description',
      excludeSemantics: true,

      child: Container(
        width: double.infinity,
        color: background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              // Nudged down so the icon sits on the first line of text rather than
              // floating above it when the text wraps to two lines.
              padding: const EdgeInsets.only(top: 1),
              child: Icon(LeagueStageInfo.icon(stage), size: 16, color: colour),
            ),
            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: colour,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      // Darkened rather than greyed, so it still passes contrast against
                      // the tinted background in high contrast mode.
                      color: colour.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
