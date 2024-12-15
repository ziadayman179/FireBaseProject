import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:untitled/services/firebase_service.dart';
import 'package:untitled/ui/screens/auth.dart';
import 'package:untitled/ui/screens/home_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    name: 'lol',
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Setup Firebase Messaging Handlers
  FirebaseMessaging.onMessage.listen(FirebaseService.foregroundNotificationHandler);
  FirebaseMessaging.onBackgroundMessage(FirebaseService.backgroundNotificationHandler);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FCM Notification Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthStateWidget(),
    );
  }
}

class AuthStateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          User? user = snapshot.data;
          if (user == null) {
            // User is not signed in, show authentication page
            return AuthenticationPage();
          } else {
            // User is signed in, show home page
            return HomePage();
          }
        }

        // Show loading indicator while checking auth state
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}