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

enum LeagueStage {
  setup,
  inPlay,
}

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

  // One line saying what you can do in this stage. This is the sentence that does the
  // actual work of explaining the app, so it is written for somebody who has never seen
  // it before.
  static String description(LeagueStage stage) {
    switch (stage) {
      case LeagueStage.setup:
        return 'Add players and set the scoring. The league starts when you generate fixtures.';
      case LeagueStage.inPlay:
        return 'Fixtures are set. Enter scores as games are played.';
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
  // change"; green reads as "running". Both are dark enough for white text.
  static Color colour(LeagueStage stage) {
    switch (stage) {
      case LeagueStage.setup:
        return const Color(0xFFB26A00);
      case LeagueStage.inPlay:
        return const Color(0xFF2E7D32);
    }
  }

  // The tint used behind that colour on a chip or banner.
  static Color background(LeagueStage stage) {
    switch (stage) {
      case LeagueStage.setup:
        return const Color(0xFFFFF4E0);
      case LeagueStage.inPlay:
        return const Color(0xFFE7F4E8);
    }
  }
}
