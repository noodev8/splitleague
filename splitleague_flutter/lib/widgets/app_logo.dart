/*
Reusable app logo widget for the SplitLeague application
Can be used in various screens with customizable size and colors
*/

import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final Color backgroundColor;
  final Color textColor;
  final Color dotsColor;
  final double opacity;
  final bool showText;
  final String? subtitle;

  const AppLogo({
    super.key,
    this.size = 120.0,
    this.backgroundColor = Colors.white,
    this.textColor = Colors.white,
    this.dotsColor = Colors.white,
    this.opacity = 0.15,
    this.showText = true,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Logo container with rounded corners
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(opacity),
            borderRadius: BorderRadius.circular(size * 0.16),
          ),
          padding: EdgeInsets.all(size * 0.1),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // SL Monogram
              Text(
                'SL',
                style: TextStyle(
                  color: textColor,
                  fontSize: size * 0.48,
                  fontWeight: FontWeight.bold,
                  height: 0.9,
                ),
              ),
              
              SizedBox(height: size * 0.1),
              
              // Three dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildDot(),
                  SizedBox(width: size * 0.08),
                  _buildDot(),
                  SizedBox(width: size * 0.08),
                  _buildDot(),
                ],
              ),
            ],
          ),
        ),
        
        // App name text (optional)
        if (showText) ...[
          const SizedBox(height: 16),
          const Text(
            'SplitLeague',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Subtitle (optional)
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ],
    );
  }
  
  // Helper method to build a dot
  Widget _buildDot() {
    return Container(
      width: size * 0.06,
      height: size * 0.06,
      decoration: BoxDecoration(
        color: dotsColor,
        shape: BoxShape.circle,
      ),
    );
  }
}
