/*
The ThemeData the app runs on.

Most of the app's look is set explicitly by the SL* widgets rather than by the theme -
that is deliberate, because the old code's problem was half-set themes quietly fighting
per-widget colours. What the theme is for here is the things Flutter draws that we do
not: dialogs, snack bars, text fields, the text selection handles, the ripple.

Anything drawn by Material that we have not styled should still land inside the palette,
so a dialog we forget about does not arrive in Material's stock indigo.
*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_palette.dart';
import 'app_type.dart';

class AppTheme {
  static ThemeData build() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.teal,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppPalette.teal,
      onPrimary: AppPalette.onDark,
      secondary: AppPalette.deep,
      onSecondary: AppPalette.onDark,
      surface: AppPalette.surface,
      onSurface: AppPalette.ink,
      error: AppPalette.clay,
      onError: AppPalette.onDark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppPalette.chalk,

      // Instrument Sans is the interface face, so it is the default for anything
      // that does not ask for the display face by name.
      fontFamily: AppType.bodyFamily,

      // Ripples: the stock Material splash is a big grey circle that reads as a
      // bug against these quiet surfaces.
      splashColor: AppPalette.tealTint.withValues(alpha: 0.6),
      highlightColor: AppPalette.tealTint.withValues(alpha: 0.35),

      dividerTheme: const DividerThemeData(
        color: AppPalette.hairline,
        thickness: 1,
        space: 1,
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: AppPalette.surface,
        foregroundColor: AppPalette.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppType.t(AppType.title),

        // Dark status bar icons, because every app bar in the app is white.
        //
        // Android keeps whatever the last screen asked for, and the dashboard asks
        // for white icons for its dark header - so without this, every light screen
        // opened from the dashboard inherited an invisible clock and battery.
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
      ),

      // Dialogs carry the confirmations for every one-way action in the app -
      // starting a league, resetting one - so they are worth getting right.
      dialogTheme: DialogThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: AppType.t(AppType.titleSmall),
        contentTextStyle: AppType.b(AppType.body),
      ),

      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
        ),
      ),

      // The dialog buttons. Cancel-style actions read as quiet text; the
      // confirming action is given the teal.
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppPalette.tealDeep,
          textStyle: AppType.b(AppType.action),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppPalette.teal,
          foregroundColor: AppPalette.onDark,
          elevation: 0,
          textStyle: AppType.b(AppType.action),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppPalette.tealDeep,
          side: BorderSide(color: AppPalette.tealDeep.withValues(alpha: 0.45)),
          textStyle: AppType.b(AppType.action),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppPalette.chalk,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 16,
        ),
        labelStyle: AppType.b(AppType.meta),
        floatingLabelStyle: AppType.b(AppType.meta, color: AppPalette.tealDeep),
        hintStyle: AppType.b(AppType.meta),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.teal, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.clay),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppPalette.clay, width: 1.6),
        ),
        errorStyle: TextStyle(
          fontFamily: AppType.bodyFamily,
          fontSize: 12.5,
          color: AppPalette.clay,
        ),
      ),

      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppPalette.teal,
        selectionColor: AppPalette.tealTint,
        selectionHandleColor: AppPalette.teal,
      ),

      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppPalette.teal,
      ),

      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppPalette.ink,
        contentTextStyle: AppType.b(AppType.body, color: AppPalette.onDark),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      popupMenuTheme: PopupMenuThemeData(
        color: AppPalette.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: AppType.b(AppType.action),
      ),

      // The app is deliberately light-only. A half-done dark mode over a palette
      // this specific would be worse than none.
      brightness: Brightness.light,
    );
  }
}
