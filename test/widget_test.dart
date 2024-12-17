import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:mockito/mockito.dart';
import 'package:untitled/main.dart';
import 'package:untitled/firebase_options.dart';

// Mock Firebase initialization for testing
abstract class MockFirebaseApp implements FirebaseApp {
  @override
  String get name => 'testApp';
}

void main() {
  setUpAll(() async {
    // Ensure Flutter binding is initialized
    TestWidgetsFlutterBinding.ensureInitialized();

    // Mock Firebase initialization
    try {
      await Firebase.initializeApp(
        name: 'testApp',
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e) {
      print('Firebase initialization error in test: $e');

      // Create a mock Firebase app if real initialization fails
      await Firebase.initializeApp(
        name: 'testApp',
        options: FirebaseOptions(
          apiKey: 'test-api-key',
          appId: 'test-app-id',
          messagingSenderId: 'test-messaging-sender-id',
          projectId: 'test-project-id',
        ),
      );
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