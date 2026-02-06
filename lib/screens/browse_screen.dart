// lib/screens/browse_screen.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/twitch_service.dart';
import '../services/kick_service.dart';
import 'player_screen.dart';

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({Key? key}) : super(key: key);

  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TwitchService _twitchService = TwitchService();
  final KickService _kickService = KickService();
  
  List<Map<String, dynamic>> _twitchStreams = [];
  List<Map<String, dynamic>> _kickStreams = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStreams();
  }

  Future<void> _loadStreams() async {
    setState(() => _isLoading = true);
    
    try {
      final twitchData = await _twitchService.getTopStreams(limit: 20);
      final kickData = await _kickService.getFeaturedStreams();
      
      setState(() {
        _twitchStreams = twitchData;
        _kickStreams = kickData;
      });
    } catch (e) {
      print('Error loading streams: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Streams'),
        backgroundColor: const Color(0xFF9146FF),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.play_arrow), text: 'Twitch'),
            Tab(icon: Icon(Icons.sports_esports), text: 'Kick'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildStreamList(_twitchStreams, 'Twitch'),
                _buildStreamList(_kickStreams, 'Kick'),
              ],
            ),
    );
  }

  Widget _buildStreamList(List<Map<String, dynamic>> streams, String platform) {
    if (streams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.videocam_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text('No streams available'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStreams,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadStreams,
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: streams.length,
        itemBuilder: (context, index) {
          final stream = streams[index];
          return _buildStreamCard(stream, platform);
        },
      ),
    );
  }

  Widget _buildStreamCard(Map<String, dynamic> stream, String platform) {
    String title;
    String username;
    String thumbnailUrl;
    String? viewers;
    String? gameName;

    if (platform == 'Twitch') {
      title = stream['title'] ?? 'Untitled';
      username = stream['user_name'] ?? 'Unknown';
      thumbnailUrl = (stream['thumbnail_url'] ?? '')
          .replaceAll('{width}', '400')
          .replaceAll('{height}', '225');
      viewers = stream['viewer_count']?.toString();
      gameName = stream['game_name'];
    } else {
      // Kick
      title = stream['session_title'] ?? stream['livestream']?['session_title'] ?? 'Untitled';
      username = stream['user']?['username'] ?? stream['slug'] ?? 'Unknown';
      thumbnailUrl = stream['thumbnail']?['url'] ?? 
                     stream['livestream']?['thumbnail']?['url'] ?? '';
      viewers = stream['viewer_count']?.toString() ?? 
                stream['livestream']?['viewer_count']?.toString();
      gameName = stream['category']?['name'] ?? 
                 stream['livestream']?['categories']?[0]?['name'];
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerScreen(
              username: username,
              platform: platform,
            ),
          ),
        );
      },
      child: Card(
        color: const Color(0xFF1E1E1E),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  thumbnailUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[900],
                            child: const Icon(Icons.image_not_supported),
                          ),
                        )
                      : Container(
                          color: Colors.grey[900],
                          child: const Icon(Icons.videocam, size: 48),
                        ),
                  
                  // Live indicator
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4444),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  
                  // Viewers
                  if (viewers != null)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              _formatViewers(viewers),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Info
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (gameName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      gameName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF9146FF),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatViewers(String viewers) {
    final count = int.tryParse(viewers) ?? 0;
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return viewers;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
