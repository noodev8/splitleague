/*
Shared styles for the splitleague application
Contains colors, text styles, and other UI elements
*/

import 'package:flutter/material.dart';

class AppStyles {
  // Colors - Modern scheme
  static const Color primaryColor = Color(0xFF4361EE); // Vibrant blue
  static const Color accentColor = Color(0xFF3A0CA3); // Deep purple
  static const Color backgroundColor = Color(0xFFF8F9FA); // Light gray background
  static const Color textColor = Color(0xFF212529); // Dark text
  static const Color secondaryTextColor = Color(0xFF6C757D); // Medium gray text
  static const Color errorColor = Color(0xFFE63946); // Bright red
  static const Color successColor = Color(0xFF2A9D8F); // Teal green
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color highlightColor = Color(0xFF4CC9F0); // Light blue
  static const Color warningColor = Color(0xFFF77F00); // Orange

  // Text Styles
  static const TextStyle headingStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: textColor,
  );

  static const TextStyle subheadingStyle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: textColor,
  );

  static const TextStyle bodyStyle = TextStyle(
    fontSize: 16,
    color: textColor,
  );

  static const TextStyle captionStyle = TextStyle(
    fontSize: 14,
    color: secondaryTextColor,
  );

  // Button Styles
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    elevation: 2,
  );

  static final ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: primaryColor,
    side: const BorderSide(color: primaryColor),
    padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
  );

  static final ButtonStyle subtleButtonStyle = TextButton.styleFrom(
    foregroundColor: primaryColor,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static final ButtonStyle tabButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.white,
    foregroundColor: secondaryTextColor,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 0,
    minimumSize: const Size(10, 36),
  );

  static final ButtonStyle activeTabButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: primaryColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    elevation: 2,
    minimumSize: const Size(10, 36),
  );

  // Input Decoration
  static InputDecoration inputDecoration(String label, {String? hint, Widget? prefixIcon, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Colors.grey),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: errorColor),
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
    );
  }

  // Card Decoration
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withAlpha(38), // 0.15 opacity
        spreadRadius: 1,
        blurRadius: 8,
        offset: const Offset(0, 3),
      ),
    ],
  );

  // Selection Card Decoration
  static final BoxDecoration selectionCardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade300, width: 1),
  );

  static final BoxDecoration selectedCardDecoration = BoxDecoration(
    color: primaryColor.withAlpha(13), // 0.05 opacity
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: primaryColor, width: 2),
  );

  // Tab Container Decoration
  static final BoxDecoration tabContainerDecoration = BoxDecoration(
    color: Colors.grey.shade100,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: Colors.grey.shade200),
  );
}
