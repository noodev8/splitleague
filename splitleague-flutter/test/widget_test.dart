// Tests for the scoreline - the unit the whole app is built on.
//
// It replaced FixtureCard, which this file used to test. The behaviour worth pinning
// down is not that it renders, but that it says who won without being read: an unplayed
// fixture must offer the way to enter a result, and a played one must mark the winner.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitleague_flutter/styles/app_palette.dart';
import 'package:splitleague_flutter/widgets/sl_scoreline.dart';

void main() {
  // Pump a scoreline on its own, with nothing else on screen to find.
  Future<void> pumpScoreline(WidgetTester tester, Widget scoreline) {
    return tester.pumpWidget(MaterialApp(home: Scaffold(body: scoreline)));
  }

  testWidgets(
    'an unplayed fixture invites a result rather than showing a score',
    (WidgetTester tester) async {
      await pumpScoreline(
        tester,
        SlScoreline(leftName: 'Player 1', rightName: 'Player 2', onTap: () {}),
      );

      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('Player 2'), findsOneWidget);

      // The point of the unplayed state: it asks for the result.
      expect(find.text('Enter'), findsOneWidget);
    },
  );

  testWidgets('a played fixture shows the score and marks the winner', (
    WidgetTester tester,
  ) async {
    await pumpScoreline(
      tester,
      const SlScoreline(
        leftName: 'Winner',
        rightName: 'Loser',
        leftScore: 3,
        rightScore: 1,
      ),
    );

    // An en dash, not a hyphen - see sl_scoreline.dart.
    expect(find.text('3 – 1'), findsOneWidget);
    expect(find.text('Enter'), findsNothing);

    // The winner stays in ink and the loser drops to slate, so the result is
    // legible without reading the numbers.
    final Text winner = tester.widget<Text>(find.text('Winner'));
    final Text loser = tester.widget<Text>(find.text('Loser'));

    expect(winner.style?.color, AppPalette.ink);
    expect(loser.style?.color, AppPalette.slate);
  });

  testWidgets(
    'a scoreline with no tap handler does not offer to enter a result',
    (WidgetTester tester) async {
      await pumpScoreline(
        tester,
        const SlScoreline(leftName: 'A', rightName: 'B'),
      );

      expect(find.text('Enter'), findsNothing);
    },
  );
}
