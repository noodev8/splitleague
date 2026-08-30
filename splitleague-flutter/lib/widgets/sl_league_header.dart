/*
The header every league screen shares: the league name, the stage, and the segmented
control that moves between the views.

What it replaces: a gradient app bar, then a row of three full-width buttons, then a
three-line tinted banner repeating what stage the league was in and what you could do
in it. That was about 200 vertical pixels of chrome on a 720-pixel-wide phone, and it
said the same thing on all four screens, so by the second screen nobody read it.

Here the stage is a single line under the league name: a coloured dot, the stage name,
and one short clause. It is still in exactly one fixed place on every league screen -
which was the good idea in the original banner - it just costs one line instead of five.

The name is set in the display face because a league's name is the one piece of content
the organiser chose, and it should look chosen.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../helpers/league_stage.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';
import 'sl_segmented.dart';

class SlLeagueHeader extends StatelessWidget implements PreferredSizeWidget {
  final String leagueName;
  final LeagueStage stage;

  final List<SlSegment> segments;
  final int selectedIndex;

  final VoidCallback onBack;

  // An icon button on the right - sharing, usually.
  final IconData? actionIcon;
  final String? actionTooltip;
  final VoidCallback? onAction;

  const SlLeagueHeader({
    super.key,
    required this.leagueName,
    required this.stage,
    required this.segments,
    required this.selectedIndex,
    required this.onBack,
    this.actionIcon,
    this.actionTooltip,
    this.onAction,
  });

  @override
  Size get preferredSize => const Size.fromHeight(0);

  @override
  Widget build(BuildContext context) {
    // The league screens have no AppBar, so they do not get the app bar theme's
    // status bar style. Without this they keep the white icons the dashboard asked
    // for, on a white header. See app_theme.dart.
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Container(
        color: AppPalette.surface,
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 8, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppPalette.ink),
                      tooltip: 'Back to your leagues',
                      onPressed: onBack,
                    ),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            leagueName,
                            style: AppType.t(AppType.title),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          _stageLine(),
                        ],
                      ),
                    ),

                    if (actionIcon != null && onAction != null)
                      IconButton(
                        icon: Icon(
                          actionIcon,
                          color: AppPalette.tealDeep,
                          size: 22,
                        ),
                        tooltip: actionTooltip,
                        onPressed: onAction,
                      ),
                  ],
                ),
              ),

              SlSegmented(segments: segments, selectedIndex: selectedIndex),

              const Divider(
                height: 1,
                thickness: 1,
                color: AppPalette.hairline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // The stage, on one line.
  //
  // A dot rather than an icon: at 8 pixels the icons in the old banner were
  // unreadable anyway, and the colour is doing all the work. The stage name is
  // still spelled out next to it, so the colour is never the only signal.
  Widget _stageLine() {
    final Color colour = LeagueStageInfo.colour(stage);

    return Semantics(
      label:
          'League stage: ${LeagueStageInfo.label(stage)}. '
          '${LeagueStageInfo.description(stage)}',
      excludeSemantics: true,
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: colour, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              '${LeagueStageInfo.label(stage)} · ${LeagueStageInfo.description(stage)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.b(
                AppType.meta,
                color: colour,
                size: 12,
              ).copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
