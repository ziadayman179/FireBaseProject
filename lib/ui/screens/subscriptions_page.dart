import 'package:flutter/material.dart';
import 'package:untitled/services/firebase_service.dart';
import 'package:untitled/ui/screens/chat_page.dart';
import 'package:untitled/model/notification_channel.dart';

class SubscriptionsPage extends StatefulWidget {
  const SubscriptionsPage({super.key});

  @override
  _ViewSubscriptionsPageState createState() => _ViewSubscriptionsPageState();
}

class _ViewSubscriptionsPageState extends State<SubscriptionsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<NotificationChannel?> _subscribedChannels = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserSubscriptions();
  }

  void _loadUserSubscriptions() async {
    try {
      final subscribedChannelIds = await _firebaseService.getUserSubscriptions();
      final subscribedChannels = await Future.wait(subscribedChannelIds.map((channelId) async {
        return await _firebaseService.getChannelById(channelId);
      }));

      setState(() {
        _subscribedChannels = subscribedChannels.whereType<NotificationChannel>().toList();
        _isLoading = false;
      });
    } catch (error) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load subscriptions. Please try again later.';
      });
      print('Error loading subscriptions: $error');
    }
  }

  void _startChat(String channelId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(channelId: channelId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Subscriptions"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text(_errorMessage!))
          : _subscribedChannels.isEmpty
          ? const Center(child: Text('You have no subscriptions.'))
          : ListView.builder(
        itemCount: _subscribedChannels.length,
        itemBuilder: (context, index) {
          final channel = _subscribedChannels[index];

          if (channel == null) {
            return const SizedBox.shrink();
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: ListTile(
              title: Text(channel.name),
              subtitle: Text(channel.description),
              trailing: IconButton(
                icon: const Icon(Icons.chat),
                onPressed: () => _startChat(channel.id),
              ),
            ),
          );
        },
      ),
    );
  }
}
