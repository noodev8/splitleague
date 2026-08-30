/*
One league, on the dashboard.

The old card showed the league name, a player count and a stage chip. All true, none of
it actionable - so a list of leagues was a list of names, and a brand new league with one
player said nothing about what to do next. That is the screen people were leaving from.

Three changes:

  1. The line under the name is now the next step, not a description. See
     helpers/league_prompt.dart - "Just you so far · invite people" instead of
     "1 player".

  2. A league that wants something from you carries a coloured rule down its left
     edge, in the stage colour. Scanning the list finds the live ones without
     reading a word. A league with nothing outstanding keeps the plain card.

  3. The stage chip is gone. It was saying the same thing as the prompt line in
     worse words, and two badges saying one thing was the confusion. The rule
     carries the stage colour instead.
*/

import 'package:flutter/material.dart';
import '../helpers/accessibility_helper.dart';
import '../helpers/league_prompt.dart';
import '../helpers/league_stage.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';

class LeagueCard extends StatelessWidget {
  final Map<String, dynamic> league;
  final VoidCallback? onTap;
  final Function(int)? onRemove;

  const LeagueCard({
    super.key,
    required this.league,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final String name = league['name'] ?? 'Unnamed League';
    final String prompt = LeaguePrompt.forLeague(league);
    final bool attention = LeaguePrompt.needsAttention(league);

    // Null when the server never told us the stage. The rule then stays neutral
    // rather than colouring a league we know nothing about.
    final LeagueStage? stage = LeagueStageInfo.knownFromLeague(league);

    // A league with nothing outstanding gets a hairline, not a grey bar. If every
    // card carried a visible rule the colour would stop meaning "this one wants
    // something", which is the only thing it is there to say.
    final Color rule =
        (stage != null && attention)
            ? LeagueStageInfo.colour(stage)
            : AppPalette.hairline;

    final String semanticLabel =
        '${AccessibilityHelper.getLeagueLabel(league)}. $prompt';

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      enabled: onTap != null,
      excludeSemantics: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppPalette.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // The rule. Four pixels of stage colour is the whole badge now.
                  Container(width: 4, color: rule),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 4, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            name,
                            style: AppType.t(AppType.title),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            prompt,
                            style: AppType.b(
                              AppType.meta,
                              // The prompt takes the stage colour only when the
                              // league actually wants something. Colouring every
                              // line would make the colour meaningless.
                              color:
                                  attention && stage != null
                                      ? LeagueStageInfo.colour(stage)
                                      : AppPalette.slate,
                            ).copyWith(
                              fontWeight:
                                  attention ? FontWeight.w600 : FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (onRemove != null)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      tooltip: 'League options',
                      icon: Icon(
                        Icons.more_vert,
                        color: AppPalette.slate.withValues(alpha: 0.8),
                        size: 20,
                      ),
                      itemBuilder:
                          (context) => [
                            PopupMenuItem<String>(
                              value: 'remove',
                              child: Text(
                                'Hide from my leagues',
                                style: AppType.b(
                                  AppType.action,
                                  color: AppPalette.clay,
                                ),
                              ),
                            ),
                          ],
                      onSelected: (value) {
                        if (value == 'remove') {
                          onRemove!(league['league_id']);
                        }
                      },
                    )
                  else
                    const SizedBox(width: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
