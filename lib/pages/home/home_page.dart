import 'package:chatbot_app_1/pages/home/provider/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:markdown_widget/widget/all.dart';
import 'package:provider/provider.dart';

class ChatbotHomeScreen extends StatefulWidget {
  const ChatbotHomeScreen({super.key});

  @override
  _ChatbotHomeScreenState createState() => _ChatbotHomeScreenState();
}

class _ChatbotHomeScreenState extends State<ChatbotHomeScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _sendMessage(GeminiApi geminiApi) async {
    if (_messageController.text.trim().isEmpty) return;

    String userMessage = _messageController.text.trim();
    _messageController.clear();

    await geminiApi.chatWithGemini(userMessage);

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Hero(
              tag: 'app_logo',
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PillowTalk',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: Color(0xFF10B981),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Always here for you',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages area
          Consumer<GeminiApi>(builder: (context, provider, _) {
            return Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: provider.messages.length,
                itemBuilder: (context, index) {
                  return MessageBubble(message: provider.messages[index]);
                },
              ),
            );
          }),

          // Input area
          Consumer<GeminiApi>(builder: (context, provider, _) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Text input field
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 120),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.4,
                          ),
                          decoration: InputDecoration(
                            fillColor: Colors.transparent,
                            filled: true,
                            hintText: "Message PillowTalk...",
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            errorBorder: InputBorder.none,
                            disabledBorder: InputBorder.none,
                            focusedErrorBorder: InputBorder.none,
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 15,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(provider),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Send button
                    GestureDetector(
                      onTap: provider.loading
                          ? null
                          : () {
                              _sendMessage(provider);
                            },
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          gradient: provider.loading
                              ? null
                              : const LinearGradient(
                                  colors: [
                                    Color(0xFF6366F1),
                                    Color(0xFF8B5CF6)
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: provider.loading ? Colors.grey[300] : null,
                          shape: BoxShape.circle,
                          boxShadow: provider.loading
                              ? null
                              : [
                                  BoxShadow(
                                    color: const Color(0xFF6366F1)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: provider.loading
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.grey[600]!),
                                ),
                              )
                            : const Icon(
                                Icons.arrow_upward_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class MessageBubble extends StatelessWidget {
  final Message message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: message.isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: message.isUser ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(message.isUser ? 20 : 4),
                      topRight: Radius.circular(message.isUser ? 4 : 20),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: MarkdownBlock(
                    data: message.text,
                    config: MarkdownConfig(
                      configs: [
                        PConfig(
                            textStyle: TextStyle(
                                color: message.isUser
                                    ? Colors.white
                                    : Colors.black)),
                        H1Config(
                            style: TextStyle(
                                color: message.isUser
                                    ? Colors.white
                                    : Colors.black)),
                        H2Config(
                            style: TextStyle(
                                color: message.isUser
                                    ? Colors.white
                                    : Colors.black)),
                        H3Config(
                            style: TextStyle(
                                color: message.isUser
                                    ? Colors.white
                                    : Colors.black)),
                        H4Config(
                            style: TextStyle(
                                color: message.isUser
                                    ? Colors.white
                                    : Colors.black)),
                        H5Config(
                            style: TextStyle(
                                color: message.isUser
                                    ? Colors.white
                                    : Colors.black)),
                        H6Config(
                            style: TextStyle(
                                color: message.isUser
                                    ? Colors.white
                                    : Colors.black)),
                        PreConfig(
                            textStyle: TextStyle(
                                color: message.isUser
                                    ? Colors.white
                                    : Colors.black)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 2),

                // Timestamp
                Padding(
                  padding: EdgeInsets.only(
                    left: message.isUser ? 0 : 8,
                    right: message.isUser ? 8 : 0,
                  ),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                // Action buttons for bot messages
                // if (!message.isUser) ...[
                //   const SizedBox(height: 8),
                //   Padding(
                //     padding: const EdgeInsets.only(left: 8),
                //     child: Row(
                //       mainAxisSize: MainAxisSize.min,
                //       children: [
                //         _ActionButton(
                //           icon: Icons.thumb_up_outlined,
                //           onTap: () => _onActionTap('like'),
                //         ),
                //         const SizedBox(width: 8),
                //         _ActionButton(
                //           icon: Icons.thumb_down_outlined,
                //           onTap: () => _onActionTap('dislike'),
                //         ),
                //         const SizedBox(width: 8),
                //         _ActionButton(
                //           icon: Icons.content_copy_rounded,
                //           onTap: () => _onActionTap('copy'),
                //         ),
                //       ],
                //     ),
                //   ),
                // ],
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.grey[400]!, Colors.grey[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white,
                size: 18,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
  }

  void _onActionTap(String action) {
    // Handle action button taps
    print('Action tapped: $action');
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 0.5,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}
