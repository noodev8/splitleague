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
    final String name = league['name'] ?? 'Unnamed League';
    final int playerCount = league['player_count'] ?? 0;
    final String semanticLabel = AccessibilityHelper.getLeagueLabel(league);

    return Semantics(
      label: semanticLabel,
      button: onTap != null,
      enabled: onTap != null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppStyles.iceLightBlue.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppStyles.iceDarkBlue.withOpacity(0.08),
              offset: const Offset(0, 2),
              blurRadius: 4,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  // League info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppStyles.iceDarkBlue,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 16,
                              color: AppStyles.iceDarkBlue.withOpacity(0.7),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$playerCount ${playerCount == 1 ? 'player' : 'players'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppStyles.iceDarkBlue.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Menu button
                  if (onRemove != null)
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(
                        Icons.more_vert,
                        color: AppStyles.iceDarkBlue.withOpacity(0.7),
                        size: 20,
                      ),
                      itemBuilder: (context) => [
                        PopupMenuItem<String>(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, 
                                size: 18, 
                                color: AppStyles.errorColor.withOpacity(0.8)
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remove from Dashboard',
                                style: TextStyle(
                                  color: AppStyles.errorColor.withOpacity(0.8)
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      onSelected: (value) {
                        if (value == 'remove') {
                          onRemove!(league['league_id']);
                        }
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
