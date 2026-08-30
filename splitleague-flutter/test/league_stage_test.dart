// Tests for the league stage model and for the header that shows it.
//
// The stage is the app's one piece of real state - setting up, or in play - so the thing
// worth pinning down is that a league map coming back from the API is read the same way
// everywhere, including when the field is missing.
//
// The chip and the banner these tests used to cover are gone. The stage is now one line
// in SlLeagueHeader, which is where it is asserted instead.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitleague_flutter/helpers/league_stage.dart';
import 'package:splitleague_flutter/widgets/sl_league_header.dart';
import 'package:splitleague_flutter/widgets/sl_segmented.dart';

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

  testWidgets('the league header names the stage and what to do in it', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SlLeagueHeader(
            leagueName: 'Thursday Pool',
            stage: LeagueStage.inPlay,
            segments: const [SlSegment(label: 'Fixtures')],
            selectedIndex: 0,
            onBack: () {},
          ),
        ),
      ),
    );

    expect(find.text('Thursday Pool'), findsOneWidget);

    // The stage is one line: the name and the instruction, separated by a dot.
    expect(
      find.text('In play · Enter results as games are played'),
      findsOneWidget,
    );
  });

  testWidgets('the two stages never read the same', (
    WidgetTester tester,
  ) async {
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
