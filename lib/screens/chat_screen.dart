import 'package:flutter/material.dart';
import '../models/message.dart';
import '../utils/app_strings.dart';
import '../utils/app_themes.dart';
import '../services/notification_service.dart';

class ChatScreen extends StatefulWidget {
  final String friendName;
  final String friendAvatar;

  const ChatScreen({
    Key? key,
    required this.friendName,
    required this.friendAvatar,
  }) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  late TextEditingController _messageController;
  late AnimationController _animationController;
  final List<Message> _messages = [];
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
    _scrollController = ScrollController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _animationController.forward();

    // Add sample messages
    _addSampleMessages();
  }

  void _addSampleMessages() {
    _messages.addAll([
      Message(
        id: '1',
        senderId: 'friend',
        senderName: widget.friendName,
        senderAvatar: widget.friendAvatar,
        content: 'Hello! How are you?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        isCurrentUser: false,
      ),
      Message(
        id: '2',
        senderId: 'current',
        senderName: 'You',
        senderAvatar: '😊',
        content: 'I\'m good, thanks for asking!',
        timestamp: DateTime.now().subtract(const Duration(minutes: 4)),
        isCurrentUser: true,
      ),
      Message(
        id: '3',
        senderId: 'friend',
        senderName: widget.friendName,
        senderAvatar: widget.friendAvatar,
        content: 'Did you watch the last match?',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        isCurrentUser: false,
      ),
    ]);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.isEmpty) return;

    final messageContent = _messageController.text;

    final newMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: 'current',
      senderName: 'You',
      senderAvatar: '😊',
      content: messageContent,
      timestamp: DateTime.now(),
      isCurrentUser: true,
    );

    setState(() {
      _messages.add(newMessage);
    });

    // إضافة إشعار للصديق
    NotificationService().addMessageNotification(
      senderId: 'current_user',
      senderName: 'You',
      senderAvatar: '😊',
      message: messageContent,
    );

    _messageController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return AppStrings.t(context, 'now');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} ${AppStrings.t(context, 'minutes_ago')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} ${AppStrings.t(context, 'hours_ago')}';
    } else {
      return '${time.day}/${time.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: AppThemes.backgroundGradient(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      colorScheme.primary.withValues(alpha: 0.3),
                      colorScheme.secondary.withValues(alpha: 0.3),
                    ],
                  ),
                  border: Border.all(
                    color: colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    widget.friendAvatar,
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.friendName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    AppStrings.t(context, 'opened'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Messages List
            Expanded(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                  CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return _buildMessageBubble(
                      context,
                      message,
                      isDark,
                      colorScheme,
                    );
                  },
                ),
              ),
            ),

            // Message Input
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.8),
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: MediaQuery.of(context).viewInsets.bottom + 12,
              ),
              child: Row(
                children: [
                  // Message Input Field
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: AppStrings.t(context, 'message'),
                          hintStyle: TextStyle(
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        style: TextStyle(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Send Button
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.8),
                        ],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _sendMessage,
                        borderRadius: BorderRadius.circular(28),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    BuildContext context,
    Message message,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: message.isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!message.isCurrentUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.3),
                    colorScheme.secondary.withValues(alpha: 0.3),
                  ],
                ),
                border: Border.all(
                  color: colorScheme.primary,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  message.senderAvatar,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  decoration: BoxDecoration(
                    gradient: message.isCurrentUser
                        ? LinearGradient(
                            colors: [
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.8),
                            ],
                          )
                        : LinearGradient(
                            colors: [
                              (isDark
                                  ? Colors.white.withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.2)),
                              (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.15)),
                            ],
                          ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(
                        message.isCurrentUser ? 20 : 4,
                      ),
                      bottomRight: Radius.circular(
                        message.isCurrentUser ? 4 : 20,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (message.isCurrentUser
                                ? colorScheme.primary
                                : Colors.black)
                            .withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Text(
                    message.content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: message.isCurrentUser
                          ? Colors.white
                          : colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: message.isCurrentUser ? 0 : 8,
                  ),
                  child: Text(
                    _formatTime(message.timestamp),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white54 : Colors.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message.isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }
}
