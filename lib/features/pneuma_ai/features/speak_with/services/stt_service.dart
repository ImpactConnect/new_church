import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:church_mobile/features/bible_ai/services/ai_config_service.dart';

final sttServiceProvider = Provider<SttService>((ref) => SttService());

class SttService {
  /// Transcribes audio using the configured STT provider (e.g. whisper).
  Future<String?> transcribeAudio(String audioFilePath, String provider) async {
    try {
      if (provider == 'whisper') {
        return await _transcribeWithWhisper(audioFilePath);
      } else if (provider == 'deepgram') {
        return await _transcribeWithDeepgram(audioFilePath);
      } else {
        // Fallback or native implementation (if needed, native is handled by speech_to_text package directly in UI)
        debugPrint('STT provider $provider not explicitly handled via API.');
        return null;
      }
    } catch (e) {
      debugPrint('Error in SttService: $e');
      return null;
    }
  }

  Future<String?> _transcribeWithWhisper(String audioFilePath) async {
    final openAiKey = await AiConfigService.getSttApiKey('whisper');
    if (openAiKey == null || openAiKey.isEmpty) {
      debugPrint('Whisper API key is missing.');
      return null;
    }

    final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll({
        'Authorization': 'Bearer $openAiKey',
      })
      ..fields['model'] = 'whisper-1'
      ..fields['language'] = 'en'
      ..files.add(await http.MultipartFile.fromPath('file', audioFilePath));

    final response = await request.send();
    final responseData = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(responseData);
      return jsonResponse['text'];
    } else {
      debugPrint('Whisper API Error: $responseData');
      return null;
    }
  }

  Future<String?> _transcribeWithDeepgram(String audioFilePath) async {
    final deepgramKey = await AiConfigService.getSttApiKey('deepgram');
    if (deepgramKey == null || deepgramKey.isEmpty) {
      debugPrint('Deepgram API key is missing.');
      return null;
    }

    // Deepgram API setup
    final uri = Uri.parse('https://api.deepgram.com/v1/listen?model=nova-2&smart_format=true&language=en');
    final fileBytes = await http.MultipartFile.fromPath('file', audioFilePath);
    
    final response = await http.post(
      uri,
      headers: {
        'Authorization': 'Token $deepgramKey',
        'Content-Type': 'audio/m4a', // Adjust based on actual encoding
      },
      body: await fileBytes.finalize().toBytes(),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return jsonResponse['results']['channels'][0]['alternatives'][0]['transcript'];
    } else {
      debugPrint('Deepgram API Error: ${response.body}');
      return null;
    }
  }
}
