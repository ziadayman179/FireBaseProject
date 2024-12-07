import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:untitled/model/chat_message.dart'; // For ChatMessage class
import 'package:untitled/services/firebase_service.dart'; // For FirebaseService class


class ChatPage extends StatefulWidget {
  final String channelId;

  const ChatPage({required this.channelId, super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _controller = TextEditingController();
  List<ChatMessage> _messages = [];

  @override
  void initState() {
    super.initState();
    _firebaseService.getMessages(widget.channelId).listen((messages) {
      setState(() {
        _messages = messages;
      });
    });
  }

  void _sendMessage() async {
    if (_controller.text.isNotEmpty) {
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
            message: _controller.text,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          );

          await _firebaseService.sendMessage(widget.channelId, newMessage);

          _controller.clear();
        } else {
          print('No user found for this token.');
        }
      } catch (error) {
        print('Failed to send message: $error');
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Room'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return ListTile(
                  title: Text(message.senderId),
                  subtitle: Text(message.message),
                  trailing: Text(DateTime.fromMillisecondsSinceEpoch(message.timestamp).toLocal().toString()),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Type your message',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
