import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/hand_drawn_widgets.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text: '您好！我是 Toastmasters 會議助手，可以幫您查詢會議、分會資訊，或報名角色。請問有什麼可以幫您的嗎？',
      isUser: false,
    ),
  ];
  final List<ChatMessage> _conversationHistory = [];
  bool _isTyping = false;
  String _statusMessage = 'ToastLab AI is typing...';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      appBar: AppBar(
        title: Text(
          'ToastLab AI',
          style: TextStyle(
            color: AppTheme.darkWood,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: CustomPaint(
        painter: CloudBackgroundPainter(),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                itemCount: _messages.length + (_isTyping ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length && _isTyping) {
                    return _buildTypingIndicator();
                  }
                  return _buildMessageBubble(_messages[index]);
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightWood.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppTheme.ricePaper,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.lightWood.withValues(alpha: 0.1),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(
                      color: AppTheme.lightWood.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onSubmitted: _sendMessage,
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => _sendMessage(_controller.text),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.sageGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.sageGreen.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: message.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          if (!message.isUser &&
              message.thoughtProcess != null &&
              message.thoughtProcess!.isNotEmpty)
            _buildThinkingProcess(message.thoughtProcess!),
          if (message.text.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: message.isUser
                      ? AppTheme.sageGreen.withValues(alpha: 0.15)
                      : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                    bottomRight: Radius.circular(message.isUser ? 4 : 20),
                  ),
                  border: Border.all(
                    color: message.isUser
                        ? AppTheme.sageGreen.withValues(alpha: 0.1)
                        : AppTheme.lightWood.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.lightWood.withValues(alpha: 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  message.text,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.darkWood,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          if (message.actions != null && message.actions!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: message.actions!.map((action) {
                  return _buildDynamicActionButton(action);
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildThinkingProcess(List<StepDetail> steps) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      constraints: const BoxConstraints(maxWidth: 280),
      // Use ExpansionTile-like behavior
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          childrenPadding: const EdgeInsets.only(
            left: 12,
            right: 12,
            bottom: 12,
          ),
          collapsedBackgroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          leading: Icon(
            Icons.psychology,
            color: AppTheme.lightWood.withValues(alpha: 0.6),
            size: 20,
          ),
          title: Text(
            'Thinking Process (${steps.length} steps)',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.lightWood.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          children: steps.map((step) {
            final isToolCall = step.stepType == 'tool_call';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isToolCall ? Icons.build_circle_outlined : Icons.output,
                    size: 16,
                    color: isToolCall ? Colors.blueGrey : Colors.green[700],
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step.label ?? step.content,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.darkWood.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDynamicActionButton(ActionButton action) {
    final color = action.actionType == 'signup_role'
        ? AppTheme.sageGreen
        : AppTheme.softPeach;
    final icon = action.actionType == 'signup_role'
        ? Icons.how_to_reg
        : Icons.info_outline;

    return GestureDetector(
      onTap: () => _handleActionButton(action),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              action.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleActionButton(ActionButton action) async {
    if (action.actionType == 'signup_role') {
      final roleName = action.payload['roleName'] as String?;
      final meetingId = action.payload['meetingId'];
      final roleSlotId = action.payload['roleSlotId'];

      // Send a message to confirm signup
      await _sendMessage('我要報名 $roleName (會議 #$meetingId, 角色 #$roleSlotId)');
    }
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12, left: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.sageGreen,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _statusMessage,
              style: TextStyle(color: AppTheme.lightWood, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isTyping) return;

    final userMessage = text.trim();
    _controller.clear();

    setState(() {
      _messages.add(_ChatMessage(text: userMessage, isUser: true));
      _isTyping = true;
      _statusMessage = 'ToastLab AI is typing...';
    });

    // Create a placeholder message for the assistant
    final assistantMessage = _ChatMessage(
      text: '',
      isUser: false,
      actions: [],
      thoughtProcess: [],
    );

    setState(() {
      _messages.add(assistantMessage);
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = FirebaseAuth.instance.currentUser;
      final userEmail = user?.email ?? 'anonymous';

      // Try to get name from AuthService member first (our backend profile),
      // otherwise fall back to Firebase displayName
      final userName =
          authService.member?['name'] as String? ?? user?.displayName;

      final StringBuffer messageBuffer = StringBuffer();

      await for (final chunk in _chatService.streamChat(
        userMessage,
        history: _conversationHistory,
        userEmail: userEmail,
        userName: userName,
      )) {
        setState(() {
          // Handle different chunk types
          if (chunk.type == 'text') {
            if (chunk.content != null) {
              messageBuffer.write(chunk.content);
              assistantMessage.text = messageBuffer.toString();
            }
          } else if (chunk.type == 'thought_start') {
            if (chunk.tool != null) {
              assistantMessage.thoughtProcess!.add(
                StepDetail(
                  stepType: 'tool_call',
                  content: chunk.tool!, // Store just tool name for display
                  label: chunk.toolLabel,
                ),
              );
              _statusMessage = 'Running ${chunk.toolLabel ?? chunk.tool}...';
            }
          } else if (chunk.type == 'thought_end') {
            // Find the last tool call and update it or add result
            if (assistantMessage.thoughtProcess!.isNotEmpty) {
              try {
                final index = assistantMessage.thoughtProcess!.lastIndexWhere(
                  (s) => s.stepType == 'tool_call' && s.content == chunk.tool,
                );
                if (index != -1) {
                  // Replace with a "done" version
                  final oldStep = assistantMessage.thoughtProcess![index];
                  assistantMessage.thoughtProcess![index] = StepDetail(
                    stepType: 'tool_done',
                    content: chunk.tool!,
                    label: oldStep.label,
                  );
                } else {
                  // Fallback
                  assistantMessage.thoughtProcess!.add(
                    StepDetail(
                      stepType: 'tool_result',
                      content: 'Finished ${chunk.tool}',
                      label: chunk.toolLabel,
                    ),
                  );
                }
              } catch (e) {
                print('Error updating thought process: $e');
              }
            }
          } else if (chunk.type == 'actions') {
            if (chunk.actions != null) {
              assistantMessage.actions!.addAll(chunk.actions!);
            }
          } else if (chunk.type == 'error') {
            messageBuffer.write('\n[Error: ${chunk.content}]');
            assistantMessage.text = messageBuffer.toString();
          }

          // Force scroll to bottom
          if (_scrollController.hasClients) {
            _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent,
            );
          }
        });
      }

      // Conversation history update
      _conversationHistory.add(ChatMessage(role: 'user', content: userMessage));
      _conversationHistory.add(
        ChatMessage(role: 'model', content: assistantMessage.text),
      );

      setState(() {
        _isTyping = false;
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(text: 'Error connection: $e', isUser: false),
        );
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _chatService.dispose();
    super.dispose();
  }
}

class _ChatMessage {
  String text;
  final bool isUser;
  List<ActionButton>? actions;
  List<StepDetail>? thoughtProcess;

  _ChatMessage({
    required this.text,
    required this.isUser,
    this.actions,
    this.thoughtProcess,
  });
}
