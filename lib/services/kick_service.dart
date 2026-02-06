// lib/services/kick_service.dart

import 'package:dio/dio.dart';
import '../core/constants.dart';

class KickService {
  final Dio _dio = Dio();

  KickService() {
    _dio.options.headers = {
      'Accept': 'application/json',
      'User-Agent': 'Mozilla/5.0 (Linux; Android 13)',
    };
  }

  // Buscar canais em destaque
  Future<List<Map<String, dynamic>>> getFeaturedStreams() async {
    try {
      final response = await _dio.get(
        '${AppConstants.kickBaseUrl}/channels/featured',
      );

      if (response.statusCode == 200) {
        final data = response.data as List;
        return data.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      print('Error fetching Kick streams: $e');
      return [];
    }
  }

  // Buscar canal específico
  Future<Map<String, dynamic>?> getChannel(String username) async {
    try {
      final response = await _dio.get(
        '${AppConstants.kickBaseUrl}/channels/$username',
      );

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error fetching Kick channel: $e');
      return null;
    }
  }

  // Buscar M3U8 URL
  Future<String?> getStreamUrl(String username) async {
    try {
      final channelData = await getChannel(username);
      
      if (channelData == null) return null;

      final livestream = channelData['livestream'];
      if (livestream == null) return null;

      return livestream['playback_url'] as String?;
    } catch (e) {
      print('Error getting Kick stream URL: $e');
      return null;
    }
  }

  // Verificar se está ao vivo
  Future<bool> isLive(String username) async {
    try {
      final channelData = await getChannel(username);
      return channelData?['livestream'] != null;
    } catch (e) {
      return false;
    }
  }
}
