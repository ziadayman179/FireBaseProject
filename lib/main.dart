import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'services/firebase_messaging_service.dart';
import 'ui/screens/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
 await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

  FirebaseMessaging.onMessage.listen(FirebaseMessagingService.foregroundNotificationHandler);
  FirebaseMessaging.onBackgroundMessage(FirebaseMessagingService.backgroundNotificationHandler);

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
      home: const HomePage(),
    );
  }
}
