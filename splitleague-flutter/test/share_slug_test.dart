/*
Tests for the share slug on the app side.

Two things are worth pinning down, because both are assumptions that were wrong before and
would be easy to reintroduce:

  1. A league link's identifier is OPAQUE. It used to be assumed to be four digits. It is now
     normally a ten character share slug, and old links still carry codes, so nothing in the app
     may care about its length or shape.

  2. Somebody who arrives from a link sees NO code boxes. That is the whole point of the slug -
     it is ten characters, nobody is going to type it, and asking them to would turn an
     invitation into a wall.
*/

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:splitleague_flutter/helpers/deep_link_helper.dart';
import 'package:splitleague_flutter/screens/join_league_screen.dart';
import 'package:splitleague_flutter/widgets/pin_input.dart';

void main() {
  group('DeepLinkHelper.extractLeagueKey', () {
    test('pulls a share slug out of a league link', () {
      final uri = Uri.parse('https://splitleague.noodev8.com/l/7jwpbsz5ym');

      expect(DeepLinkHelper.extractLeagueKey(uri), '7jwpbsz5ym');
    });

    test(
      'still pulls a 4-digit code out of a link shared before slugs existed',
      () {
        final uri = Uri.parse('https://splitleague.noodev8.com/l/1231');

        expect(DeepLinkHelper.extractLeagueKey(uri), '1231');
      },
    );

    test('does not care how long the identifier is', () {
      // Nothing here validates the shape - the server decides what it has been handed. If this
      // ever starts returning null for an unfamiliar length, a length assumption has crept back.
      final uri = Uri.parse(
        'https://splitleague.noodev8.com/l/somethinglongerentirely',
      );

      expect(DeepLinkHelper.extractLeagueKey(uri), 'somethinglongerentirely');
    });

    test('refuses a link from any other host', () {
      final uri = Uri.parse('https://example.com/l/7jwpbsz5ym');

      expect(DeepLinkHelper.extractLeagueKey(uri), isNull);
    });

    test('refuses a link that is not a league link', () {
      expect(
        DeepLinkHelper.extractLeagueKey(
          Uri.parse('https://splitleague.noodev8.com/about/7jwpbsz5ym'),
        ),
        isNull,
      );

      expect(
        DeepLinkHelper.extractLeagueKey(
          Uri.parse('https://splitleague.noodev8.com/l'),
        ),
        isNull,
      );
    });
  });

  group('JoinLeagueScreen', () {
    testWidgets('shows the code boxes when somebody opened it to type a code', (
      tester,
    ) async {
      await tester.pumpWidget(const MaterialApp(home: JoinLeagueScreen()));
      await tester.pump();

      expect(find.byType(PinInput), findsOneWidget);

      // The eyebrow above the code boxes. Sentence case since the redesign - the
      // screen title carries the capital, not every heading on it.
      expect(find.text('Join a league'), findsWidgets);
    });

    testWidgets('shows NO code boxes when it was opened by a link', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: JoinLeagueScreen(leagueKey: '7jwpbsz5ym')),
      );
      await tester.pump();

      // The identifier came from the link. There is nothing for this person to type, and a row
      // of four boxes could not hold a ten character slug anyway.
      expect(find.byType(PinInput), findsNothing);
    });

    testWidgets('never puts the league key on screen', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: JoinLeagueScreen(leagueKey: '7jwpbsz5ym')),
      );
      await tester.pump();

      // A slug is an address, not something to show somebody. The screen names the league, not
      // the identifier it was reached by.
      expect(find.textContaining('7jwpbsz5ym'), findsNothing);
    });
  });
}
