import 'package:flutter/material.dart';
// import '../widgets/error_display.dart';

class DetailsTabContent extends StatelessWidget {
  final Map<String, dynamic> leagueInfo;
  final bool hasFixtures;
  final Function(String?) onCopyToClipboard;
  final String Function(String?) formatDate;
  final String Function(String?) getPointsTypeDisplay;
  final Function(String)? onEditLeagueName;
  final Function()? onResetScores;
  final Function()? onCopyLeague;

  const DetailsTabContent({
    super.key,
    required this.leagueInfo,
    required this.hasFixtures,
    required this.onCopyToClipboard,
    required this.formatDate,
    required this.getPointsTypeDisplay,
    this.onEditLeagueName,
    this.onResetScores,
    this.onCopyLeague,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // League info card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // League name and PIN
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.sports_soccer,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'League Name',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  leagueInfo['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              // Edit button - only visible to the creator
                              if (leagueInfo['is_creator'] == true && onEditLeagueName != null)
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  tooltip: 'Edit league name',
                                  onPressed: () => _showEditNameDialog(context),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (!hasFixtures) ...[
                      // Only show the code if user is creator OR allow_code_share is true
                      if (leagueInfo['is_creator'] == true || leagueInfo['allow_code_share'] == true) ...[
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: InkWell(
                            onTap: () => onCopyToClipboard(leagueInfo['public_code']),
                            child: Row(
                              children: [
                                Text(
                                  leagueInfo['public_code'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.copy,
                                  color: Colors.blue,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(25),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Started',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Organizer
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Organiser',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          leagueInfo['created_by_nickname'] ?? leagueInfo['created_by']?.toString() ?? 'Unknown',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Points Type
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Points Type',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          getPointsTypeDisplay(leagueInfo['win_type']),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Created at
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withAlpha(25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.history,
                        color: Colors.blue,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Created On',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          formatDate(leagueInfo['created_at']),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Reset Scores button - only visible to the organizer and only if fixtures exist
        if (leagueInfo['is_creator'] == true && hasFixtures && onResetScores != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onResetScores,
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('Reset All Scores'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Copy League button - only visible to the organizer and only if fixtures exist
        if (leagueInfo['is_creator'] == true && hasFixtures && onCopyLeague != null) ...[
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onCopyLeague,
              icon: const Icon(Icons.copy, color: Colors.white),
              label: const Text('Copy League'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Points rules section
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.withAlpha(50)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Points rules list
                Column(
                  children: [
                    // Win points
                    _buildPointsCard(
                      'Win',
                      '${leagueInfo['points_for_win'] ?? 0}',
                      Icons.emoji_events,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),

                    // Draw points (only for WDL)
                    if (leagueInfo['win_type'] == 'WDL') ...[
                      _buildPointsCard(
                        'Draw',
                        '${leagueInfo['points_for_draw'] ?? 0}',
                        Icons.handshake,
                        Colors.blue,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Win margin bonus
                    _buildPointsCard(
                      'Win Margin Bonus',
                      '${leagueInfo['points_for_win_margin'] ?? 0}',
                      Icons.add_circle,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),

                    // Close loss points
                    _buildPointsCard(
                      'Lose within margin',
                      '${leagueInfo['points_for_close_loss'] ?? 0}',
                      Icons.remove_circle,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),

                    // Margin threshold
                    _buildPointsCard(
                      'Margin Threshold',
                      '${leagueInfo['win_margin_threshold'] ?? 0}',
                      Icons.speed,
                      Colors.blue,
                    ),
                    const SizedBox(height: 12),

                    // Play each other
                    _buildPointsCard(
                      'Play Each Other',
                      '${leagueInfo['play_each_other'] ?? 1} time${leagueInfo['play_each_other'] == 1 ? '' : 's'}',
                      Icons.repeat,
                      Colors.blue,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build points rule card
  Widget _buildPointsCard(String label, String value, IconData icon, Color color) {
    return Container(
      width: double.infinity, // Make container take full width
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: color.withAlpha(200),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Show dialog to edit league name
  void _showEditNameDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController(text: leagueInfo['name'] ?? '');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit League Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'League Name',
              hintText: 'Enter new league name',
            ),
            maxLength: 30,
            textCapitalization: TextCapitalization.sentences,
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isNotEmpty && newName != leagueInfo['name']) {
                  Navigator.of(context).pop();
                  onEditLeagueName?.call(newName);
                } else if (newName.isEmpty) {
                  // Show error for empty name
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('League name cannot be empty')),
                  );
                } else {
                  // Name is unchanged, just close the dialog
                  Navigator.of(context).pop();
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
