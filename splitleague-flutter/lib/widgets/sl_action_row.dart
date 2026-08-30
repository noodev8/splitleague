/*
A tappable row.

Most of what used to be a filled blue button is really just a way into somewhere else -
"Manage League Members", "Copy League", "Reset Scores". Those are not calls to action;
they are a menu. Drawn as buttons they compete with the one action that matters, and the
screen stops saying what to do next.

So they are rows: a label, an optional second line, a chevron, and a hairline between
them. Grouped under an eyebrow by SlSection, the group reads as settings rather than as
a stack of things demanding to be pressed.

`destructive` turns the label clay. That is the whole treatment for a dangerous action -
no filled red button, because a filled button invites the tap and these are the actions
we least want tapped by mistake. The confirmation dialog does the rest of the work.
*/

import 'package:flutter/material.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';

class SlActionRow extends StatelessWidget {
  final String label;

  // One short line under the label, for a consequence the label cannot carry -
  // "Deletes every fixture and score". Optional, and usually not needed.
  final String? detail;

  final IconData? icon;
  final VoidCallback? onTap;
  final bool destructive;

  // Shown on the right instead of the chevron - a value in a settings-style row.
  final String? trailingValue;

  const SlActionRow({
    super.key,
    required this.label,
    this.detail,
    this.icon,
    this.onTap,
    this.destructive = false,
    this.trailingValue,
  });

  @override
  Widget build(BuildContext context) {
    final Color labelColour = destructive ? AppPalette.clay : AppPalette.ink;
    final bool enabled = onTap != null;

    return Semantics(
      button: enabled,
      enabled: enabled,
      child: Material(
        color: AppPalette.surface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 20,
                    color: destructive ? AppPalette.clay : AppPalette.slate,
                  ),
                  const SizedBox(width: 14),
                ],

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppType.b(
                          AppType.action,
                          color: enabled ? labelColour : AppPalette.slate,
                        ),
                      ),
                      if (detail != null) ...[
                        const SizedBox(height: 2),
                        Text(detail!, style: AppType.b(AppType.meta)),
                      ],
                    ],
                  ),
                ),

                if (trailingValue != null)
                  Text(trailingValue!, style: AppType.b(AppType.value))
                else if (enabled)
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppPalette.slate.withValues(alpha: 0.7),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/*
A group of rows under an uppercase label, on one white card with hairlines between.

The eyebrow is the app's structural device, and it earns its place here because the label
says something the rows cannot say for themselves - which of them belong together, and
who they are for ("Organiser only").
*/
class SlSection extends StatelessWidget {
  final String? eyebrow;
  final List<Widget> children;

  // Space above the section. The first section on a screen usually wants less.
  final double topGap;

  const SlSection({
    super.key,
    this.eyebrow,
    required this.children,
    this.topGap = 24,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: topGap),

        if (eyebrow != null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(
              eyebrow!.toUpperCase(),
              style: AppType.b(AppType.eyebrow),
            ),
          ),
        ],

        Container(
          decoration: BoxDecoration(
            color: AppPalette.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppPalette.hairline),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                if (i > 0)
                  const Divider(
                    height: 1,
                    thickness: 1,
                    indent: 16,
                    color: AppPalette.hairline,
                  ),
                children[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}
