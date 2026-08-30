/*
The stage a league is in.

A league has exactly two stages, and which one it is in is decided by a single fact:
whether fixtures have been generated yet.

  Setting up  - no fixtures. People are still being added, scoring can still be changed,
                the join code still works. Nothing is fixed.
  In play     - fixtures exist. Scores get entered, the table means something, and nobody
                new can join (join_league.js returns FIXTURES_EXIST on purpose).

Generating fixtures is the one-way door between the two, and it is the only way through.

This was already the de facto state machine throughout the app - it gates joining, adding
guests, showing the code, the share wording and the public landing page - but it was never
named and never shown to the user. This file names it, so every screen says the same thing
in the same words instead of each one re-deciding what `hasFixtures` means.
*/

import 'package:flutter/material.dart';
import '../styles/app_palette.dart';

enum LeagueStage { setup, inPlay }

class LeagueStageInfo {
  // Work out the stage from a league map as the API returns it.
  //
  // `has_fixtures` is the field to trust - get_user_leagues and get_league_preview both
  // send it. The older `hasFixtures` spelling and a locally-set flag are accepted too,
  // because several screens build their own league maps as they navigate.
  //
  // The fallback when nothing is present is `setup`, and that is a deliberate choice
  // rather than an accident: a screen that has to guess should show the harmless stage,
  // not tell somebody their league has started when it may not have.
  static LeagueStage fromLeague(Map<String, dynamic> league) {
    final dynamic value = league['has_fixtures'] ?? league['hasFixtures'];

    if (value == true) return LeagueStage.inPlay;
    if (value == false) return LeagueStage.setup;

    // Anything else - null, a missing key, a string - is unknown, so assume setup.
    return LeagueStage.setup;
  }

  // The stage, or null when the league map simply does not say.
  //
  // Use this anywhere the stage is being *displayed*. `fromLeague` has to return
  // something and so it guesses; a badge on screen should not guess, because a league
  // labelled "Setting up" when nobody actually knows is worse than no label at all.
  //
  // It matters in practice: `has_fixtures` on the dashboard's league list is a new field,
  // so an app talking to a server that predates it gets null here and shows nothing,
  // rather than labelling every league on the dashboard as still being set up.
  static LeagueStage? knownFromLeague(Map<String, dynamic> league) {
    final dynamic value = league['has_fixtures'] ?? league['hasFixtures'];

    if (value == true) return LeagueStage.inPlay;
    if (value == false) return LeagueStage.setup;

    return null;
  }

  // The same question asked the other way round, for the many call sites that already
  // hold a plain bool.
  static LeagueStage fromHasFixtures(bool hasFixtures) {
    return hasFixtures ? LeagueStage.inPlay : LeagueStage.setup;
  }

  // The short name, as it appears on a chip or next to the league title.
  static String label(LeagueStage stage) {
    switch (stage) {
      case LeagueStage.setup:
        return 'Setting up';
      case LeagueStage.inPlay:
        return 'In play';
    }
  }

  // One short line saying what you do in this stage.
  //
  // This used to be a full sentence each, sitting in a three-line banner on every
  // league screen. It said the same thing every time you moved between tabs, which
  // is how a helpful sentence turns into wallpaper. It is now one clause on one
  // line, shown beside the stage name in the header - short enough to be read
  // rather than skipped.
  static String description(LeagueStage stage) {
    switch (stage) {
      case LeagueStage.setup:
        return 'Add players, then start it';
      case LeagueStage.inPlay:
        return 'Enter results as games are played';
    }
  }

  static IconData icon(LeagueStage stage) {
    switch (stage) {
      case LeagueStage.setup:
        return Icons.edit_outlined;
      case LeagueStage.inPlay:
        return Icons.sports_score;
    }
  }

  // Amber for setup, green for in play. Amber reads as "unfinished, still yours to
  // change"; green reads as "running". Both come from AppPalette so they sit inside
  // the app's palette rather than shouting over it - the old pair were Material's
  // stock amber and green and were the loudest thing on every league screen.
  static Color colour(LeagueStage stage) {
    switch (stage) {
      case LeagueStage.setup:
        return AppPalette.amber;
      case LeagueStage.inPlay:
        return AppPalette.pitch;
    }
  }

  // The tint used behind that colour on a chip.
  static Color background(LeagueStage stage) {
    switch (stage) {
      case LeagueStage.setup:
        return AppPalette.amberTint;
      case LeagueStage.inPlay:
        return AppPalette.pitchTint;
    }
  }
}
