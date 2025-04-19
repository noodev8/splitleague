/*
Animation utilities for the SplitLeague app
Provides consistent animations and transitions
*/

import 'package:flutter/material.dart';

/// Animation durations
class AnimDurations {
  static const fast = Duration(milliseconds: 200);
  static const medium = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 400);
}

/// Animation curves
class AnimCurves {
  static const standard = Curves.easeInOut;
  static const decelerate = Curves.easeOutCubic;
  static const accelerate = Curves.easeInCubic;
  static const bounce = Curves.elasticOut;
  static const spring = Curves.easeInOutBack;
}

/// Simple fade-in animation widget
class FadeInAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final double beginOpacity;

  const FadeInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.beginOpacity = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: beginOpacity, end: 1.0),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        // Ensure opacity is within valid range (0.0 to 1.0)
        final clampedOpacity = value.clamp(0.0, 1.0);
        return Opacity(
          opacity: clampedOpacity,
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Simple slide-in animation widget
class SlideInAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Offset beginOffset;

  const SlideInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.beginOffset = const Offset(0.0, 0.2),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(begin: beginOffset, end: Offset.zero),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        // Ensure values are valid
        final safeValue = Offset(
          value.dx.isFinite ? value.dx : 0.0,
          value.dy.isFinite ? value.dy : 0.0,
        );
        return Transform.translate(
          offset: Offset(
            safeValue.dx * 100, // Scale for better visual effect
            safeValue.dy * 100,
          ),
          child: child,
        );
      },
      child: child,
    );
  }
}

/// Combined fade and slide animation
class FadeSlideAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Offset beginOffset;
  final double beginOpacity;

  const FadeSlideAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeOut,
    this.beginOffset = const Offset(0.0, 0.2),
    this.beginOpacity = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    return FadeInAnimation(
      duration: duration,
      curve: curve,
      beginOpacity: beginOpacity,
      child: SlideInAnimation(
        duration: duration,
        curve: curve,
        beginOffset: beginOffset,
        child: child,
      ),
    );
  }
}

/// Animated card with hover effect
class AnimatedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry margin;
  final EdgeInsetsGeometry padding;
  final double elevation;
  final double hoverElevation;
  final BorderRadius borderRadius;
  final Color? color;

  const AnimatedCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin = EdgeInsets.zero,
    this.padding = EdgeInsets.zero,
    this.elevation = 2.0,
    this.hoverElevation = 4.0,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.color,
  });

  @override
  State<AnimatedCard> createState() => _AnimatedCardState();
}

class _AnimatedCardState extends State<AnimatedCard> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => isHovered = true),
      onExit: (_) => setState(() => isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: widget.margin,
          padding: widget.padding,
          decoration: BoxDecoration(
            color: widget.color ?? Theme.of(context).cardColor,
            borderRadius: widget.borderRadius,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(25),
                blurRadius: isHovered ? widget.hoverElevation * 2 : widget.elevation * 2,
                spreadRadius: isHovered ? widget.hoverElevation / 2 : widget.elevation / 2,
                offset: Offset(0, isHovered ? widget.hoverElevation / 2 : widget.elevation / 2),
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Animated tab transition
class AnimatedTabTransition extends StatelessWidget {
  final List<Widget> children;
  final int selectedIndex;
  final Duration duration;
  final Curve curve;

  const AnimatedTabTransition({
    super.key,
    required this.children,
    required this.selectedIndex,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      switchInCurve: curve,
      switchOutCurve: curve,
      transitionBuilder: (Widget child, Animation<double> animation) {
        // Ensure animation value is valid
        final safeAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOut,
        );
        return FadeTransition(
          opacity: safeAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.05, 0.0),
              end: Offset.zero,
            ).animate(safeAnimation),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(selectedIndex),
        child: children[selectedIndex],
      ),
    );
  }
}
