import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:courier/features/settings/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen displays toggles', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );

    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('Gloves Mode'), findsOneWidget);
    expect(find.text('Ping Interval (Location Tracking)'), findsOneWidget);
  });
}
