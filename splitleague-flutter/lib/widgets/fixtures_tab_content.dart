/*
The list of games in a league, and the filters over it.

This is the screen a league in play lives on, and the question people open it with is
always the same: what still needs a result? The old version could not answer it. Every
fixture was a card of roughly equal weight, an unplayed one looked much like a played
one, and the filter panel above them was a white block with two labelled rows and a
refresh button - about a fifth of the screen spent on controls.

Now:

  * The filters are three chips carrying counts - All 12 / To play 5 / Played 7. The
    count is the answer to the question, so it is on screen before you touch anything.

  * Every fixture is an SlScoreline (see sl_scoreline.dart). A played game shows its
    score with the winner in ink; an unplayed one shows a teal "Enter". The list
    reads as a checklist, which is what it is.

  * Fixtures sit in one card with hairlines between them rather than as a stack of
    separate cards, so a long list reads as a table.

The player filter is a text button rather than a bordered select, because it is the
second-most-used control on the screen and it was taking up as much room as the first.
*/

import 'package:flutter/material.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import 'sl_empty.dart';
import 'sl_scoreline.dart';

class FixturesTabContent extends StatelessWidget {
  final bool isCreator;
  final bool isLoadingFixtures;
  final bool isLoadingMembers;
  final List<Map<String, dynamic>> fixtures;
  final List<Map<String, dynamic>> filteredFixtures;
  final String? filterPlayerId;
  final String? filterPlayerName;
  final String? filterPlayedStatus;
  final String? fixturesErrorMessage;
  final String? successMessage;
  final int? lastUpdatedFixtureId;
  final ScrollController? scrollController;

  final Function() onLoadFixtures;
  final Function(BuildContext) onShowFilterMenu;
  final Function(Map<String, dynamic>) onNavigateToUpdateScore;
  final Function() onClearFilter;
  final Function(String)? onApplyPlayedStatusFilter;
  final Function()? onClearPlayedStatusFilter;

  const FixturesTabContent({
    super.key,
    required this.isCreator,
    required this.isLoadingFixtures,
    required this.isLoadingMembers,
    required this.fixtures,
    required this.filteredFixtures,
    required this.filterPlayerId,
    required this.filterPlayerName,
    this.filterPlayedStatus,
    required this.fixturesErrorMessage,
    required this.successMessage,
    this.lastUpdatedFixtureId,
    this.scrollController,
    required this.onLoadFixtures,
    required this.onShowFilterMenu,
    required this.onNavigateToUpdateScore,
    required this.onClearFilter,
    this.onApplyPlayedStatusFilter,
    this.onClearPlayedStatusFilter,
  });

  // Strip the storage prefix off a guest's nickname. Guests are rows in app_user
  // with a nickname of the form "guest_Dave"; the prefix is never shown.
  String _playerName(Map<String, dynamic> fixture, String which) {
    final String raw =
        (fixture['player_${which}_nickname']?.toString().isNotEmpty == true)
            ? fixture['player_${which}_nickname'].toString()
            : (fixture['player_${which}_name']?.toString() ?? 'Unknown');

    return raw.startsWith('guest_') ? raw.substring(6) : raw;
  }

