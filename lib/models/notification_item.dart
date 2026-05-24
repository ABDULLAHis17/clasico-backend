/// Notification Model
class NotificationItem {
  final String id;
  final String title;
  final String message;
  final DateTime timestamp;
  final String type; // 'match', 'news', 'transfer', 'general', 'message', 'game_invite'
  final bool isRead;
  final String? imageUrl;
  final String? relatedId; // ID of related match, news, etc.
  final String? senderId; // ID of the user who sent the message/invite
  final String? senderName; // Name of the user who sent the message/invite
  final String? senderAvatar; // Avatar of the user who sent the message/invite
  final String? gameId; // ID of the game for game invites

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.timestamp,
    this.type = 'general',
    this.isRead = false,
    this.imageUrl,
    this.relatedId,
    this.senderId,
    this.senderName,
    this.senderAvatar,
    this.gameId,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? timestamp,
    String? type,
    bool? isRead,
    String? imageUrl,
    String? relatedId,
    String? senderId,
    String? senderName,
    String? senderAvatar,
    String? gameId,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      relatedId: relatedId ?? this.relatedId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      gameId: gameId ?? this.gameId,
    );
  }
}
