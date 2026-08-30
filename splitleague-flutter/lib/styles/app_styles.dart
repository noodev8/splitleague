/*
The old style constants, repointed at the new palette.

This file used to be where the app's look was defined - an indigo primary, a Material grey
background, a set of ElevatedButton styles. It is now a thin layer over
styles/app_palette.dart and styles/app_type.dart, and nothing here has a colour of its own.

Why it still exists. The screens that carry most of the app's traffic - the dashboard, the
four league screens, sign in, register, create and join - were rewritten against the new
system directly. The handful that are reached rarely, like change password and hidden
leagues, still refer to these names. Repointing them here means those screens sit inside
the palette without each one having to be rebuilt, and there is no second palette left in
the codebase that could drift.

Do not add to this file. New work uses AppPalette and AppType. When the last of the older
screens is rewritten this file goes away, and the analyzer will say so by finding no
references.
*/

import 'package:flutter/material.dart';
import 'app_palette.dart';
import 'app_type.dart';

class AppStyles {
  // Colours - every one of these is now an alias.
  static const Color primaryColor = AppPalette.teal;
  static const Color accentColor = AppPalette.tealDeep;
  static const Color backgroundColor = AppPalette.chalk;
  static const Color textColor = AppPalette.ink;
  static const Color secondaryTextColor = AppPalette.slate;
  static const Color successColor = AppPalette.pitch;
  static const Color cardColor = AppPalette.surface;
  static const Color errorColor = AppPalette.clay;

  // The old "ice theme" names. They were a second palette that had drifted from the
  // first; they now point at the same places as everything else.
  static const Color iceWhite = AppPalette.surface;
  static const Color iceLightBlue = AppPalette.tealTint;
  static const Color iceBlue = AppPalette.teal;
  static const Color iceDarkBlue = AppPalette.deep;

  // Text styles.
  static TextStyle get headingStyle => AppType.t(AppType.display, size: 24);
  static TextStyle get subheadingStyle =>
      AppType.t(AppType.titleSmall, size: 18);
  static TextStyle get bodyStyle => AppType.b(AppType.body, size: 16);
  static TextStyle get captionStyle => AppType.b(AppType.meta, size: 14);
  static TextStyle get sectionHeading => AppType.t(AppType.title);
  static TextStyle get subtitle => AppType.b(AppType.meta, size: 14);

  // Buttons.
  //
  // These match SlButton's three kinds, so a screen still using them looks like one
  // that has been rewritten. New work uses widgets/sl_button.dart, which also carries
  // the rule about one filled button per screen.
  static final ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: AppPalette.teal,
    foregroundColor: AppPalette.onDark,
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    textStyle: AppType.b(AppType.action),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static final ButtonStyle secondaryButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: AppPalette.tealDeep,
    side: BorderSide(color: AppPalette.tealDeep.withValues(alpha: 0.45)),
    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
    textStyle: AppType.b(AppType.action),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  );

  static final ButtonStyle subtleButtonStyle = TextButton.styleFrom(
    foregroundColor: AppPalette.tealDeep,
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
    textStyle: AppType.b(AppType.action),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
  );

  // Fields. The theme already styles every field in the app; this stays only so that
  // the older screens calling it get the same one.
  static InputDecoration inputDecoration(
    String label, {
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
    );
  }

  // Surfaces.
  static final BoxDecoration cardDecoration = BoxDecoration(
    color: AppPalette.surface,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: AppPalette.hairline),
  );

  static final BoxDecoration selectionCardDecoration = BoxDecoration(
    color: AppPalette.surface,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: AppPalette.hairline),
  );

  static final BoxDecoration selectedCardDecoration = BoxDecoration(
    color: AppPalette.tealTint,
    borderRadius: BorderRadius.circular(10),
    border: Border.all(color: AppPalette.teal),
  );
}
