import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:untitled/main.dart';
import 'package:untitled/firebase_options.dart';

void main() {
  // Ensure proper Firebase initialization for testing
  setUpAll(() async {
    // Ensure Flutter binding is initialized
    TestWidgetsFlutterBinding.ensureInitialized();

    // Try to handle different platform scenarios
    try {
      await Firebase.initializeApp(
        name: 'testApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      // If initialization fails, print the error for debugging
      print('Firebase initialization error: $e');

      // For GitHub Actions (Linux), you might need to mock or skip Firebase init
      // Alternatively, add a Linux configuration to firebase_options.dart
      if (Platform.isLinux) {
        print('Skipping Firebase initialization on Linux');
        // You might want to mock Firebase services here
      }
    }
  });

  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build the app and trigger a frame
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}