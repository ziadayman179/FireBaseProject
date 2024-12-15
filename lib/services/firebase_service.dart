import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/model/notification_channel.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:untitled/services/userServices.dart';

import '../model/UserModel.dart';
import 'AnalyticsService.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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
  Future<void> removeChannelRealtimeDatabase(String channelId) async {
    try {
      final databaseReference = FirebaseDatabase.instance.ref();
      await databaseReference.child('channels/$channelId').remove();
      print('Channel $channelId removed from Realtime Database');
    } catch (e) {
      print('Error removing channel: $e');
    }
  }
  Future<UserModel?> getUserById(String userId) async {
    try {
      // Reference to the user node in the Realtime Database
      final DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$userId');

      // Fetch the user data
      final DataSnapshot snapshot = await userRef.get();

      if (snapshot.exists && snapshot.value != null) {
        // Convert the snapshot value to a Map<String, dynamic>
        final userData = Map<String, dynamic>.from(snapshot.value as Map);

        // Map the data to UserModel
        return UserModel.fromMap(userData);
      } else {
        print("No user found with ID: $userId");
        return null;
      }
    } catch (e) {
      print("Error fetching user with ID $userId: $e");
      return null;
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
  Future<void> addOrUpdateSubscription(String channelId) async {
    String? userId = await UserServices.getUserId();
    DatabaseReference userRef = FirebaseDatabase.instance.ref('subscriptions/users/$userId');
    await userRef.update({
      channelId: true,
    });
    await FirebaseMessaging.instance.subscribeToTopic(channelId);
    final analyticsService =AnalyticsService();
    analyticsService.subscribeToChannel(channelId, userId!);
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

  Future<void> unsubscribeFromChannelRealTimeDB(String channel) async {
      String? uid = await UserServices.getUserId();
      DatabaseReference userRef = FirebaseDatabase.instance.ref('subscriptions/users/$uid');
      userRef.child(channel).remove();
      await FirebaseMessaging.instance.unsubscribeFromTopic(channel);
      final analyticsService =AnalyticsService();
      analyticsService.unsubscribe(channel, uid!);
  }

  Future<List<String>> getUserSubscriptions() async {
    try {
      // Retrieve the current user's ID
      String? userId = await UserServices.getUserId();

      if (userId == null) {
        print('Error: Unable to retrieve user ID');
        return [];
      }
      DatabaseReference subRef =
      FirebaseDatabase.instance.ref("subscriptions/users/$userId");
      final DataSnapshot snapshot = await subRef.get();
      if (snapshot.exists && snapshot.value != null) {
        // Parse the snapshot data into a list of subscriptions
        final List<String> subscriptions =
        List<String>.from((snapshot.value as Map).keys);

        print("User subscriptions: $subscriptions");
        return subscriptions;
      } else {
        print("No subscriptions found for the user.");
        return [];
      }
    } catch (e) {
      print("Error fetching user subscriptions: $e");
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

  Future<void> sendMessage(String channelId, String message) async {
    try {
      final userId = await UserServices.getUserId();
      final userName = await UserServices.getUserName();

      if (userId == null) {
        print('Error: Could not retrieve user ID for message.');
        return;
      }

      final messageRef = FirebaseDatabase.instance.ref('channels/$channelId/messages').push();
      final timestamp = DateTime.now().toIso8601String();
      await messageRef.set({
        'message': message,
        'timestamp': timestamp,
        'userId': userId,
        'userName': userName ?? 'Anonymous',
      });
      print('Message sent successfully');
    } catch (e) {
      print('Error sending message: $e');
    }
  }


  void getMessages(String channelId) {
    DatabaseReference channelRef =
    FirebaseDatabase.instance.ref('channels/$channelId/messages');

    channelRef.onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        Map<String, dynamic> messageData =
        Map<String, dynamic>.from(event.snapshot.value as Map);
        print('New message in channel $channelId: $messageData');
      }
    });
  }

}
