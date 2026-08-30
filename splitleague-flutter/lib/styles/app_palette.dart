/*
The colours of the app, in one place.

Before this file there were three unrelated palettes fighting each other on the same
screen: a teal gradient in the app bar (taken from the logo), an indigo for the tabs and
the primary buttons, and Material's own bright blue for every button inside the content.
Nothing agreed with anything, and because every action was the same filled blue rectangle
there was no way to tell which of them mattered.

This palette does two things about that.

First, it commits to the teal. The logo is a teal gradient, so the teal is the brand and
everything else was an accident. `deep` is the dark end of that gradient and `teal` is the
one action colour.

Second - and this is the rule that actually fixes the "everything looks the same" problem -
`teal` is spent on ONE filled button per screen, and that button is the thing we want the
user to do next. Everything else is a plain row, a quiet outline, or a text link. If you
find yourself wanting a second filled teal button, the screen has two primary actions and
the answer is to decide which one it really is.

Naming is deliberately about the role, not the hue: `ink`, `slate`, `hairline`, `chalk`.
Renaming a colour then means changing one value here rather than hunting for "blue".
*/

import 'package:flutter/material.dart';

class AppPalette {
  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  // Near-black, cooled slightly towards the brand teal so it sits with the rest
  // rather than looking like a pasted-in grey.
  static const Color ink = Color(0xFF0C1F24);

  // Everything secondary: metadata, captions, the losing name in a scoreline.
  static const Color slate = Color(0xFF5C7076);

  // Text on top of `deep` or `teal`.
  static const Color onDark = Color(0xFFFFFFFF);

  // ---------------------------------------------------------------------------
  // Surfaces
  // ---------------------------------------------------------------------------

  // The page ground. Very slightly cool and green so white cards lift off it.
  static const Color chalk = Color(0xFFF2F5F4);

  // Cards, sheets, list rows.
  static const Color surface = Color(0xFFFFFFFF);

  // The one-pixel rules that do most of the structural work now that there are
  // far fewer boxes and shadows.
  static const Color hairline = Color(0xFFE1E8E7);

  // A slightly stronger rule, for the divider under a section heading.
  static const Color hairlineStrong = Color(0xFFCBD6D5);

  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------

  // The dark end of the logo gradient. App bars, the dashboard ground, anything
  // that should read as "the app itself" rather than as content.
  static const Color deep = Color(0xFF063C48);

  // A step lighter, used only for the dashboard's gradient so the header has
  // some depth without turning into a rainbow.
  static const Color deepLift = Color(0xFF0A5F66);

  // THE action colour. One filled button per screen. Nothing else.
  static const Color teal = Color(0xFF00857A);

  // Pressed / darker teal, and the colour for teal text on white.
  static const Color tealDeep = Color(0xFF006B62);

  // The tint behind teal - selected segments, the active chip, a highlighted row.
  static const Color tealTint = Color(0xFFE0EFEC);

  // ---------------------------------------------------------------------------
  // Stage
  //
  // The two stages of a league keep their existing meaning - amber for "still
  // yours to change", green for "running" - but retuned so they sit inside this
  // palette instead of shouting over it.
  // ---------------------------------------------------------------------------

  static const Color amber = Color(0xFF9A5B00);
  static const Color amberTint = Color(0xFFF7EEDF);

  static const Color pitch = Color(0xFF1B6E3B);
  static const Color pitchTint = Color(0xFFE4EFE7);

  // ---------------------------------------------------------------------------
  // Meaning
  // ---------------------------------------------------------------------------

  // Destructive. Used as *text* on a plain row, never as a filled red button -
  // a filled button invites the tap, and these are the actions we least want
  // tapped by accident.
  static const Color clay = Color(0xFFA6402C);
  static const Color clayTint = Color(0xFFF6E9E6);

  // Guests. Warm, and distinct from both stage colours.
  static const Color guest = Color(0xFF9A5B00);
  static const Color guestTint = Color(0xFFF7EEDF);

  // The dashboard's ground: the logo gradient, but only ever behind the header,
  // never behind content.
  static const List<Color> headerGradient = <Color>[deep, deepLift];
}
