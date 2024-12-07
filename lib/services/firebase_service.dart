import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/model/notification_channel.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:untitled/model/chat_message.dart';


class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

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
      await FirebaseFirestore.instance.collection('channels').doc(channelId).delete();
      print("Channel removed successfully");
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
      await usersRef.where('token', isEqualTo: token).limit(1).get();

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
