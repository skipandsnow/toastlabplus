import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/chat_service.dart';
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
      text:
          'Hello! I noticed the TME role is available for 12/10. Would you like to sign up?',
      isUser: false,
      showActionButtons: true,
    ),
  ];
  final List<ChatMessage> _conversationHistory = [];
  bool _isTyping = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.ricePaper,
      appBar: AppBar(
        title: Text(
          'Assistant',
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
          if (message.showActionButtons)
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 4),
              child: Wrap(
                spacing: 8,
                children: [
                  _buildActionButton(
                    'Yes, sign me up',
                    AppTheme.sageGreen,
                    Icons.check,
                  ),
                  _buildActionButton(
                    'No thanks',
                    AppTheme.softPeach,
                    Icons.close,
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, IconData icon) {
    return GestureDetector(
      onTap: () => _sendMessage(label),
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
              label,
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
              'Assistant is typing...',
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
    });

    try {
      final response = await _chatService.sendMessage(
        userMessage,
        history: _conversationHistory,
      );
      _conversationHistory.add(ChatMessage(role: 'user', content: userMessage));
      _conversationHistory.add(
        ChatMessage(role: 'model', content: response.message),
      );

      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: response.message, isUser: false));
      });
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: 'Error connection', isUser: false));
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
  final String text;
  final bool isUser;
  final bool showActionButtons;
  _ChatMessage({
    required this.text,
    required this.isUser,
    this.showActionButtons = false,
  });
}
