/*
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseMessagingService {

  static Future<void> foregroundNotificationHandler(RemoteMessage message) async {
    try {
      print('Foreground message: ${message.notification?.title}');

      DatabaseReference messageRef = FirebaseDatabase.instance.ref("message");
      await messageRef.push().set({
        'title': message.notification?.title,
        'body': message.notification?.body,
        'date': message.sentTime.toString(),
        'data': message.data,
      });
    } catch (e) {
      print('Error handling foreground message: $e');
    }
  }

  static Future<void> backgroundNotificationHandler(RemoteMessage message) async {
    try {
      print('Background message: ${message.notification?.title}');

      DatabaseReference messageRef = FirebaseDatabase.instance.ref("notification");
      await messageRef.push().set({
        'title': message.notification?.title,
        'body': message.notification?.body,
        'date': message.sentTime.toString(),
        'data': message.data,
      });
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
}
*//*

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/model/notification_channel.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:untitled/model/chat_message.dart';


class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  Future<void> addChannelRealtimeDatabase(NotificationChannel channel) async {
    try {
      final databaseReference = FirebaseDatabase.instance.ref();
      await databaseReference.child('channels/${channel.id}').set({
        'name': channel.name,
        'createdAt': ServerValue.timestamp,
      });
      print('Channel ${channel.id} added to Realtime Database');
    } catch (e) {
      print('Error adding channel: $e');
    }
  }


  Future<void> addChannel(NotificationChannel channel) async {
    try {
      await _firestore.collection('channels').add(channel.toMap());
      print("Channel added successfully");
    } catch (e) {
      print("Error adding channel: $e");
    }
  }

  Future<void> removeChannel(String channelId) async {
    try {
      // Remove the channel from 'channels' collection
      final channelQuery = await FirebaseFirestore.instance
          .collection('channels')
          .where('id', isEqualTo: channelId)
          .limit(1)
          .get();

      if (channelQuery.docs.isNotEmpty) {
        await channelQuery.docs.first.reference.delete();
        print("Channel removed successfully");
      } else {
        print("No channel found with the given id");
      }

      // Remove the channel references from 'topics' collection
      final topicsQuery = await FirebaseFirestore.instance
          .collection('topics')
          .where('channels', arrayContains: channelId)
          .get();

      for (var topicDoc in topicsQuery.docs) {
        await topicDoc.reference.update({
          'channels': FieldValue.arrayRemove([channelId])
        });
        print("Channel removed from topic: ${topicDoc.id}");
      }

      print("Channel removal process completed successfully.");
    } catch (e) {
      print("Error removing channel: $e");
    }
  }

  Future<List<NotificationChannel>> getChannels() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('channels').get();

      return snapshot.docs.map((doc) {
        return NotificationChannel.fromMap(doc.data());
      }).toList();
    } catch (e) {
      print('Error fetching channels: $e');
      return [];
    }
  }

  Future<List<NotificationChannel>> getSubscribedChannels(List<String> channelIds) async {
    List<NotificationChannel> channels = [];
    for (String channelId in channelIds) {
      final channelSnapshot = await FirebaseFirestore.instance.collection('channels').doc(channelId).get();
      if (channelSnapshot.exists) {
        channels.add(NotificationChannel.fromMap(channelSnapshot.data() as Map<String, dynamic>));
      }
    }
    return channels;
  }

  Future<void> addOrUpdateSubscription(String channelId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print('Error: Unable to retrieve FCM token');
        return;
      }

      CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

      QuerySnapshot userSnapshot =
      await usersRef.where('token', isEqualTo: token).limit(1).get();

      if (userSnapshot.docs.isNotEmpty) {
        DocumentReference userDoc = userSnapshot.docs.first.reference;
        await userDoc.update({
          'subscriptions.$channelId': true,
        });
        print('Subscription updated for existing user');
      } else {
        await usersRef.add({
          'token': token,
          'subscriptions': {
            channelId: true,
          },
          'user_id': 'user_${Timestamp.now().millisecondsSinceEpoch}',
        });
        print('New user created and subscription added');
      }
    } catch (e) {
      print('Error adding or updating subscription: $e');
    }
    await FirebaseMessaging.instance.subscribeToTopic(channelId);
  }

  static Future<void> foregroundNotificationHandler(RemoteMessage message) async {
    try {
      DatabaseReference messageRef = FirebaseDatabase.instance.ref("message");
      await messageRef.push().set({
        'title': message.notification?.title,
        'body': message.notification?.body,
        'date': message.sentTime.toString(),
        'data': message.data,
      });
    } catch (e) {
      print('Error handling foreground message: $e');
    }
  }

  static Future<void> backgroundNotificationHandler(RemoteMessage message) async {
    try {
      print('Background message: ${message.notification?.title}');

      DatabaseReference messageRef = FirebaseDatabase.instance.ref("notification");
      await messageRef.push().set({
        'title': message.notification?.title,
        'body': message.notification?.body,
        'date': message.sentTime.toString(),
        'data': message.data,
      });
    } catch (e) {
      print('Error handling background message: $e');
    }
  }

  static Stream<RemoteMessage> get onMessage {
    return FirebaseMessaging.onMessage;
  }

  Future<void> removeSubscription(String channelId) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print('Error: Unable to retrieve FCM token');
        return;
      }

      CollectionReference usersRef = FirebaseFirestore.instance.collection('users');

      QuerySnapshot userSnapshot =
      await usersRef.where('id', isEqualTo: token).limit(1).get();

      if (userSnapshot.docs.isNotEmpty) {
        DocumentReference userDoc = userSnapshot.docs.first.reference;

        await userDoc.update({
          'subscriptions.$channelId': FieldValue.delete(), // Remove the subscription
        });

        print('Subscription removed for user');
      } else {
        print('No user found with the given token');
      }
    } catch (e) {
      print('Error removing subscription: $e');
    }
    await FirebaseMessaging.instance.unsubscribeFromTopic(channelId);
  }

  Future<List<String>> getUserSubscriptions() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print('Error: Unable to retrieve FCM token');
        return [];
      }

      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('token', isEqualTo: token)
          .limit(1)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        DocumentSnapshot userDoc = userSnapshot.docs.first;

        Map<String, dynamic> subscriptions = userDoc['subscriptions'] ?? {};
        List<String> subscribedChannelIds = subscriptions.keys.toList();
        return subscribedChannelIds;
      } else {
        print('No user found with the given token');
        return [];
      }
    } catch (e) {
      print('Error fetching user subscriptions: $e');
      return [];
    }
  }

  Future<NotificationChannel?> getChannelById(String channelId) async {
    try {
      print("Fetching channel with ID: $channelId");

      final querySnapshot = await _firestore
          .collection('channels')
          .where('id', isEqualTo: channelId)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;

        print("Fetched channel data: ${doc.data()}");

        final channelData = doc.data();

        print("Mapping data to NotificationChannel: $channelData");
        return NotificationChannel.fromMap(channelData);
      } else {
        print("Channel not found for ID: $channelId");
        return null;
      }
    } catch (e) {
      print("Error fetching channel with ID: $channelId. Error: $e");
      return null;
    }
  }

  Future<void> sendMessage(String channelId, ChatMessage message) async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        print('Error: Unable to retrieve FCM token');
        return;
      }

      final userDocSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('token', isEqualTo: token)
          .limit(1)
          .get();

      if (userDocSnapshot.docs.isNotEmpty) {
        final userDoc = userDocSnapshot.docs.first;
        final userId = userDoc.data()['user_id'];

        final newMessage = ChatMessage(
          senderId: userId,
          message: message.message,
          timestamp: DateTime.now().millisecondsSinceEpoch,
        );

        final messageRef = _database.child('channels/$channelId/messages').push();
        await messageRef.set(newMessage.toMap());
      } else {
        print('No user found for this token.');
      }
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }


  Stream<List<ChatMessage>> getMessages(String channelId) {
    return _database
        .child('channels/$channelId/messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      final messages = <ChatMessage>[];
      final data = event.snapshot.value;

      if (data != null && data is Map) {
        final mapData = Map<String, dynamic>.from(data);
        mapData.forEach((key, value) {
          messages.add(ChatMessage.fromMap(Map<String, dynamic>.from(value)));
        });
      }

      return messages;
    });
  }

}

*/
