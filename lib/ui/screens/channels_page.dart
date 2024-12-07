import 'package:flutter/material.dart';
import '../../model/notification_channel.dart';
import '../../services/firebase_messaging_service.dart';

class ChannelsPage extends StatelessWidget {
  ChannelsPage({super.key});

  final List<NotificationChannel> channels = [
    NotificationChannel(id: 'sports', name: 'Sports News', description: 'Get the latest sports updates'),
    NotificationChannel(id: 'technology', name: 'Tech News', description: 'Latest technology updates'),
    NotificationChannel(id: 'music', name: 'Music', description: 'Stay updated with music releases'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Channels"),
      ),
      body: ListView.builder(
        itemCount: channels.length,
        itemBuilder: (context, index) {
          final channel = channels[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    channel.description,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseMessagingService.subscribeToChannel(channel.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Subscribed to ${channel.name}')),
                          );
                        },
                        child: const Text('Subscribe'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          await FirebaseMessagingService.unsubscribeFromChannel(channel.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Unsubscribed from ${channel.name}')),
                          );
                        },
                        child: const Text('Unsubscribe'),
                      ),
                    ],
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
