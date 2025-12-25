import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

/// Service for interacting with the Chat Backend (Gemini AI + MCP)
class ChatService {
  final http.Client _client;

  ChatService({http.Client? client}) : _client = client ?? http.Client();

  /// Send a message to the AI and get a response with optional actions
  Future<ChatResponse> sendMessage(
    String message, {
    List<ChatMessage>? history,
    String? userEmail,
  }) async {
    final body = {
      'message': message,
      if (history != null)
        'conversation_history': history.map((m) => m.toJson()).toList(),
      if (userEmail != null) 'user_email': userEmail,
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
      return ChatResponse.fromJson(data);
    }
    throw Exception('Chat failed: ${response.statusCode} - ${response.body}');
  }

  /// Stream a message to the AI and get updates via Stream
  Stream<ChatChunk> streamChat(
    String message, {
    List<ChatMessage>? history,
    String? userEmail,
    String? userName,
  }) async* {
    final body = {
      'message': message,
      if (history != null)
        'conversation_history': history.map((m) => m.toJson()).toList(),
      if (userEmail != null) 'user_email': userEmail,
      if (userName != null) 'user_name': userName,
    };

    final request =
        http.Request(
            'POST',
            Uri.parse(
              '${ApiConfig.chatBackendBaseUrl}${ApiConfig.chatEndpoint}',
            ),
          )
          ..headers['Content-Type'] = 'application/json'
          ..body = json.encode(body);

    final response = await _client.send(request);

    if (response.statusCode != 200) {
      throw Exception('Chat stream failed: ${response.statusCode}');
    }

    await for (final chunk
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      if (chunk.trim().isEmpty) continue;
      try {
        final data = json.decode(chunk) as Map<String, dynamic>;
        yield ChatChunk.fromJson(data);
      } catch (e) {
        // Ignore malformed chunks
      }
    }
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

/// Interactive action button from chat backend
class ActionButton {
  final String id;
  final String label;
  final String actionType;
  final Map<String, dynamic> payload;

  ActionButton({
    required this.id,
    required this.label,
    required this.actionType,
    required this.payload,
  });

  factory ActionButton.fromJson(Map<String, dynamic> json) {
    return ActionButton(
      id: json['id'] as String,
      label: json['label'] as String,
      actionType: json['action_type'] as String,
      payload: json['payload'] as Map<String, dynamic>,
    );
  }
}

class StepDetail {
  final String stepType;
  final String content;
  final String? label;

  StepDetail({required this.stepType, required this.content, this.label});

  factory StepDetail.fromJson(Map<String, dynamic> json) {
    return StepDetail(
      stepType: json['step_type'] as String,
      content: json['content'] as String,
      label: json['label'] as String?,
    );
  }
}

class ChatResponse {
  final String message;
  final String model;
  final List<ActionButton>? actions;
  final List<StepDetail>? thoughtProcess;

  ChatResponse({
    required this.message,
    required this.model,
    this.actions,
    this.thoughtProcess,
  });

  factory ChatResponse.fromJson(Map<String, dynamic> json) {
    List<ActionButton>? parsedActions;
    if (json['actions'] != null) {
      parsedActions = (json['actions'] as List<dynamic>)
          .map((a) => ActionButton.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    List<StepDetail>? parsedThoughtProcess;
    if (json['thought_process'] != null) {
      parsedThoughtProcess = (json['thought_process'] as List<dynamic>)
          .map((t) => StepDetail.fromJson(t as Map<String, dynamic>))
          .toList();
    }

    return ChatResponse(
      message: json['response'] as String,
      model: json['model'] as String,
      actions: parsedActions,
      thoughtProcess: parsedThoughtProcess,
    );
  }
}

class ChatChunk {
  final String type;
  final String? content;
  final String? tool;
  final String? toolLabel;
  final String? result;
  final List<ActionButton>? actions;

  ChatChunk({
    required this.type,
    this.content,
    this.tool,
    this.toolLabel,
    this.result,
    this.actions,
  });

  factory ChatChunk.fromJson(Map<String, dynamic> json) {
    List<ActionButton>? parsedActions;
    if (json['type'] == 'actions' && json['data'] != null) {
      parsedActions = (json['data'] as List<dynamic>)
          .map((a) => ActionButton.fromJson(a as Map<String, dynamic>))
          .toList();
    }

    return ChatChunk(
      type: json['type'] as String,
      content: json['content'] as String?,
      tool: json['tool'] as String?,
      toolLabel: json['tool_label'] as String?,
      result: json['result'] as String?,
      actions: parsedActions,
    );
  }
}
