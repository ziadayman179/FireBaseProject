import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:untitled/services/firebase_service.dart';
import 'package:untitled/services/userServices.dart';

class ChatPage extends StatefulWidget {
  final String channelId;

  const ChatPage({required this.channelId, super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}
//explain
class _ChatPageState extends State<ChatPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadUserName();
    _listenForMessages();
  }

  Future<void> _loadUserName() async {
    String? userName = await UserServices.getUserName();
    setState(() {
    });
  }

  void _listenForMessages() {
    _firebaseService.getMessages(widget.channelId);
    DatabaseReference messageRef = FirebaseDatabase.instance.ref('channels/${widget.channelId}/messages');

    messageRef.onChildAdded.listen((event) {
      if (event.snapshot.value != null) {
        final newMessage = Map<String, dynamic>.from(
            event.snapshot.value as Map<dynamic, dynamic>);
        setState(() {
          _messages.add(newMessage);
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
                  title: Text(
                    message['userName'] ?? 'Anonymous',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(message['message'] ?? ''),
                  trailing: Text(
                    _formatTimestamp(message['timestamp']),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
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
                  onPressed: () async {
                    final text = _controller.text.trim();
                    if (text.isNotEmpty) {
                      await _firebaseService.sendMessage(
                          widget.channelId,
                          text
                      );
                      _controller.clear();
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp).toLocal();
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid time';
    }
  }
}