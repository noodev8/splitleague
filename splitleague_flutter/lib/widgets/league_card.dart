/*
Widget for displaying a league card
Used in the dashboard to show leagues the user is a member of
*/

import 'package:flutter/material.dart';
import '../styles/app_styles.dart';

class LeagueCard extends StatelessWidget {
  final Map<String, dynamic> league;
  final VoidCallback? onTap;

  const LeagueCard({
    super.key,
    required this.league,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Get league data using league_id instead of id where needed
    final String name = league['name'] ?? 'Unnamed League';
    final bool isCreator = league['is_creator'] ?? false;
    final bool isActive = league['active'] ?? false;
    final int playerCount = league['player_count'] ?? 0;

    return Card(
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
                        ),
                        const SizedBox(width: 4),
                        Row(
                          children: [
                            Text(
                              '$playerCount ${playerCount == 1 ? 'player' : 'players'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppStyles.secondaryTextColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: isActive ? AppStyles.successColor.withAlpha(25) : Colors.grey.withAlpha(25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isActive ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? AppStyles.successColor : Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Status indicators
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isCreator)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor.withAlpha(30),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Organiser',
                        style: TextStyle(
                          color: AppStyles.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    color: AppStyles.secondaryTextColor,
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
