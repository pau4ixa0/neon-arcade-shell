import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:dynamic_shell_app/features/fallback_game/presentation/game_screen.dart';

void main() {
  testWidgets('Neon Flappy Arcade game loads properly', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: GameScreen(),
    ));

    // Verify game title is present
    expect(find.text('NEON FLAPPY ARCADE'), findsOneWidget);
    expect(find.text('SCORE'), findsOneWidget);
    expect(find.text('BEST RECORD'), findsOneWidget);
  });
}
