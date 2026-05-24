import '../models/notification_item.dart';

/// Service to manage notifications
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final List<NotificationItem> _notifications = [];

  // Get all notifications
  List<NotificationItem> getAll() => List.unmodifiable(_notifications);

  // Get unread count
  int getUnreadCount() => _notifications.where((n) => !n.isRead).length;

  // Add new notification
  void add(NotificationItem notification) {
    _notifications.insert(0, notification); // Add to beginning
  }

  // Mark as read
  void markAsRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  // Mark all as read
  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
  }

  // Delete notification
  void delete(String id) {
    _notifications.removeWhere((n) => n.id == id);
  }

  // Clear all notifications
  void clearAll() {
    _notifications.clear();
  }

  // Add message notification
  void addMessageNotification({
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String message,
  }) {
    add(NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: senderName,
      message: message,
      timestamp: DateTime.now(),
      type: 'message',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      isRead: false,
    ));
  }

  // Add game invite notification
  void addGameInviteNotification({
    required String senderId,
    required String senderName,
    required String senderAvatar,
    required String gameId,
    required String gameName,
  }) {
    add(NotificationItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: '$senderName يدعوك للعب',
      message: 'يريدك أن تلعب $gameName معه',
      timestamp: DateTime.now(),
      type: 'game_invite',
      senderId: senderId,
      senderName: senderName,
      senderAvatar: senderAvatar,
      gameId: gameId,
      isRead: false,
    ));
  }

  // Add sample notifications (for demo)
  void addSampleNotifications() {
    final now = DateTime.now();
    
    add(NotificationItem(
      id: '1',
      title: 'Match Starting Soon',
      message: 'Real Madrid vs Barcelona starts in 15 minutes',
      timestamp: now.subtract(const Duration(minutes: 5)),
      type: 'match',
      imageUrl: '⚽',
    ));

    add(NotificationItem(
      id: '2',
      title: 'Goal Alert!',
      message: 'Cristiano Ronaldo scored! Al-Nassr 1-0',
      timestamp: now.subtract(const Duration(hours: 1)),
      type: 'match',
      imageUrl: '🥅',
      isRead: false,
    ));

    add(NotificationItem(
      id: '3',
      title: 'Breaking News',
      message: 'Major transfer announcement expected today',
      timestamp: now.subtract(const Duration(hours: 2)),
      type: 'news',
      imageUrl: '📰',
      isRead: true,
    ));

    add(NotificationItem(
      id: '4',
      title: 'Transfer Complete',
      message: 'Jude Bellingham completes move to Real Madrid',
      timestamp: now.subtract(const Duration(hours: 5)),
      type: 'transfer',
      imageUrl: '✈️',
      isRead: true,
    ));

    add(NotificationItem(
      id: '5',
      title: 'Match Result',
      message: 'Manchester City 3-2 Liverpool - Full Time',
      timestamp: now.subtract(const Duration(hours: 8)),
      type: 'match',
      imageUrl: '🏆',
      isRead: true,
    ));
  }
}
