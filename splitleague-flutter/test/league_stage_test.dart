// Tests for the league stage model and the two widgets that show it.
//
// The stage is the app's one piece of real state - setting up, or in play - so the thing
// worth pinning down is that a league map coming back from the API is read the same way
// everywhere, including when the field is missing.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitleague_flutter/helpers/league_stage.dart';
import 'package:splitleague_flutter/widgets/league_stage_banner.dart';
import 'package:splitleague_flutter/widgets/league_stage_chip.dart';

void main() {
  group('LeagueStageInfo.fromLeague', () {
    test('a league with fixtures is in play', () {
      expect(
        LeagueStageInfo.fromLeague({'has_fixtures': true}),
        LeagueStage.inPlay,
      );
    });

    test('a league without fixtures is still being set up', () {
      expect(
        LeagueStageInfo.fromLeague({'has_fixtures': false}),
        LeagueStage.setup,
      );
    });

    test('a missing field falls back to setup, not to in play', () {
      // This is the case the old code got wrong by defaulting the other way in
      // places. Guessing "in play" tells somebody their league has started when it
      // may not have; guessing "setting up" is the harmless direction to be wrong in.
      expect(LeagueStageInfo.fromLeague({}), LeagueStage.setup);
      expect(
        LeagueStageInfo.fromLeague({'has_fixtures': null}),
        LeagueStage.setup,
      );
    });

    test('the camelCase spelling is accepted too', () {
      expect(
        LeagueStageInfo.fromLeague({'hasFixtures': true}),
        LeagueStage.inPlay,
      );
    });
  });

  group('LeagueStageInfo.fromHasFixtures', () {
    test('maps the bool the screens already hold', () {
      expect(LeagueStageInfo.fromHasFixtures(true), LeagueStage.inPlay);
      expect(LeagueStageInfo.fromHasFixtures(false), LeagueStage.setup);
    });
  });

  testWidgets('LeagueStageChip names the stage', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LeagueStageChip(stage: LeagueStage.setup),
      ),
    ));

    expect(find.text('Setting up'), findsOneWidget);
  });

  testWidgets('LeagueStageBanner explains what you can do', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: LeagueStageBanner(stage: LeagueStage.inPlay),
      ),
    ));

    expect(find.text('In play'), findsOneWidget);
    expect(
      find.text('Fixtures are set. Enter scores as games are played.'),
      findsOneWidget,
    );
  });

  testWidgets('the two stages never read the same', (WidgetTester tester) async {
    // A guard against someone later copying a label and forgetting to change it -
    // two stages that look identical on screen would defeat the entire point.
    expect(
      LeagueStageInfo.label(LeagueStage.setup),
      isNot(LeagueStageInfo.label(LeagueStage.inPlay)),
    );
    expect(
      LeagueStageInfo.description(LeagueStage.setup),
      isNot(LeagueStageInfo.description(LeagueStage.inPlay)),
    );
    expect(
      LeagueStageInfo.colour(LeagueStage.setup),
      isNot(LeagueStageInfo.colour(LeagueStage.inPlay)),
    );
  });
}
