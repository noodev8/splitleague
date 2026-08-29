// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:splitleague_flutter/widgets/fixture_card.dart';

void main() {
  testWidgets('FixtureCard displays correctly', (WidgetTester tester) async {
    // Create test fixture data
    final testFixture = {
      'player_1_name': 'Player 1',
      'player_2_name': 'Player 2',
      'played': false,
    };

    // Build our widget and trigger a frame
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FixtureCard(
            fixture: testFixture,
          ),
        ),
      ),
    );

    // Verify that both player names are displayed
    expect(find.text('Player 1'), findsOneWidget);
    expect(find.text('Player 2'), findsOneWidget);
    
    // Verify that VS is shown for unplayed matches
    expect(find.text('VS'), findsOneWidget);
  });
}
