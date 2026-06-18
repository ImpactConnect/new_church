import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/video_item.dart';

class YouTubeApiService {
  static const String _baseUrl = 'https://www.googleapis.com/youtube/v3';

  Future<List<VideoItem>> fetchChannelVideos({int maxResults = 10}) async {
    // Fetch settings from Firestore
    String? apiKey;
    String? channelId;
    try {
      final doc = await FirebaseFirestore.instance.collection('app_settings').doc('youtube').get();
      if (doc.exists) {
        apiKey = doc.data()?['apiKey'];
        channelId = doc.data()?['channelId'];
      }
    } catch (e) {
      throw Exception('Error fetching YouTube settings from Firestore: $e');
    }

    if (apiKey == null || apiKey.isEmpty || apiKey == 'YOUR_YOUTUBE_API_KEY' || 
        channelId == null || channelId.isEmpty || channelId == 'YOUR_CHANNEL_ID') {
      throw Exception('YouTube API Key or Channel ID not configured in admin settings.');
    }

    final url = Uri.parse(
        '$_baseUrl/search?key=$apiKey&channelId=$channelId&part=snippet,id&order=date&maxResults=$maxResults&type=video');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? [];

        return items.map((item) {
          final snippet = item['snippet'];
          final videoId = item['id']['videoId'];

          return VideoItem(
            id: videoId,
            title: snippet['title'] ?? 'Unknown Title',
            videoUrl: 'https://www.youtube.com/watch?v=$videoId',
            thumbnailUrl: snippet['thumbnails']?['high']?['url'] ?? 
                          snippet['thumbnails']?['default']?['url'] ?? '',
            description: snippet['description'] ?? '',
            category: 'YouTube Channel',
            videoType: VideoType.youtube,
            postedDate: DateTime.parse(snippet['publishedAt']),
            views: 0, // Search API doesn't return views; requires a separate /videos call
            likes: 0,
            isRecommended: false,
          );
        }).toList();
      } else {
        throw Exception('Failed to load YouTube videos: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching YouTube videos: $e');
    }
  }
}
