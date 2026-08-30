/*
The three kinds of button in the app, and nothing else.

The problem this file exists to solve: every action in the old app was a full-width
filled blue rectangle. "Invite players", "Manage League Members", "Reset League" and
"Copy League" all looked identical, so the screen never said which one mattered - and
users setting a league up and then leaving is exactly what that looks like.

So there are three, and they are ranked:

  SlButton.primary    filled teal. AT MOST ONE PER SCREEN. It is the thing we want
                      the user to do next. If a screen seems to need two, it has two
                      primary actions and the real fix is to decide which one it is.

  SlButton.secondary  outlined. A real action, just not the one being pushed. Add a
                      guest while the main ask is to invite people.

  SlButton.quiet      text only. Everything else - dismiss, cancel, "not now".

Destructive actions are deliberately NOT here. They live as rows in SlActionRow with
clay-coloured text, because a filled red button invites the tap and these are the
actions we least want tapped by accident.
*/

import 'package:flutter/material.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';

enum SlButtonKind { primary, secondary, quiet }

class SlButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final SlButtonKind kind;

  // Fills the available width. Primary buttons nearly always do; secondary ones
  // usually sit inline next to something else.
  final bool expand;

  // Swaps the label for a spinner and blocks the tap.
  final bool busy;

  const SlButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.busy = false,
  }) : kind = SlButtonKind.primary;

  const SlButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.busy = false,
  }) : kind = SlButtonKind.secondary;

  const SlButton.quiet({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.busy = false,
  }) : kind = SlButtonKind.quiet;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onPressed != null && !busy;

    // Each kind is a different *weight* of the same shape, not a different colour.
    // That is what lets the eye rank them without reading the words.
    late final Color background;
    late final Color foreground;
    late final BorderSide border;

    switch (kind) {
      case SlButtonKind.primary:
        background = enabled ? AppPalette.teal : AppPalette.hairlineStrong;
        foreground = AppPalette.onDark;
        border = BorderSide.none;

      case SlButtonKind.secondary:
        background = Colors.transparent;
        foreground = enabled ? AppPalette.tealDeep : AppPalette.slate;
        border = BorderSide(
          color:
              enabled
                  ? AppPalette.tealDeep.withValues(alpha: 0.45)
                  : AppPalette.hairline,
        );

      case SlButtonKind.quiet:
        background = Colors.transparent;
        foreground = enabled ? AppPalette.tealDeep : AppPalette.slate;
        border = BorderSide.none;
    }

    // Quiet buttons are text, so they get tighter padding - a text link with a
    // button's padding reads as a ghost button, which is a fourth kind we do not
    // want.
    final EdgeInsets padding =
        kind == SlButtonKind.quiet
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : const EdgeInsets.symmetric(horizontal: 20, vertical: 14);

    final Widget content =
        busy
            ? SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(foreground),
              ),
            )
            : Row(
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: foreground),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    label,
                    style: AppType.b(AppType.action, color: foreground),
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            );

    final Widget button = Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border:
                  border == BorderSide.none
                      ? null
                      : Border.fromBorderSide(border),
            ),
            // A minimum height rather than a fixed one, so a wrapped label at a
            // large text scale grows the button instead of being clipped.
            //
            // Deliberately NOT a Center here. A Scaffold lays its bottomNavigationBar
            // out with loose constraints - maxHeight is the whole screen - and Center
            // expands to fill whatever it is given, so a button in the bottom bar grew
            // to fill the display. Letting the row size itself keeps the button the
            // height of its own content, whatever it is placed inside.
            // No `alignment` either, for the same reason - a Container given an
            // alignment also expands to fill whatever space it is offered.
            constraints: const BoxConstraints(minHeight: 48),
            child: content,
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}
