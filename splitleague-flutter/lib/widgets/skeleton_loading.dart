/*
Skeleton loading widgets for the SplitLeague app
Provides consistent loading state UI components
*/

import 'package:flutter/material.dart';

class SkeletonLoading extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;
  final Color? baseColor;
  final Color? highlightColor;
  final bool isShimmer;

  const SkeletonLoading({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 8,
    this.baseColor,
    this.highlightColor,
    this.isShimmer = true,
  });

  @override
  Widget build(BuildContext context) {
    // Use default colors if not provided
    final baseColorValue = baseColor ?? Colors.grey.shade300;
    final highlightColorValue = highlightColor ?? Colors.grey.shade100;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isShimmer ? null : baseColorValue,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: isShimmer
          ? _ShimmerEffect(
              baseColor: baseColorValue,
              highlightColor: highlightColorValue,
              child: Container(
                decoration: BoxDecoration(
                  color: baseColorValue,
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
            )
          : null,
    );
  }
}

class _ShimmerEffect extends StatefulWidget {
  final Widget child;
  final Color baseColor;
  final Color highlightColor;

  const _ShimmerEffect({
    required this.child,
    required this.baseColor,
    required this.highlightColor,
  });

  @override
  _ShimmerEffectState createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<_ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _colorAnimation = ColorTween(
      begin: widget.baseColor,
      end: widget.highlightColor,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeInOut),
        reverseCurve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                widget.baseColor,
                _colorAnimation.value ?? widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// Skeleton for a text line
class SkeletonText extends StatelessWidget {
  final double width;
  final double height;
  final EdgeInsetsGeometry margin;

  const SkeletonText({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.margin = const EdgeInsets.symmetric(vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: SkeletonLoading(
        width: width,
        height: height,
        borderRadius: 4,
      ),
    );
  }
}

// Skeleton for a card
class SkeletonCard extends StatelessWidget {
  final double height;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final int lines;
  final bool showAvatar;
  final bool showButton;

  const SkeletonCard({
    super.key,
    this.height = 120,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.lines = 3,
    this.showAvatar = false,
    this.showButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(25),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showAvatar) ...[
            SkeletonLoading(
              width: 50,
              height: 50,
              borderRadius: 25,
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const SkeletonText(
                  width: 150,
                  height: 20,
                ),
                const SizedBox(height: 8),
                // Content lines
                for (int i = 0; i < lines; i++)
                  SkeletonText(
                    width: i == lines - 1 ? 180 : double.infinity,
                  ),
                const Spacer(),
                if (showButton)
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: SkeletonText(
                      width: 80,
                      height: 32,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Skeleton for a list of items
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final bool scrollable;
  final bool showAvatar;
  final int lines;
  final bool showButton;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 100,
    this.scrollable = true,
    this.showAvatar = false,
    this.lines = 2,
    this.showButton = false,
  });

  @override
  Widget build(BuildContext context) {
    final list = List.generate(
      itemCount,
      (index) => SkeletonCard(
        height: itemHeight,
        lines: lines,
        showAvatar: showAvatar,
        showButton: showButton,
      ),
    );

    return scrollable
        ? ListView(
            physics: const NeverScrollableScrollPhysics(),
            children: list,
          )
        : Column(
            children: list,
          );
  }
}

// Skeleton for a fixture card
class SkeletonFixtureCard extends StatelessWidget {
  const SkeletonFixtureCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date and status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                SkeletonText(width: 100),
                SkeletonText(width: 80),
              ],
            ),
            const SizedBox(height: 16),
            // Players
            Row(
              children: [
                // Player 1
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonText(width: 120),
                      SizedBox(height: 8),
                      SkeletonText(width: 80),
                    ],
                  ),
                ),
                // VS
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const SkeletonText(width: 30, height: 30),
                ),
                // Player 2
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SkeletonText(width: 120),
                      SizedBox(height: 8),
                      SkeletonText(width: 80),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Skeleton for a standings table
class SkeletonStandingsTable extends StatelessWidget {
  final int rowCount;

  const SkeletonStandingsTable({
    super.key,
    this.rowCount = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header row
            Row(
              children: const [
                Expanded(flex: 3, child: SkeletonText()),
                SizedBox(width: 8),
                Expanded(child: SkeletonText()),
                SizedBox(width: 8),
                Expanded(child: SkeletonText()),
                SizedBox(width: 8),
                Expanded(child: SkeletonText()),
                SizedBox(width: 8),
                Expanded(child: SkeletonText()),
              ],
            ),
            const Divider(height: 32),
            // Data rows
            for (int i = 0; i < rowCount; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: const [
                    Expanded(flex: 3, child: SkeletonText()),
                    SizedBox(width: 8),
                    Expanded(child: SkeletonText()),
                    SizedBox(width: 8),
                    Expanded(child: SkeletonText()),
                    SizedBox(width: 8),
                    Expanded(child: SkeletonText()),
                    SizedBox(width: 8),
                    Expanded(child: SkeletonText()),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Skeleton for league details
class SkeletonLeagueDetails extends StatelessWidget {
  const SkeletonLeagueDetails({super.key});

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
              children: [
                // League name and PIN
                Row(
                  children: const [
                    SkeletonLoading(width: 40, height: 40, borderRadius: 8),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonText(width: 80, height: 12),
                          SizedBox(height: 4),
                          SkeletonText(width: 150, height: 16),
                        ],
                      ),
                    ),
                    SkeletonLoading(width: 60, height: 30, borderRadius: 8),
                  ],
                ),
                const SizedBox(height: 16),
                // Organizer
                Row(
                  children: const [
                    SkeletonLoading(width: 40, height: 40, borderRadius: 8),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonText(width: 80, height: 12),
                        SizedBox(height: 4),
                        SkeletonText(width: 120, height: 16),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Points Type
                Row(
                  children: const [
                    SkeletonLoading(width: 40, height: 40, borderRadius: 8),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonText(width: 80, height: 12),
                        SizedBox(height: 4),
                        SkeletonText(width: 100, height: 16),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Created at
                Row(
                  children: const [
                    SkeletonLoading(width: 40, height: 40, borderRadius: 8),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonText(width: 80, height: 12),
                        SizedBox(height: 4),
                        SkeletonText(width: 140, height: 16),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        // Points rules section
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < 5; i++) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: const [
                        SkeletonLoading(width: 36, height: 36, borderRadius: 8),
                        SizedBox(width: 16),
                        Expanded(child: SkeletonText()),
                        SkeletonText(width: 30),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
