/*
The league table.

The table is the reason the app exists - it is the thing people screenshot and send to
each other - so it is the one place the display face is allowed to do the most work.

Changes from the old table:

  * The top three positions were coloured blue and the rest grey, which said "these
    three are special" in a two-player league. Position is now plain, and the only
    thing marked is the row that is you - the one piece of information a person
    scanning a table actually wants first.

  * W, D and L were green, amber and red. Three more colours on a screen that already
    had too many, to label columns whose headers already say what they are. They are
    now all ink, with the points column heavier - because the points column is the
    one that decides the order, and it should be the one that reads loudest.

  * Numbers are tabular figures in the display face, so the columns line up as
    columns rather than drifting as scores change.

Which columns appear still depends on the scoring type, which is right: a Win/Lose league
has no draws, so showing a D column full of zeroes would be noise.
*/

import 'package:flutter/material.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import 'sl_empty.dart';

class StandingsTabContent extends StatelessWidget {
  final bool isLoadingStandings;
  final List<Map<String, dynamic>> standings;
  final String? standingsErrorMessage;
  final String? winType;
  final Function() onLoadStandings;

  // Who is looking at the table, so their own row can be marked.
  //
  // Done here rather than read off the row because the server has never sent an
  // `is_current_user` flag - the old table looked for one, so the highlight it was
  // trying to draw had never appeared for anybody.
  final int? currentUserId;

  const StandingsTabContent({
    super.key,
    required this.isLoadingStandings,
    required this.standings,
    required this.standingsErrorMessage,
    required this.winType,
    required this.onLoadStandings,
    this.currentUserId,
  });

  // Guests are stored with a "guest_" prefix on the nickname; never show it.
  String _formatPlayerName(String name) {
    return name.startsWith('guest_') ? name.substring(6) : name;
  }

  // Every column apart from the name, in order, decided by the scoring type.
  //
  // Held as a list rather than written out twice so the header and the rows cannot
  // drift apart - which they had, in the old version, for the bonus column.
  List<_Column> _columns() {
    final bool isWinOnly = winType == 'WIN';
    final bool isWdl = winType == 'WDL';
    final bool isPoints = winType == 'PTS';

    return <_Column>[
      const _Column('P', 'played', width: 30),
      if (!isWinOnly) const _Column('W', 'won', width: 30),
      if (isWdl) const _Column('D', 'drawn', width: 30),
      if (!isWinOnly) const _Column('L', 'lost', width: 30),
      if (isPoints) const _Column('B', 'bonus_points', width: 30),

      // The column the table is sorted by, so it is the emphasised one.
      _Column(
        isWinOnly ? 'Won' : 'Pts',
        isWinOnly ? 'won' : 'points',
        width: 42,
        emphasis: true,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingStandings) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 56),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (standingsErrorMessage != null) {
      return SlError(
        message: standingsErrorMessage!,
        onRetry: onLoadStandings,
        retryLabel: 'Reload the table',
      );
    }

    if (standings.isEmpty) {
      return const SlEmpty(
        title: 'No table yet',
        detail: 'It fills in as results are entered.',
      );
    }

    final List<_Column> columns = _columns();

    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          _buildHeader(columns),
          for (int i = 0; i < standings.length; i++) ...[
            const Divider(height: 1, thickness: 1, color: AppPalette.hairline),
            _buildRow(standings[i], i + 1, columns),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(List<_Column> columns) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      color: AppPalette.chalk,
      child: Row(
        children: [
          const SizedBox(width: 22),
          Expanded(child: Text('PLAYER', style: AppType.b(AppType.eyebrow))),
          for (final column in columns)
            SizedBox(
              width: column.width,
              child: Text(
                column.label.toUpperCase(),
                textAlign: TextAlign.center,
                style: AppType.b(AppType.eyebrow),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(
    Map<String, dynamic> player,
    int position,
    List<_Column> columns,
  ) {
    final bool isCurrentUser =
        currentUserId != null &&
        player['user_id']?.toString() == currentUserId.toString();

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      // The only highlighted row is you. Everything else stays plain, which is
      // what makes finding yourself instant.
      color: isCurrentUser ? AppPalette.tealTint.withValues(alpha: 0.6) : null,
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$position',
              style: AppType.t(
                AppType.figure,
                color: AppPalette.slate,
                size: 14,
              ),
            ),
          ),

          Expanded(
            child: Text(
              _formatPlayerName(
                player['nickname'] ?? player['name'] ?? 'Unknown',
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: AppType.b(AppType.name).copyWith(
                fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
                fontVariations: <FontVariation>[
                  FontVariation('wght', isCurrentUser ? 700 : 500),
                ],
              ),
            ),
          ),

          for (final column in columns)
            SizedBox(
              width: column.width,
              child: Text(
                '${player[column.field] ?? 0}',
                textAlign: TextAlign.center,
                style: AppType.t(
                  AppType.figure,
                  color: column.emphasis ? AppPalette.ink : AppPalette.slate,
                  size: column.emphasis ? 16 : 14,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// One numeric column of the table.
class _Column {
  final String label;
  final String field;
  final double width;

  // The column the table is ordered by. Drawn heavier and in ink, because it is
  // the one that explains the order everything else is in.
  final bool emphasis;

  const _Column(
    this.label,
    this.field, {
    required this.width,
    this.emphasis = false,
  });
}
