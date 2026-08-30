/*
The type scale.

Two typefaces, each with one job.

  Archivo         the display face. Titles, league names, and every scoreline.
                  Archivo carries a WIDTH axis as well as a weight axis, and this
                  file sets it slightly expanded (105-108) for those roles. That
                  expansion is the thing that makes a league name or a scoreline
                  read like lettering on a board rather than like a heading in a
                  form, and it is the one deliberate flourish in the whole app.

  InstrumentSans  the body and interface face. Narrower and quieter than Archivo
                  on purpose, so the two never compete. All sentences, labels,
                  metadata and button text.

Both are variable fonts bundled in fonts/ (see pubspec.yaml), so the weight and width
are set through `fontVariations` rather than by shipping a dozen static files. The
matching `fontWeight` is set too - some text rendering paths use it for line breaking
and for the fallback face if the bundled font ever fails to load.

Sizes are not scaled here. The accessibility provider scales the whole app through
MediaQuery in main.dart, so a size written here is the size at 100%.
*/

import 'package:flutter/material.dart';
import 'app_palette.dart';

class AppType {
  static const String displayFamily = 'Archivo';
  static const String bodyFamily = 'InstrumentSans';

  // Build the variation list for the display face at a given weight and width.
  static List<FontVariation> _display(double weight, double width) {
    return <FontVariation>[
      FontVariation('wght', weight),
      FontVariation('wdth', width),
    ];
  }

  static List<FontVariation> _body(double weight) {
    return <FontVariation>[FontVariation('wght', weight)];
  }

  // Figures that line up in a column. Every number that sits in a table or a
  // scoreline uses this, so digits never jitter as scores change.
  static const List<FontFeature> _tabular = <FontFeature>[
    FontFeature.tabularFigures(),
  ];

  // ---------------------------------------------------------------------------
  // Display - Archivo, expanded
  // ---------------------------------------------------------------------------

  // The largest thing on a screen. Used for the dashboard greeting and for the
  // headline of an empty state, and nowhere else.
  static const TextStyle display = TextStyle(
    fontFamily: displayFamily,
    fontSize: 28,
    height: 1.15,
    letterSpacing: -0.6,
    fontWeight: FontWeight.w700,
    color: AppPalette.ink,
  );

  // A league name, a screen title, the name at the top of a card.
  static const TextStyle title = TextStyle(
    fontFamily: displayFamily,
    fontSize: 20,
    height: 1.2,
    letterSpacing: -0.3,
    fontWeight: FontWeight.w700,
    color: AppPalette.ink,
  );

  // The smaller title used inside a card or a sheet.
  static const TextStyle titleSmall = TextStyle(
    fontFamily: displayFamily,
    fontSize: 17,
    height: 1.25,
    letterSpacing: -0.2,
    fontWeight: FontWeight.w700,
    color: AppPalette.ink,
  );

  // A score. Tabular, heavy, expanded - the signature unit of the app.
  static const TextStyle score = TextStyle(
    fontFamily: displayFamily,
    fontSize: 22,
    height: 1.0,
    letterSpacing: 0.5,
    fontWeight: FontWeight.w800,
    fontFeatures: _tabular,
    color: AppPalette.ink,
  );

  // The same treatment at table size, for the standings columns.
  static const TextStyle figure = TextStyle(
    fontFamily: displayFamily,
    fontSize: 15,
    height: 1.2,
    fontWeight: FontWeight.w700,
    fontFeatures: _tabular,
    color: AppPalette.ink,
  );

  // ---------------------------------------------------------------------------
  // Body - Instrument Sans
  // ---------------------------------------------------------------------------

  // A sentence. There should be very few of these.
  static const TextStyle body = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: AppPalette.ink,
  );

  // Metadata under a title: "4 players", "Organised by Andreas".
  static const TextStyle meta = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 13,
    height: 1.35,
    fontWeight: FontWeight.w400,
    color: AppPalette.slate,
  );

  // The name of a person in a list or a scoreline.
  static const TextStyle name = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    height: 1.25,
    fontWeight: FontWeight.w600,
    color: AppPalette.ink,
  );

  // Button and row-action text.
  static const TextStyle action = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    height: 1.2,
    letterSpacing: 0.1,
    fontWeight: FontWeight.w600,
    color: AppPalette.ink,
  );

  // The small uppercase eyebrow that labels a section or states the stage.
  //
  // This is the app's main structural device. It is used only where the label
  // says something true that the content itself cannot - the stage of a league,
  // the name of a group of settings - never as decoration.
  static const TextStyle eyebrow = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 11,
    height: 1.2,
    letterSpacing: 0.9,
    fontWeight: FontWeight.w700,
    color: AppPalette.slate,
  );

  // The value shown against a label in a definition list.
  static const TextStyle value = TextStyle(
    fontFamily: bodyFamily,
    fontSize: 15,
    height: 1.3,
    fontWeight: FontWeight.w600,
    fontFeatures: _tabular,
    color: AppPalette.ink,
  );

  // ---------------------------------------------------------------------------
  // Applying the variable axes
  //
  // A const TextStyle cannot carry the FontVariation list, because the width
  // depends on the role. These helpers add it. Use them at the point of use:
  //
  //     Text(name, style: AppType.t(AppType.title))
  //
  // Anything that skips them still renders - the font falls back to its default
  // instance - it simply loses the expansion.
  // ---------------------------------------------------------------------------

  // Display roles: expanded, so titles and scores read as lettering.
  static TextStyle t(TextStyle base, {Color? color, double? size}) {
    final double weight = (base.fontWeight ?? FontWeight.w400).value.toDouble();

    // Scores are pushed a little wider than titles - they are the signature and
    // they are short, so they can carry it.
    final bool isScore =
        base.fontSize != null &&
        base.fontSize! >= 20 &&
        base.fontWeight == FontWeight.w800;

    return base.copyWith(
      color: color ?? base.color,
      fontSize: size ?? base.fontSize,
      fontVariations: _display(weight, isScore ? 108 : 105),
    );
  }

  // Body roles: default width, weight only.
  static TextStyle b(TextStyle base, {Color? color, double? size}) {
    final double weight = (base.fontWeight ?? FontWeight.w400).value.toDouble();

    return base.copyWith(
      color: color ?? base.color,
      fontSize: size ?? base.fontSize,
      fontVariations: _body(weight),
    );
  }
}
