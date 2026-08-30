/*
The segmented control that moves between the views of one league.

What it replaces: three full-width buttons where the current screen was a solid indigo
block and the other two were grey blocks. Those read as three actions of equal weight,
not as one control with a position - which is what they actually are.

This is one track with a sliding selection inside it. Only the label changes weight and
colour; nothing grows a shadow or a border. It sits directly under the app bar with a
hairline beneath, so it belongs to the header rather than floating over the content.

The four league views still navigate with pushReplacement underneath - that part of the
flow was fixed already and is deliberately untouched (see docs/next-league-flow.md).
*/

import 'package:flutter/material.dart';
import '../styles/app_palette.dart';
import '../styles/app_type.dart';

class SlSegment {
  final String label;
  final VoidCallback? onTap;

  const SlSegment({required this.label, this.onTap});
}

class SlSegmented extends StatelessWidget {
  final List<SlSegment> segments;
  final int selectedIndex;

  const SlSegmented({
    super.key,
    required this.segments,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      color: AppPalette.surface,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppPalette.chalk,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            for (int i = 0; i < segments.length; i++)
              Expanded(child: _segment(segments[i], i == selectedIndex)),
          ],
        ),
      ),
    );
  }

  Widget _segment(SlSegment segment, bool selected) {
    return Semantics(
      button: true,
      selected: selected,
      label: segment.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? AppPalette.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        // A hairline rather than a shadow. The selected segment is lifted by
        // being white against the track, which is enough.
        child: InkWell(
          onTap: selected ? null : segment.onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            constraints: const BoxConstraints(minHeight: 38),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: selected ? Border.all(color: AppPalette.hairline) : null,
            ),
            child: Text(
              segment.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.b(
                AppType.action,
                color: selected ? AppPalette.ink : AppPalette.slate,
                size: 14,
              ).copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontVariations: <FontVariation>[
                  FontVariation('wght', selected ? 700 : 500),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
