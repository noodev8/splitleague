import 'package:flutter/material.dart';
import '../widgets/error_display.dart';

class EmptyStateDisplay extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? actionText;
  final Function()? onAction;

  const EmptyStateDisplay({
    super.key,
    required this.message,
    required this.icon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
            if (actionText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StandingsTabContent extends StatefulWidget {
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
  State<StandingsTabContent> createState() => _StandingsTabContentState();
}

class _StandingsTabContentState extends State<StandingsTabContent> {
  @override
  void initState() {
    super.initState();
    // No forced reload - we rely on the provider's initialization
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Loading indicator
        if (widget.isLoadingStandings)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading standings...',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          )
        // Error message
        else if (widget.standingsErrorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: ErrorDisplay(
              message: widget.standingsErrorMessage!,
              onRetry: widget.onLoadStandings,
              retryText: 'Refresh Standings',
            ),
          )
        // Empty standings
        else if (widget.standings.isEmpty)
          EmptyStateDisplay(
            message: 'No Standings Yet\nStandings will appear once matches have been played',
            icon: Icons.leaderboard,
            actionText: 'Refresh',
            onAction: widget.onLoadStandings,
          )
        // Standings table
        else
          _buildStandingsTable(),
      ],
    );
  }

  Widget _buildStandingsTable() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Table header
            _buildTableHeader(),
            const SizedBox(height: 8),
            // Table rows
            ...List.generate(
              widget.standings.length,
              (index) => _buildTableRow(widget.standings[index], index + 1),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
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
          if (widget.winType != 'WIN') ...[
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
            if (widget.winType == 'WDL')
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
          if (widget.winType == 'PTS')
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
              widget.winType == 'WIN' ? 'Won' : 'Pts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> player, int position) {
    final isCurrentUser = player['is_current_user'] == true;

    return Container(
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
          if (widget.winType != 'WIN') ...[
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
            if (widget.winType == 'WDL')
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
          if (widget.winType == 'PTS')
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
    );
  }
}
