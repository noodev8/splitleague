import 'package:flutter/material.dart';
import '../widgets/error_display.dart';
import '../widgets/skeleton_loading.dart';
import '../helpers/animation_helper.dart';
import '../helpers/accessibility_helper.dart';

class StandingsTabContent extends StatelessWidget {
  final bool isLoadingStandings;
  final List<Map<String, dynamic>> standings;
  final String? standingsErrorMessage;
  final String? winType;
  final Function() onLoadStandings;

  const StandingsTabContent({
    super.key,
    required this.isLoadingStandings,
    required this.standings,
    required this.standingsErrorMessage,
    required this.winType,
    required this.onLoadStandings,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Loading indicator
        if (isLoadingStandings)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: SkeletonStandingsTable(rowCount: 6),
          )
        // Error message
        else if (standingsErrorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ErrorDisplay(
              message: standingsErrorMessage!,
              onRetry: onLoadStandings,
              retryText: 'Refresh Standings',
            ),
          )
        // Empty standings
        else if (standings.isEmpty)
          EmptyStateDisplay(
            message: 'No Standings Yet\nStandings will appear once matches have been played',
            icon: Icons.leaderboard,
            actionText: 'Refresh',
            onAction: onLoadStandings,
          )
        // Standings table
        else
          AnimatedCard(
            elevation: 2,
            borderRadius: BorderRadius.circular(12),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 24), // Position column
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Player',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 30,
                        child: Text(
                          'P',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (winType != 'WIN') ...[
                        SizedBox(
                          width: 30,
                          child: Text(
                            'W',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        if (winType == 'WDL')
                          SizedBox(
                            width: 30,
                            child: Text(
                              'D',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        SizedBox(
                          width: 30,
                          child: Text(
                            'L',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                      // Bonus column for PTS type
                      if (winType == 'PTS')
                        SizedBox(
                          width: 30,
                          child: Text(
                            'B',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      // Points column
                      SizedBox(
                        width: 40,
                        child: Text(
                          winType == 'WIN' ? 'Won' : 'Pts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Table rows with staggered animation
                Column(
                  children: List.generate(standings.length, (index) {
                    final player = standings[index];
                    final position = index + 1;
                    final isCurrentUser = player['is_current_user'] == true;

                    // Create semantic label for screen readers
                    final String semanticLabel = AccessibilityHelper.getStandingsRowLabel(player, position, winType);

                    return FadeSlideAnimation(
                      duration: Duration(milliseconds: 300 + index * 50),
                      curve: AnimCurves.decelerate,
                      beginOffset: const Offset(0.0, 0.25),
                      beginOpacity: 0.0,
                      child: Semantics(
                        label: semanticLabel,
                        child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: BoxDecoration(
                          color: isCurrentUser ? Colors.blue.withAlpha(20) : null,
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.shade200,
                              width: 1.0,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            // Position
                            SizedBox(
                              width: 24,
                              child: Text(
                                '$position',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: position <= 3 ? Colors.blue : Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // Player name
                            Expanded(
                              flex: 3,
                              child: Text(
                                player['nickname'] ?? player['name'] ?? 'Unknown',
                                style: TextStyle(
                                  fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.normal,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            // Played
                            SizedBox(
                              width: 30,
                              child: Text(
                                '${player['played'] ?? 0}',
                                textAlign: TextAlign.center,
                              ),
                            ),
                            // Won, Draw, Lost columns (only for WDL and PTS)
                            if (winType != 'WIN') ...[
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '${player['won'] ?? 0}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.green,
                                  ),
                                ),
                              ),
                              if (winType == 'WDL')
                                SizedBox(
                                  width: 30,
                                  child: Text(
                                    '${player['drawn'] ?? 0}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Colors.amber.shade700,
                                    ),
                                  ),
                                ),
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '${player['lost'] ?? 0}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                            // Bonus points for PTS type
                            if (winType == 'PTS')
                              SizedBox(
                                width: 30,
                                child: Text(
                                  '${player['bonus_points'] ?? 0}',
                                  style: TextStyle(
                                    color: (player['bonus_points'] ?? 0) > 0 ? Colors.purple : Colors.grey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            // Points
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${player['points'] ?? 0}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
