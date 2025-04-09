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
    // Get league data
    final String name = league['name'] ?? 'Unnamed League';
    final bool isCreator = league['is_creator'] ?? false;
    final bool isActive = league['active'] ?? false;
    final String publicCode = league['public_code'] ?? '';

    // Get points data
    final Map<String, dynamic> points = league['points'] ?? {};
    final int pointsForWin = points['points_for_win'] ?? 3;
    final int pointsForDraw = points['points_for_draw'] ?? 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // League header with status indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppStyles.primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isCreator)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppStyles.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Creator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? AppStyles.successColor : Colors.grey,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // League details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Points system
                  Row(
                    children: [
                      _buildPointsItem('Win', pointsForWin.toString()),
                      const SizedBox(width: 16),
                      _buildPointsItem('Draw', pointsForDraw.toString()),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // League code
                  Row(
                    children: [
                      const Icon(
                        Icons.key,
                        size: 16,
                        color: AppStyles.secondaryTextColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'League Code: $publicCode',
                        style: const TextStyle(
                          color: AppStyles.secondaryTextColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build points item
  Widget _buildPointsItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppStyles.secondaryTextColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppStyles.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
