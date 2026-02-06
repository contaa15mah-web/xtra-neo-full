// lib/screens/player_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/twitch_service.dart';
import '../services/kick_service.dart';
import '../widgets/stream_player.dart';

class PlayerScreen extends StatefulWidget {
  final String username;
  final String platform;

  const PlayerScreen({
    Key? key,
    required this.username,
    required this.platform,
  }) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  String? _streamUrl;
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _streamInfo;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
      DeviceOrientation.portraitUp,
    ]);
    _loadStream();
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  Future<void> _loadStream() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (widget.platform == 'Twitch') {
        final service = TwitchService();
        final streamUrl = await service.getStreamUrl(widget.username);
        final streamData = await service.getStreamByUsername(widget.username);
        
        setState(() {
          _streamUrl = streamUrl;
          _streamInfo = streamData;
          _isLoading = false;
        });
      } else {
        final service = KickService();
        final streamUrl = await service.getStreamUrl(widget.username);
        final channelData = await service.getChannel(widget.username);
        
        setState(() {
          _streamUrl = streamUrl;
          _streamInfo = channelData?['livestream'];
          _isLoading = false;
        });
      }

      if (_streamUrl == null) {
        setState(() {
          _error = 'Stream not available';
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Player
            AspectRatio(
              aspectRatio: 16 / 9,
              child: _buildPlayer(),
            ),
            
            // Stream Info
            Expanded(
              child: _buildStreamInfo(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    if (_isLoading) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF9146FF),
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 64),
              const SizedBox(height: 16),
              Text(
                _error!,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStream,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_streamUrl == null) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Stream offline',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return StreamPlayer(
      streamUrl: _streamUrl!,
      channelName: widget.username,
      showControls: true,
    );
  }

  Widget _buildStreamInfo() {
    if (_streamInfo == null) {
      return Container();
    }

    String title = '';
    String? viewers;
    String? game;

    if (widget.platform == 'Twitch') {
      title = _streamInfo!['title'] ?? 'Untitled';
      viewers = _streamInfo!['viewer_count']?.toString();
      game = _streamInfo!['game_name'];
    } else {
      title = _streamInfo!['session_title'] ?? 'Untitled';
      viewers = _streamInfo!['viewer_count']?.toString();
      game = _streamInfo!['categories']?[0]?['name'];
    }

    return Container(
      color: const Color(0xFF121212),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Channel name
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFF9146FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    widget.username[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (game != null)
                      Text(
                        game,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              if (viewers != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4444),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.visibility, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        viewers,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            title,
            style: const TextStyle(fontSize: 16),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          
          const Spacer(),
          
          // Platform badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.platform == 'Twitch' 
                  ? const Color(0xFF9146FF) 
                  : const Color(0xFF53FC18),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              widget.platform,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
