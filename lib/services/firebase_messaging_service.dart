import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';

import '../firebase_options.dart';

class FirebaseMessagingService {

  static Future<void> foregroundNotificationHandler(RemoteMessage message) async {
    try {
      print('Foreground message: ${message.notification?.title}');

      DatabaseReference messageRef = FirebaseDatabase.instance.ref("message");
      try {
        await messageRef.push().set({
          'title': message.notification?.title,
          'body': message.notification?.body,
          'date': message.sentTime.toString(),
          'data': message.data,
        });
      } catch (dbError) {
        print('Detailed Database Error: $dbError');
        // Print more details about the error
        print('Database Reference: ${messageRef.path}');
      }
    } catch (e) {
      print('Error handling foreground message: $e');
    }
  }

// Do the same for backgroundNotificationHandler
  static Future<void> backgroundNotificationHandler(RemoteMessage message) async {
    try {
      print('Background message: ${message.notification?.title}');

      DatabaseReference messageRef = FirebaseDatabase.instance.ref("notification");
      try {
        await messageRef.push().set({
          'title': message.notification?.title,
          'body': message.notification?.body,
          'date': message.sentTime.toString(),
          'data': message.data,
        });
      } catch (dbError) {
        print('Detailed Database Error: $dbError');
        // Print more details about the error
        print('Database Reference: ${messageRef.path}');
      }
    } catch (e) {
      print('Error handling background message: $e');
    }
  }

  static Stream<RemoteMessage> get onMessage {
    return FirebaseMessaging.onMessage;
  }

  static Future<void> subscribeToChannel(String channelId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        DatabaseReference usersRef = FirebaseDatabase.instance.ref('users');
        DataSnapshot snapshot = await usersRef.get();

        bool tokenExists = false;
        String userId = '';

        if (snapshot.exists) {
          Map<dynamic, dynamic> usersData = snapshot.value as Map<dynamic, dynamic>;

          usersData.forEach((key, value) {
            if (value['token'] == token) {
              tokenExists = true;
              userId = key;
            }
          });
        }

        if (!tokenExists) {
          userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
          await usersRef.child(userId).set({
            'token': token,
            'subscriptions': {},
          });
          print('New user created with ID: $userId');
        }

        DatabaseReference userSubscriptionsRef =
        usersRef.child('$userId/subscriptions');

        await userSubscriptionsRef.update({
          channelId: true,
        });

        await FirebaseMessaging.instance.subscribeToTopic(channelId);
        print('User $userId subscribed to $channelId');
      } else {
        print('Error: Unable to get token');
      }
    } catch (e) {
      print('Error subscribing to channel $channelId: $e');
    }
  }

  // Unsubscribe user from a channel
  static Future<void> unsubscribeFromChannel(String channelId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        DatabaseReference usersRef = FirebaseDatabase.instance.ref('users');
        DataSnapshot snapshot = await usersRef.get();
        String? userId;

        if (snapshot.exists) {
          Map<dynamic, dynamic> usersData = snapshot.value as Map<dynamic, dynamic>;

          usersData.forEach((key, value) {
            if (value['token'] == token) {
              userId = key;
            }
          });
        }

        if (userId != null) {
          DatabaseReference userSubscriptionsRef =
          usersRef.child('$userId/subscriptions');
          await userSubscriptionsRef.child(channelId).remove();

          await FirebaseMessaging.instance.unsubscribeFromTopic(channelId);
          print('User $userId unsubscribed from $channelId');
        } else {
          print('Error: No user found for token $token');
        }
      } else {
        print('Error: Unable to get token');
      }
    } catch (e) {
      print('Error unsubscribing from channel $channelId: $e');
    }
  }
  static Future<String?> getDeviceToken() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      String? token = await FirebaseMessaging.instance.getToken();

      if (token != null) {
        print('Device Token: $token');
      } else {
        print('Failed to get device token.');
      }

      return token;
    } catch (e) {
      print('Error retrieving device token: $e');
      return null;
    }
  }
}

