import 'package:flutter/material.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';
import '../utils/app_strings.dart';
import '../utils/app_themes.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _notificationService = NotificationService();
  int _selectedTab = 0; // 0 = Football News, 1 = Account

  @override
  void initState() {
    super.initState();
    // Add sample notifications if empty
    if (_notificationService.getAll().isEmpty) {
      _notificationService.addSampleNotifications();
      // إضافة إشعارات تجريبية إضافية
      _addMoreSampleNotifications();
    }
  }

  void _showNotificationDetails(NotificationItem notification) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[900] : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with icon and close button
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _getTypeColor(notification.type),
                      _getTypeColor(notification.type).withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: notification.imageUrl != null &&
                              notification.imageUrl!.length <= 2
                          ? Text(
                              notification.imageUrl!,
                              style: const TextStyle(fontSize: 32),
                            )
                          : Icon(
                              _getTypeIcon(notification.type),
                              color: Colors.white,
                              size: 32,
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getNotificationTypeLabel(notification.type),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.8),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notification.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.t(context, 'details'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        notification.message,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: isDark ? Colors.grey[200] : Colors.grey[800],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: isDark ? Colors.grey[500] : Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _getTimeAgo(notification.timestamp, context),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[500] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Action buttons
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(AppStrings.t(context, 'close')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                          foregroundColor: isDark ? Colors.white : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _handleNotificationAction(notification);
                        },
                        icon: const Icon(Icons.check_circle, size: 18),
                        label: Text(AppStrings.t(context, 'confirm')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _getTypeColor(notification.type),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  String _getNotificationTypeLabel(String type) {
    switch (type) {
      case 'match':
        return 'Match';
      case 'news':
        return 'News';
      case 'transfer':
        return 'Transfer';
      case 'message':
        return AppStrings.t(context, 'new_message');
      case 'game_invite':
        return AppStrings.t(context, 'game_invite');
      default:
        return 'Notification';
    }
  }

  void _handleNotificationAction(NotificationItem notification) {
    // يمكن إضافة إجراءات مختلفة حسب نوع الإشعار
    switch (notification.type) {
      case 'message':
        // الانتقال إلى شاشة الرسائل
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t(context, 'opening_chat')),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'game_invite':
        // الانتقال إلى شاشة الألعاب
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t(context, 'opening_game')),
            backgroundColor: Colors.pink,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      case 'match':
        // الانتقال إلى تفاصيل المباراة
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t(context, 'opening_match')),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.t(context, 'notification_confirmed')),
            backgroundColor: Colors.grey,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  void _addMoreSampleNotifications() {
    // إشعارات كرة القدم إضافية
    _notificationService.add(NotificationItem(
      id: 'extra1',
      title: 'Match Starting Soon',
      message: 'Manchester United vs Liverpool starts in 30 minutes',
      type: 'match',
      timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
      isRead: false,
      imageUrl: '⚽',
    ));
    
    _notificationService.add(NotificationItem(
      id: 'extra2',
      title: 'Transfer News',
      message: 'Kylian Mbappé signs new contract with Real Madrid',
      type: 'transfer',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      imageUrl: '🔄',
    ));
    
    _notificationService.add(NotificationItem(
      id: 'extra3',
      title: 'Breaking News',
      message: 'Cristiano Ronaldo breaks another goal-scoring record',
      type: 'news',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: true,
      imageUrl: '📰',
    ));
    
    // إشعارات الحساب إضافية
    _notificationService.add(NotificationItem(
      id: 'extra4',
      title: 'New Message',
      message: 'Ahmed: Hey! Want to play a game?',
      type: 'message',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      isRead: false,
      imageUrl: '💬',
    ));
    
    _notificationService.add(NotificationItem(
      id: 'extra5',
      title: 'Game Invite',
      message: 'Fatima invited you to play Guess The Player',
      type: 'game_invite',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: false,
      imageUrl: '🎮',
    ));
  }

  List<NotificationItem> _getFootballNotifications() {
    return _notificationService.getAll().where((n) {
      return n.type == 'match' || n.type == 'news' || n.type == 'transfer';
    }).toList();
  }

  List<NotificationItem> _getAccountNotifications() {
    return _notificationService.getAll().where((n) {
      return n.type == 'message' || n.type == 'game_invite' || n.type == 'general';
    }).toList();
  }

  String _getTimeAgo(DateTime timestamp, BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return AppStrings.t(context, 'just_now');
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}${AppStrings.t(context, 'minutes_ago_short')}';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}${AppStrings.t(context, 'hours_ago_short')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}${AppStrings.t(context, 'days_ago_short')}';
    } else {
      return '${(difference.inDays / 7).floor()}${AppStrings.t(context, 'weeks_ago_short')}';
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'match':
        return Colors.green;
      case 'news':
        return Colors.blue;
      case 'transfer':
        return Colors.orange;
      case 'message':
        return Colors.purple;
      case 'game_invite':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'match':
        return Icons.sports_soccer;
      case 'news':
        return Icons.article;
      case 'transfer':
        return Icons.flight_takeoff;
      case 'message':
        return Icons.message;
      case 'game_invite':
        return Icons.sports_esports;
      default:
        return Icons.notifications;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final footballNotifications = _getFootballNotifications();
    final accountNotifications = _getAccountNotifications();
    final currentNotifications = _selectedTab == 0 ? footballNotifications : accountNotifications;

    return Scaffold(
      backgroundColor: isDark ? null : Colors.grey[100],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.t(context, 'notifications'),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${_notificationService.getAll().length} ${AppStrings.t(context, 'notifications')}',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        elevation: 0,
        flexibleSpace: Container(
          decoration: AppThemes.primaryGradient(context),
        ),
        actions: [
          if (currentNotifications.isNotEmpty)
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.more_vert, size: 24),
              ),
              onSelected: (value) {
                if (value == 'mark_all_read') {
                  setState(() {
                    _notificationService.markAllAsRead();
                  });
                } else if (value == 'clear_all') {
                  setState(() {
                    _notificationService.clearAll();
                  });
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mark_all_read',
                  child: Row(
                    children: [
                      const Icon(Icons.done_all, size: 20, color: Colors.green),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.t(context, 'mark_all_as_read'),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'clear_all',
                  child: Row(
                    children: [
                      const Icon(Icons.clear_all, size: 20, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(
                        AppStrings.t(context, 'clear_all'),
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Tabs - محسّنة جماليًا
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 0
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _selectedTab == 0
                                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.sports_soccer,
                                      color: _selectedTab == 0
                                          ? theme.colorScheme.primary
                                          : (isDark ? Colors.grey[400] : Colors.grey),
                                      size: 28,
                                    ),
                                  ),
                                  if (footballNotifications.isNotEmpty)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.red.shade400,
                                              Colors.red.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withValues(alpha: 0.5),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          footballNotifications.length.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.t(context, 'football_news'),
                            style: TextStyle(
                              fontWeight: _selectedTab == 0
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _selectedTab == 0
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.grey[400] : Colors.grey),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == 1
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 4,
                          ),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _selectedTab == 1
                                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Icon(
                                      Icons.account_circle,
                                      color: _selectedTab == 1
                                          ? theme.colorScheme.primary
                                          : (isDark ? Colors.grey[400] : Colors.grey),
                                      size: 28,
                                    ),
                                  ),
                                  if (accountNotifications.isNotEmpty)
                                    Positioned(
                                      right: -4,
                                      top: -4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Colors.red.shade400,
                                              Colors.red.shade600,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.red.withValues(alpha: 0.5),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Text(
                                          accountNotifications.length.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppStrings.t(context, 'account_notifications'),
                            style: TextStyle(
                              fontWeight: _selectedTab == 1
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: _selectedTab == 1
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.grey[400] : Colors.grey),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Notifications List
          Expanded(
            child: currentNotifications.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_none,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          AppStrings.t(context, 'no_notifications'),
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedTab == 0
                              ? AppStrings.t(context, 'no_football_news')
                              : AppStrings.t(context, 'no_account_notifications'),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: currentNotifications.length,
                    itemBuilder: (context, index) {
                      final notification = currentNotifications[index];
                      return Dismissible(
                        key: Key(notification.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          color: Colors.red,
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        onDismissed: (direction) {
                          setState(() {
                            _notificationService.delete(notification.id);
                          });
                          // Removed SnackBar
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: notification.isRead
                                ? (isDark ? Colors.grey[850] : Colors.white)
                                : (isDark
                                    ? Colors.blue[900]?.withValues(alpha: 0.3)
                                    : Colors.blue[50]),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: notification.isRead
                                  ? Colors.transparent
                                  : _getTypeColor(notification.type).withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getTypeColor(notification.type)
                                    .withValues(alpha: notification.isRead ? 0.02 : 0.1),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            leading: Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _getTypeColor(notification.type).withValues(alpha: 0.2),
                                    _getTypeColor(notification.type).withValues(alpha: 0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _getTypeColor(notification.type).withValues(alpha: 0.3),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: notification.imageUrl != null &&
                                        notification.imageUrl!.length <= 2
                                    ? Text(
                                        notification.imageUrl!,
                                        style: const TextStyle(fontSize: 28),
                                      )
                                    : Icon(
                                        _getTypeIcon(notification.type),
                                        color: _getTypeColor(notification.type),
                                        size: 28,
                                      ),
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontWeight: notification.isRead
                                          ? FontWeight.w600
                                          : FontWeight.bold,
                                      fontSize: 16,
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (!notification.isRead)
                                  Container(
                                    width: 10,
                                    height: 10,
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          theme.colorScheme.primary,
                                          theme.colorScheme.primary.withValues(alpha: 0.7),
                                        ],
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 8),
                                Text(
                                  notification.message,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? Colors.grey[300]
                                        : Colors.grey[800],
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12,
                                      color: isDark
                                          ? Colors.grey[500]
                                          : Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _getTimeAgo(notification.timestamp, context),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey[500]
                                            : Colors.grey[600],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              if (!notification.isRead) {
                                setState(() {
                                  _notificationService
                                      .markAsRead(notification.id);
                                });
                              }
                              // عرض تفاصيل الإشعار
                              _showNotificationDetails(notification);
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
