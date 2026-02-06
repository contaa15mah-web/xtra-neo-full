// lib/services/twitch_service.dart

import 'package:dio/dio.dart';
import '../core/constants.dart';

class TwitchService {
  final Dio _dio = Dio();

  TwitchService() {
    _dio.options.headers = {
      'Client-ID': AppConstants.twitchClientId,
    };
  }

  // Buscar top streams
  Future<List<Map<String, dynamic>>> getTopStreams({int limit = 20}) async {
    try {
      final response = await _dio.get(
        '${AppConstants.twitchBaseUrl}/streams',
        queryParameters: {'first': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching Twitch streams: $e');
      return [];
    }
  }

  // Buscar stream por username
  Future<Map<String, dynamic>?> getStreamByUsername(String username) async {
    try {
      final response = await _dio.get(
        '${AppConstants.twitchBaseUrl}/streams',
        queryParameters: {'user_login': username},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        if (data.isNotEmpty) {
          return data[0] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching stream: $e');
      return null;
    }
  }

  // Buscar info do usuário
  Future<Map<String, dynamic>?> getUserInfo(String username) async {
    try {
      final response = await _dio.get(
        '${AppConstants.twitchBaseUrl}/users',
        queryParameters: {'login': username},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        if (data.isNotEmpty) {
          return data[0] as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Error fetching user info: $e');
      return null;
    }
  }

  // Buscar M3U8 URL usando GraphQL
  Future<String?> getStreamUrl(String username) async {
    const query = '''
    {
      streamPlaybackAccessToken(
        channelName: "%s",
        params: {
          platform: "android",
          playerBackend: "mediaplayer",
          playerType: "site"
        }
      ) {
        value
        signature
      }
    }
    ''';

    try {
      final response = await _dio.post(
        AppConstants.twitchGqlUrl,
        data: {'query': query.replaceFirst('%s', username)},
        options: Options(
          headers: {'Client-ID': AppConstants.twitchClientId},
        ),
      );

      if (response.statusCode == 200) {
        final token = response.data['data']['streamPlaybackAccessToken']['value'];
        final signature = response.data['data']['streamPlaybackAccessToken']['signature'];

        // Construir URL M3U8
        final m3u8Url = 'https://usher.ttvnw.net/api/channel/hls/$username.m3u8'
            '?token=$token'
            '&sig=$signature'
            '&allow_source=true'
            '&allow_audio_only=true';

        return m3u8Url;
      }
      return null;
    } catch (e) {
      print('Error getting stream URL: $e');
      return null;
    }
  }

  // Buscar games populares
  Future<List<Map<String, dynamic>>> getTopGames({int limit = 20}) async {
    try {
      final response = await _dio.get(
        '${AppConstants.twitchBaseUrl}/games/top',
        queryParameters: {'first': limit},
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] as List;
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching games: $e');
      return [];
    }
  }
}
