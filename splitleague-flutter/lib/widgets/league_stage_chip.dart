/*
A small badge saying which stage a league is in - "Setting up" or "In play".

Used on the dashboard league cards, so that the list of leagues answers the question
"which of these has actually started?" without having to open each one.
*/

import 'package:flutter/material.dart';
import '../helpers/league_stage.dart';

class LeagueStageChip extends StatelessWidget {
  final LeagueStage stage;

  // Compact drops the icon and tightens the padding, for use inside a crowded row.
  final bool compact;

  const LeagueStageChip({
    super.key,
    required this.stage,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color colour = LeagueStageInfo.colour(stage);
    final Color background = LeagueStageInfo.background(stage);
    final String label = LeagueStageInfo.label(stage);

    return Semantics(
      // Read out as a sentence, because "In play" on its own is meaningless to a
      // screen reader user who cannot see it sitting under a league name.
      label: 'League stage: $label',
      excludeSemantics: true,

      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6 : 8,
          vertical: compact ? 2 : 3,
        ),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colour.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!compact) ...[
              Icon(LeagueStageInfo.icon(stage), size: 12, color: colour),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colour,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
