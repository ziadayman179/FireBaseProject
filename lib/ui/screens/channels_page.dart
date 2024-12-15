import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:untitled/model/notification_channel.dart';
import 'package:untitled/services/firebase_service.dart';
import 'package:flutter/material.dart';

class ChannelsPage extends StatefulWidget {
  @override
  _ChannelsPageState createState() => _ChannelsPageState();
}

class _ChannelsPageState extends State<ChannelsPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _channelNameController = TextEditingController();
  final TextEditingController _channelDescriptionController =
      TextEditingController();

  void _addChannel() async {
    final channel = NotificationChannel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _channelNameController.text,
      description: _channelDescriptionController.text,
    );

    await _firebaseService.addChannel(channel);
    await _firebaseService.addChannelRealtimeDatabase(channel);

    setState(() {});
    _channelNameController.clear();
    _channelDescriptionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Manage Channels")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _channelNameController,
              decoration: const InputDecoration(labelText: "Channel Name"),
            ),
            TextField(
              controller: _channelDescriptionController,
              decoration: const InputDecoration(labelText: "Channel Description"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addChannel,
              child: const Text("Add Channel"),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('channels')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  final channels = snapshot.data!.docs.map((doc) {
                    return NotificationChannel.fromMap(
                      doc.data() as Map<String, dynamic>,
                    );
                  }).toList();

                  return ListView.builder(
                    itemCount: channels.length,
                    itemBuilder: (context, index) {
                      final channel = channels[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        child: ListTile(
                          title: Text(channel.name),
                          subtitle: Text(channel.description),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () async {
                              await _firebaseService.removeChannel(channel.id);
                              await _firebaseService.removeChannelRealtimeDatabase(channel.id);
                              setState(() {});
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
