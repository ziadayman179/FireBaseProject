import 'package:flutter/material.dart';
import 'package:untitled/services/firebase_service.dart';
import 'package:untitled/model/notification_channel.dart';

class ManageSubscriptionsPage extends StatefulWidget {
  const ManageSubscriptionsPage({super.key});

  @override
  _ManageSubscriptionsPageState createState() =>
      _ManageSubscriptionsPageState();
}

class _ManageSubscriptionsPageState extends State<ManageSubscriptionsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<NotificationChannel> _channels = [];
  List<String> _userSubscriptions = [];

  @override
  void initState() {
    super.initState();
    _loadChannels();
    _loadUserSubscriptions();
  }

  void _loadChannels() async {
    final channels = await _firebaseService.getChannels();
    setState(() {
      _channels = channels;
    });
  }

  void _loadUserSubscriptions() async {
    final subscriptions = await _firebaseService.getUserSubscriptions();
    setState(() {
      _userSubscriptions = subscriptions;
    });
  }

  void _subscribeToChannel(String channelId) async {
    await _firebaseService.addOrUpdateSubscription(channelId);
    _loadUserSubscriptions();
  }

  void _unsubscribeFromChannel(String channelId) async {
    await _firebaseService.removeSubscription(channelId);
    _loadUserSubscriptions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Subscriptions"),
      ),
      body: _channels.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
        itemCount: _channels.length,
        itemBuilder: (context, index) {
          final channel = _channels[index];
          final isSubscribed = _userSubscriptions.contains(channel.id);

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title: Text(channel.name, style: const TextStyle(fontSize: 18)),
              subtitle: Text(channel.description),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSubscribed)
                    ElevatedButton(
                      onPressed: () => _unsubscribeFromChannel(channel.id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text("Unsubscribe"),
                    )
                  else
                    ElevatedButton(
                      onPressed: () => _subscribeToChannel(channel.id),
                      child: const Text("Subscribe"),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
