import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service for interacting with the Chat Backend (Gemini AI)
class ChatService {
  final http.Client _client;

  ChatService({http.Client? client}) : _client = client ?? http.Client();

  /// Send a message to the AI and get a response
  Future<ChatResponse> sendMessage(
    String message, {
    List<ChatMessage>? history,
  }) async {
    final body = {
      'message': message,
      if (history != null)
        'conversation_history': history.map((m) => m.toJson()).toList(),
    };

    final response = await _client
        .post(
          Uri.parse('${ApiConfig.chatBackendBaseUrl}${ApiConfig.chatEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(ApiConfig.receiveTimeout);

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      return ChatResponse(
        message: data['response'] as String,
        model: data['model'] as String,
      );
    }
    throw Exception('Chat failed: ${response.statusCode} - ${response.body}');
  }

  /// Check the health of the chat backend
  Future<Map<String, dynamic>> checkHealth() async {
    final response = await _client
        .get(Uri.parse('${ApiConfig.chatBackendBaseUrl}/health'))
        .timeout(ApiConfig.connectionTimeout);

    if (response.statusCode == 200) {
      return json.decode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Chat health check failed: ${response.statusCode}');
  }

  void dispose() {
    _client.close();
  }
}

class ChatMessage {
  final String role;
  final String content;

  ChatMessage({required this.role, required this.content});

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

class ChatResponse {
  final String message;
  final String model;

  ChatResponse({required this.message, required this.model});
}
