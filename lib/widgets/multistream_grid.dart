// lib/widgets/multistream_grid.dart

import 'package:flutter/material.dart';
import 'stream_player.dart';

class MultiStreamGrid extends StatefulWidget {
  const MultiStreamGrid({Key? key}) : super(key: key);

  @override
  State<MultiStreamGrid> createState() => _MultiStreamGridState();
}

class _MultiStreamGridState extends State<MultiStreamGrid> {
  final List<StreamData> _streams = [];

  void _addStream(String platform, String username, String streamUrl) {
    if (_streams.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum 4 streams')),
      );
      return;
    }

    setState(() {
      _streams.add(StreamData(
        platform: platform,
        username: username,
        streamUrl: streamUrl,
      ));
    });
  }

  void _removeStream(int index) {
    setState(() {
      _streams.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_streams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.grid_view,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No streams added',
              style: TextStyle(color: Colors.grey, fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showAddStreamDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Add Stream'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9146FF),
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      children: [
        _buildGrid(),
        
        // Add button
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _streams.length < 4 ? _showAddStreamDialog : null,
            backgroundColor: const Color(0xFF9146FF),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    if (_streams.length == 1) {
      return _buildStreamCard(0);
    } else if (_streams.length == 2) {
      return Column(
        children: [
          Expanded(child: _buildStreamCard(0)),
          Expanded(child: _buildStreamCard(1)),
        ],
      );
    } else {
      return Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildStreamCard(0)),
                if (_streams.length > 1) Expanded(child: _buildStreamCard(1)),
              ],
            ),
          ),
          if (_streams.length > 2)
            Expanded(
              child: Row(
                children: [
                  Expanded(child: _buildStreamCard(2)),
                  if (_streams.length > 3) Expanded(child: _buildStreamCard(3)),
                ],
              ),
            ),
        ],
      );
    }
  }

  Widget _buildStreamCard(int index) {
    final stream = _streams[index];
    
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF9146FF), width: 1),
      ),
      child: Stack(
        children: [
          StreamPlayer(
            streamUrl: stream.streamUrl,
            channelName: stream.username,
            showControls: _streams.length == 1,
          ),
          
          // Remove button
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => _removeStream(index),
              style: IconButton.styleFrom(
                backgroundColor: Colors.black.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddStreamDialog() {
    final usernameController = TextEditingController();
    String selectedPlatform = 'Twitch';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Stream'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: selectedPlatform,
              decoration: const InputDecoration(labelText: 'Platform'),
              items: ['Twitch', 'Kick'].map((platform) {
                return DropdownMenuItem(
                  value: platform,
                  child: Text(platform),
                );
              }).toList(),
              onChanged: (value) {
                selectedPlatform = value!;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Username',
                hintText: 'Enter channel name',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final username = usernameController.text.trim();
              if (username.isNotEmpty) {
                Navigator.pop(context);
                _loadAndAddStream(selectedPlatform, username);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9146FF),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadAndAddStream(String platform, String username) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      String? streamUrl;
      
      if (platform == 'Twitch') {
        final service = TwitchService();
        streamUrl = await service.getStreamUrl(username);
      } else {
        final service = KickService();
        streamUrl = await service.getStreamUrl(username);
      }

      Navigator.pop(context); // Close loading

      if (streamUrl != null) {
        _addStream(platform, username, streamUrl);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Stream not found: $username')),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}

class StreamData {
  final String platform;
  final String username;
  final String streamUrl;

  StreamData({
    required this.platform,
    required this.username,
    required this.streamUrl,
  });
}

// Import services
import '../services/twitch_service.dart';
import '../services/kick_service.dart';
