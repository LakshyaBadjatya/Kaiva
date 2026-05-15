import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'ai_config.dart';

/// Thin client for the NVIDIA NIM OpenAI-compatible chat endpoint.
class NvidiaClient {
  NvidiaClient._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AiConfig.nvidiaBaseUrl,
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 25),
      headers: {
        'Authorization': 'Bearer ${AiConfig.nvidiaApiKey}',
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
  }

  static final NvidiaClient instance = NvidiaClient._internal();
  late final Dio _dio;

  /// Sends a chat completion. Returns the assistant message content,
  /// or null on any failure (caller should fall back gracefully).
  Future<String?> chat({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.6,
    int maxTokens = 512,
  }) async {
    if (!AiConfig.hasNvidiaKey) return null;
    try {
      final resp = await _dio.post('/chat/completions', data: {
        'model': AiConfig.nvidiaModel,
        'messages': [
          {'role': 'system', 'content': systemPrompt},
          {'role': 'user', 'content': userPrompt},
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
        'stream': false,
      });
      final choices = (resp.data?['choices'] as List<dynamic>?) ?? const [];
      if (choices.isEmpty) return null;
      final msg = choices.first['message'] as Map<String, dynamic>?;
      return msg?['content'] as String?;
    } catch (e) {
      debugPrint('NvidiaClient.chat failed: $e');
      return null;
    }
  }
}