  int? _score(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // The bonus markers under a name. These were previously two separate icon-plus-word
  // rows inside the fixture card; they are now one short phrase, because the detail
  // belongs on the score entry screen and here it only needs to be noticeable.
  String? _bonusNote(Map<String, dynamic> fixture, bool isLeft) {
    final int? left = _score(fixture['player_1_score']);
    final int? right = _score(fixture['player_2_score']);
    if (left == null || right == null) return null;

    final int threshold = _score(fixture['win_margin_threshold']) ?? 0;
    final int winMarginPoints = _score(fixture['points_for_win_margin']) ?? 0;
    final int closeLossPoints = _score(fixture['points_for_close_loss']) ?? 0;
    if (threshold <= 0) return null;

    final int difference = left - right;
    if (difference == 0) return null;

    final bool leftWon = difference > 0;
    final int margin = difference.abs();

    // The winner gets a bonus for winning by enough; the loser gets one for
    // keeping it close. Only one of the two can apply to any one player.
    if (isLeft == leftWon) {
      if (winMarginPoints > 0 && margin >= threshold) {
        return '+$winMarginPoints bonus';
      }
      return null;
    }

    if (closeLossPoints > 0 && margin < threshold) {
      return '+$closeLossPoints close';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final bool filtering = filterPlayerId != null || filterPlayedStatus != null;
    final List<Map<String, dynamic>> shown =
        filtering ? filteredFixtures : fixtures;

    // Counted from the full list, not the filtered one - a count that changed when
    // you filtered would be useless as an answer to "how much is left".
    final int played = fixtures.where((f) => f['played'] == true).length;
    final int toPlay = fixtures.length - played;

    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (fixtures.isNotEmpty) ...[
            _buildFilters(context, played, toPlay),
            const SizedBox(height: 16),
          ],

          if (fixturesErrorMessage != null &&
              !fixturesErrorMessage!.contains('No fixtures')) ...[
            SlError(message: fixturesErrorMessage!, onRetry: onLoadFixtures),
            const SizedBox(height: 16),
          ],

          if (isLoadingFixtures || isLoadingMembers)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 56),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (fixtures.isEmpty)
            const SlEmpty(
              title: 'No fixtures yet',
              detail: 'They appear the moment the league is started.',
            )
          else if (shown.isEmpty)
            SlEmpty(
              title: 'Nothing matches that',
              actionLabel: 'Clear filters',
              onAction: () {
                onClearFilter();
                onClearPlayedStatusFilter?.call();
              },
            )
          else
            _buildFixtureList(shown),
        ],
      ),
    );
  }

  // Three chips with counts, then the player filter.
  Widget _buildFilters(BuildContext context, int played, int toPlay) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _chip(
              'All',
              fixtures.length,
              filterPlayedStatus == null,
              () => onClearPlayedStatusFilter?.call(),
            ),
            const SizedBox(width: 8),
            _chip(
              'To play',
              toPlay,
              filterPlayedStatus == 'not_played',
              () => onApplyPlayedStatusFilter?.call('not_played'),
            ),
            const SizedBox(width: 8),
            _chip(
              'Played',
              played,
              filterPlayedStatus == 'played',
              () => onApplyPlayedStatusFilter?.call('played'),
            ),
          ],
        ),

        const SizedBox(height: 4),

        // The player filter. A text button when nothing is selected, so it stays
        // out of the way; a removable pill when something is, so it is obvious
        // that the list on screen is not the whole list.
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child:
                    filterPlayerId == null
                        ? TextButton.icon(
                          onPressed: () => onShowFilterMenu(context),
                          icon: const Icon(Icons.person_outline, size: 16),
                          label: Text(
                            'Filter by player',
                            style: AppType.b(
                              AppType.meta,
                              color: AppPalette.tealDeep,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            minimumSize: const Size(0, 36),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        )
                        : _playerPill(context),
              ),
            ),

            IconButton(
              onPressed: onLoadFixtures,
              icon: const Icon(
                Icons.refresh,
                size: 18,
                color: AppPalette.slate,
              ),
              tooltip: 'Reload the fixtures',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }

  Widget _chip(String label, int count, bool selected, VoidCallback onTap) {
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label, $count',
        excludeSemantics: true,
        child: Material(
          color: selected ? AppPalette.tealTint : AppPalette.surface,
          borderRadius: BorderRadius.circular(9),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(9),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color:
                      selected
                          ? AppPalette.teal.withValues(alpha: 0.4)
                          : AppPalette.hairline,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$count',
                    style: AppType.t(
                      AppType.figure,
                      color: selected ? AppPalette.tealDeep : AppPalette.ink,
                      size: 17,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.b(
                      AppType.meta,
                      color: selected ? AppPalette.tealDeep : AppPalette.slate,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _playerPill(BuildContext context) {
    return Material(
      color: AppPalette.tealTint,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => onShowFilterMenu(context),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 7, 6, 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  filterPlayerName ?? 'Selected player',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.b(
                    AppType.meta,
                    color: AppPalette.tealDeep,
                  ).copyWith(fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                onPressed: onClearFilter,
                icon: const Icon(
                  Icons.close,
                  size: 15,
                  color: AppPalette.tealDeep,
                ),
                tooltip: 'Show every player',
                visualDensity: VisualDensity.compact,
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // One card, hairlines between - so a long list reads as a table rather than as a
  // stack of separate objects.
  Widget _buildFixtureList(List<Map<String, dynamic>> shown) {
    return Container(
      decoration: BoxDecoration(
        color: AppPalette.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppPalette.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < shown.length; i++) ...[
            if (i > 0)
              const Divider(
                height: 1,
                thickness: 1,
                color: AppPalette.hairline,
              ),
            _buildFixture(shown[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildFixture(Map<String, dynamic> fixture) {
    final bool played = fixture['played'] == true;
    final int? leftScore = played ? _score(fixture['player_1_score']) : null;
    final int? rightScore = played ? _score(fixture['player_2_score']) : null;

    final int fixtureId =
        fixture['id'] is int
            ? fixture['id']
            : int.tryParse(fixture['id'].toString()) ?? 0;

    // The row the user just came back from updating, marked so it can be found
    // again in a long list.
    final bool justUpdated =
        lastUpdatedFixtureId != null && fixtureId == lastUpdatedFixtureId;

    final Widget row = SlScoreline(
      leftName: _playerName(fixture, '1'),
      rightName: _playerName(fixture, '2'),
      leftScore: leftScore,
      rightScore: rightScore,
      leftNote: _bonusNote(fixture, true),
      rightNote: _bonusNote(fixture, false),
      onTap: () => onNavigateToUpdateScore(fixture),
    );

    if (!justUpdated) return row;

    return Container(
      color: AppPalette.tealTint.withValues(alpha: 0.55),
      child: row,
    );
  }
}
