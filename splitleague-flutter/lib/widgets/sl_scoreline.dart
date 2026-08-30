/*
The scoreline: the one visual unit this app is built around.

A league lives on a wall somewhere - a squash ladder, a darts board, an office pool
table. The artefact in that world is always the same shape: two names with a score
between them. That shape is the app's content, so it is also its signature, and it is
drawn the same way everywhere:

  Andreas                 3 - 1                 Costas
  ------------------------------------------------------

  * three columns, the score fixed in the middle so scores line up down the list
    however long the names are
  * tabular figures in the expanded display face, so digits never jitter as scores
    change and a column of results reads as a column
  * the winner in ink, the loser in slate - the result is legible without reading
    the numbers
  * a fixture with no result yet shows a tinted "Enter" in place of the score, which
    turns the fixture list into a visible checklist of what is left to do

That last point is the reason the unit is worth having. The old list showed "0 - 1" for
played games and nothing distinguishable for unplayed ones, so the screen never answered
the only question a user actually arrives with: what still needs doing?
*/

import 'package:flutter/material.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';

class SlScoreline extends StatelessWidget {
  final String leftName;
  final String rightName;

  // Null on both sides means the fixture has not been played.
  final int? leftScore;
  final int? rightScore;

  // Small bonus markers under a name, e.g. "+ bonus". Kept short deliberately.
  final String? leftNote;
  final String? rightNote;

  final VoidCallback? onTap;

  // Draws the row at the smaller size used inside a dashboard card.
  final bool compact;

  const SlScoreline({
    super.key,
    required this.leftName,
    required this.rightName,
    this.leftScore,
    this.rightScore,
    this.leftNote,
    this.rightNote,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool played = leftScore != null && rightScore != null;

    final bool leftWon = played && leftScore! > rightScore!;
    final bool rightWon = played && rightScore! > leftScore!;

    // An unplayed fixture keeps both names in ink - neither has lost yet, and
    // greying one of them would be a lie.
    final Color leftColour =
        !played
            ? AppPalette.ink
            : (leftWon ? AppPalette.ink : AppPalette.slate);
    final Color rightColour =
        !played
            ? AppPalette.ink
            : (rightWon ? AppPalette.ink : AppPalette.slate);

    final double nameSize = compact ? 13 : 15;

    final Widget row = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: compact ? 10 : 14,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _side(
              leftName,
              leftNote,
              leftColour,
              leftWon,
              nameSize,
              TextAlign.start,
              CrossAxisAlignment.start,
            ),
          ),

          // The centre column is a fixed width so that every score in a list sits
          // on the same axis, whatever the names either side of it are doing.
          SizedBox(
            width: compact ? 68 : 86,
            child: Center(
              child:
                  played
                      ? _playedScore(compact)
                      : _unplayedSlot(compact, onTap != null),
            ),
          ),

          Expanded(
            child: _side(
              rightName,
              rightNote,
              rightColour,
              rightWon,
              nameSize,
              TextAlign.end,
              CrossAxisAlignment.end,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return row;

    return Semantics(
      button: true,
      label:
          played
              ? '$leftName $leftScore, $rightName $rightScore. Tap to change the result.'
              : '$leftName against $rightName, not played yet. Tap to enter the result.',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: row),
      ),
    );
  }

  // One end of the scoreline.
  Widget _side(
    String name,
    String? note,
    Color colour,
    bool won,
    double size,
    TextAlign align,
    CrossAxisAlignment cross,
  ) {
    return Column(
      crossAxisAlignment: cross,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          name,
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.b(AppType.name, color: colour, size: size).copyWith(
            // The winner is a shade heavier as well as darker, so the result
            // survives high contrast mode and greyscale.
            fontWeight: won ? FontWeight.w700 : FontWeight.w500,
            fontVariations: <FontVariation>[
              FontVariation('wght', won ? 700 : 500),
            ],
          ),
        ),
        if (note != null) ...[
          const SizedBox(height: 3),
          Text(
            note,
            textAlign: align,
            style: AppType.b(AppType.meta, color: AppPalette.pitch, size: 11),
          ),
        ],
      ],
    );
  }

  // The result itself.
  Widget _playedScore(bool compact) {
    return Text(
      '$leftScore – $rightScore',
      style: AppType.t(AppType.score, size: compact ? 16 : 22),
    );
  }

  // No result yet. A tinted pill saying what to do, rather than an empty gap or
  // a pair of zeroes pretending to be a scoreless draw.
  Widget _unplayedSlot(bool compact, bool tappable) {
    if (!tappable) {
      return Text(
        '–',
        style: AppType.t(
          AppType.score,
          color: AppPalette.slate,
          size: compact ? 16 : 22,
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppPalette.tealTint,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Enter',
        style: AppType.b(
          AppType.action,
          color: AppPalette.tealDeep,
          size: compact ? 12 : 13,
        ),
      ),
    );
  }
}
