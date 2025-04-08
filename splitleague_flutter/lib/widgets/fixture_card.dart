/*
Widget for displaying a fixture card
Used in the fixtures screen to show match details
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class FixtureCard extends StatelessWidget {
  final Map<String, dynamic> fixture;
  final VoidCallback? onTap;

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

    // Format date if available
    String? scheduledDate;
    if (fixture['scheduled_date'] != null) {
      final date = DateTime.parse(fixture['scheduled_date']);
      scheduledDate = '${date.day}/${date.month}/${date.year}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status and date
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Status indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: played ? AppStyles.successColor : Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      played ? 'Played' : 'Upcoming',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

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
              const SizedBox(height: 16),

              // Players and scores
              Row(
                children: [
                  // Player 1
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player1Nickname.isNotEmpty ? player1Nickname : player1Name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Scores or VS
                  if (played && player1Score != null && player2Score != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor.withAlpha(25), // 0.1 opacity
                        borderRadius: BorderRadius.circular(8),
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
                        Text(
                          player2Nickname.isNotEmpty ? player2Nickname : player2Name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
