/*
Widget for displaying a fixture card
Used in the fixtures screen to show match details
*/

import 'package:flutter/material.dart';
import '../helpers/animation_helper.dart';
import '../helpers/accessibility_helper.dart';
import '../styles/app_styles.dart';

class FixtureCard extends StatelessWidget {
  final Map<String, dynamic> fixture;
  final void Function(Map<String, dynamic>)? onTap;

  const FixtureCard({
    super.key,
    required this.fixture,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get fixture data
    final bool played = fixture['played'] ?? false;
    final player1Name = fixture['player_1_name'] ?? 'Unknown';
    final player2Name = fixture['player_2_name'] ?? 'Unknown';
    final player1Nickname = fixture['player_1_nickname'] ?? '';
    final player2Nickname = fixture['player_2_nickname'] ?? '';
    final player1Score = fixture['player_1_score'];
    final player2Score = fixture['player_2_score'];

    // Determine winner and if margin bonus applies
    bool player1IsWinner = false;
    bool player2IsWinner = false;
    bool player1HasMarginBonus = false;
    bool player2HasMarginBonus = false;
    bool player1HasCloseLossBonus = false;
    bool player2HasCloseLossBonus = false;

    if (played && player1Score != null && player2Score != null) {
      // Get league settings
      final int marginThreshold = fixture['win_margin_threshold'] ?? 0;
      final int pointsForWinMargin = fixture['points_for_win_margin'] ?? 0;
      final int pointsForCloseLoss = fixture['points_for_close_loss'] ?? 0;

      // Calculate score difference
      final int scoreDifference = player1Score - player2Score;

      // Determine winner and bonuses
      if (scoreDifference > 0) {
        // Player 1 wins
        player1IsWinner = true;

        // Check for margin bonus
        if (marginThreshold > 0 && pointsForWinMargin > 0 && scoreDifference >= marginThreshold) {
          player1HasMarginBonus = true;
        }

        // Check for close loss bonus
        if (marginThreshold > 0 && pointsForCloseLoss > 0 && scoreDifference < marginThreshold) {
          player2HasCloseLossBonus = true;
        }
      } else if (scoreDifference < 0) {
        // Player 2 wins
        player2IsWinner = true;

        // Check for margin bonus
        if (marginThreshold > 0 && pointsForWinMargin > 0 && -scoreDifference >= marginThreshold) {
          player2HasMarginBonus = true;
        }

        // Check for close loss bonus
        if (marginThreshold > 0 && pointsForCloseLoss > 0 && -scoreDifference < marginThreshold) {
          player1HasCloseLossBonus = true;
        }
      }
      // If scoreDifference is 0, it's a draw and no bonuses apply
    }

    // Format date if available
    String? scheduledDate;
    if (fixture['scheduled_date'] != null) {
      final date = DateTime.parse(fixture['scheduled_date']);
      scheduledDate = '${date.day}/${date.month}/${date.year}';
    }

    // Create semantic label for screen readers
    final String semanticLabel = AccessibilityHelper.getFixtureLabel(fixture);

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      enabled: onTap != null,
      child: AnimatedCard(
        margin: const EdgeInsets.only(bottom: 4), // Reduced spacing
        borderRadius: BorderRadius.circular(8),
        elevation: 1.5, // Slightly reduced elevation
        // Different background color for played matches
        color: played ? Colors.blue.shade50 : Colors.white,
        onTap: onTap != null ? () => onTap!(fixture) : null,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // Reduced vertical padding
      child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date only
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Scheduled date
                  if (scheduledDate != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppStyles.secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          scheduledDate,
                          style: const TextStyle(
                            color: AppStyles.secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Players and scores
              Row(
                children: [
                  // Player 1
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Player name
                        Text(
                          player1Nickname.isNotEmpty ? player1Nickname : player1Name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: played && player1IsWinner
                                ? Colors.green
                                : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        // Bonus indicator
                        if (played && player1IsWinner && player1HasMarginBonus)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.add_circle,
                                  size: 12,
                                  color: Colors.green,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Bonus',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Close loss indicator
                        if (played && !player1IsWinner && player1HasCloseLossBonus)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.remove_circle,
                                  size: 12,
                                  color: Colors.orange,
                                ),
                                const SizedBox(width: 4),
                                const Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Scores or VS
                  if (played && player1Score != null && player2Score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor.withAlpha(50), // More visible
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppStyles.primaryColor.withAlpha(100)),
                      ),
                      child: Text(
                        '$player1Score - $player2Score',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppStyles.primaryColor,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'VS',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppStyles.secondaryTextColor,
                        ),
                      ),
                    ),

                  // Player 2
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Player name
                        Text(
                          player2Nickname.isNotEmpty ? player2Nickname : player2Name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: played && player2IsWinner
                                ? Colors.green
                                : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                        // Bonus indicator
                        if (played && player2IsWinner && player2HasMarginBonus)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'Bonus',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.green,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.add_circle,
                                  size: 12,
                                  color: Colors.green,
                                ),
                              ],
                            ),
                          ),
                        // Close loss indicator
                        if (played && !player2IsWinner && player2HasCloseLossBonus)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                const Text(
                                  'Close',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.remove_circle,
                                  size: 12,
                                  color: Colors.orange,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
    ),
    );
  }
}
