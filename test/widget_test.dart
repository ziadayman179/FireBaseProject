import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mockito/mockito.dart';
import 'package:untitled/main.dart';
import 'package:untitled/ui/screens/auth.dart';
import 'package:untitled/ui/screens/home_page.dart';

// Mock classes for Firebase services
class MockUser extends Mock implements User {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {
  final Stream<User?> _authStateStream;

  MockFirebaseAuth(this._authStateStream);

  @override
  Stream<User?> authStateChanges() => _authStateStream;
}

void main() {
  group('AuthStateWidget Tests', () {
    testWidgets('Shows AuthenticationPage when user is not signed in', (WidgetTester tester) async {
      // Mock FirebaseAuth to simulate user not being signed in
      final mockFirebaseAuth = MockFirebaseAuth(Stream.value(null));

      await tester.pumpWidget(
        MaterialApp(
          home: AuthStateWidget(),
        ),
      );

      expect(find.byType(AuthenticationPage), findsOneWidget);
    });

    testWidgets('Shows HomePage when user is signed in', (WidgetTester tester) async {
      // Mock FirebaseAuth to simulate user signed in
      final mockFirebaseAuth = MockFirebaseAuth(Stream.value(MockUser()));

      await tester.pumpWidget(
        MaterialApp(
          home: AuthStateWidget(),
        ),
      );

      expect(find.byType(HomePage), findsOneWidget);
    });

    testWidgets('Shows CircularProgressIndicator when checking auth state', (WidgetTester tester) async {
      final mockFirebaseAuth = MockFirebaseAuth(Stream.empty());

      await tester.pumpWidget(
        MaterialApp(
          home: AuthStateWidget(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  testWidgets('MyApp builds MaterialApp correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('FCM Notification Demo'), findsOneWidget);
  });
}
