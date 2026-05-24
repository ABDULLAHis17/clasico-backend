class BannedUser {
  final String userId;
  final DateTime bannedAt;
  final DateTime unbannedAt;
  final String reason;

  BannedUser({
    required this.userId,
    required this.bannedAt,
    required this.unbannedAt,
    required this.reason,
  });

  bool get isStillBanned => DateTime.now().isBefore(unbannedAt);
  
  int get remainingHours {
    final remaining = unbannedAt.difference(DateTime.now());
    return remaining.inHours;
  }
}

class UserBanService {
  static final Map<String, BannedUser> _bannedUsers = {};

  /// حظر مستخدم لمدة 24 ساعة
  static void banUserFor24Hours(String userId, String reason) {
    final now = DateTime.now();
    final unbannedAt = now.add(const Duration(hours: 24));

    _bannedUsers[userId] = BannedUser(
      userId: userId,
      bannedAt: now,
      unbannedAt: unbannedAt,
      reason: reason,
    );
  }

  /// التحقق من حظر المستخدم
  static bool isUserBanned(String userId) {
    final bannedUser = _bannedUsers[userId];
    if (bannedUser == null) return false;

    if (bannedUser.isStillBanned) {
      return true;
    } else {
      // إزالة الحظر إذا انتهت المدة
      _bannedUsers.remove(userId);
      return false;
    }
  }

  /// الحصول على معلومات الحظر
  static BannedUser? getBanInfo(String userId) {
    final bannedUser = _bannedUsers[userId];
    if (bannedUser == null) return null;

    if (bannedUser.isStillBanned) {
      return bannedUser;
    } else {
      _bannedUsers.remove(userId);
      return null;
    }
  }

  /// إزالة الحظر يدويًا
  static void unbanUser(String userId) {
    _bannedUsers.remove(userId);
  }

  /// الحصول على جميع المستخدمين المحظورين
  static List<BannedUser> getAllBannedUsers() {
    final now = DateTime.now();
    final activeBans = _bannedUsers.values
        .where((ban) => ban.unbannedAt.isAfter(now))
        .toList();
    
    // تنظيف الحظر المنتهي
    _bannedUsers.removeWhere((_, ban) => !ban.isStillBanned);
    
    return activeBans;
  }

  /// الحصول على عدد الساعات المتبقية للحظر
  static int getRemainingBanHours(String userId) {
    final bannedUser = _bannedUsers[userId];
    if (bannedUser == null || !bannedUser.isStillBanned) return 0;
    return bannedUser.remainingHours;
  }
}
