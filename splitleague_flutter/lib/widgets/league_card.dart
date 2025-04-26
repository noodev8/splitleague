/*
Widget for displaying a league card
Used in the dashboard to show leagues the user is a member of
*/

import 'package:flutter/material.dart';
import '../helpers/accessibility_helper.dart';
import '../styles/app_styles.dart';

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
    // Get league data using league_id instead of id where needed
    final String name = league['name'] ?? 'Unnamed League';
    // final bool isCreator = league['is_creator'] ?? false;
    final int playerCount = league['player_count'] ?? 0;

    // Create semantic label for screen readers
    final String semanticLabel = AccessibilityHelper.getLeagueLabel(league);

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      enabled: onTap != null,
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 1,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              children: [
                // League name and player count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.people,
                            size: 14,
                            color: AppStyles.secondaryTextColor,
                            semanticLabel: 'Players',
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$playerCount ${playerCount == 1 ? 'player' : 'players'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppStyles.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Status indicators and menu
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // // Show star icon for league creator
                    // if (isCreator)
                    //   Semantics(
                    //     label: 'You are the organizer of this league',
                    //     child: Container(
                    //       margin: const EdgeInsets.only(right: 8),
                    //       child: const Icon(
                    //         Icons.star,
                    //         color: Colors.amber,
                    //         size: 20,
                    //       ),
                    //     ),
                    //   ),

                    // Show remove option for all users
                    if (onRemove != null)
                      Semantics(
                        label: 'More options',
                        button: true,
                        child: PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.more_vert,
                            color: AppStyles.secondaryTextColor,
                            size: 20,
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem<String>(
                              value: 'remove',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Remove from Dashboard',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) {
                            if (value == 'remove' && onRemove != null) {
                              onRemove!(league['league_id']);
                            }
                          },
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
