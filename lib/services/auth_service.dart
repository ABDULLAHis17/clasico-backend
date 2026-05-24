import '../models/user_profile.dart';

class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  UserProfile? currentUser;

  // Simulated existing usernames
  final Set<String> _takenUsernames = {
    'admin', 'guest', 'user', 'john', 'maria', 'ahmed', 'abdullah'
  };

  Future<UserProfile> signInWithGoogle() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 600));
    // Return a mock Google account
    final user = UserProfile(
      uid: 'mock-uid-123',
      email: 'user@example.com',
      displayName: 'Football Fan',
    );
    currentUser = user;
    return user;
  }

  Future<bool> isUsernameAvailable(String username) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final clean = username.trim().toLowerCase();
    if (clean.isEmpty) return false;
    return !_takenUsernames.contains(clean);
  }

  Future<void> reserveUsername(String username) async {
    await Future.delayed(const Duration(milliseconds: 150));
    _takenUsernames.add(username.trim().toLowerCase());
  }

  Future<void> requestEmailChange(String newEmail) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<void> verifyEmailCode(String code) async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (currentUser != null) {
      currentUser = UserProfile(
        uid: currentUser!.uid,
        email: currentUser!.email.replaceFirst('@', '+updated@'),
        displayName: currentUser!.displayName,
        username: currentUser!.username,
        phoneNumber: currentUser!.phoneNumber,
        favoritePlayer: currentUser!.favoritePlayer,
        favoriteTeam: currentUser!.favoriteTeam,
        nationalTeam: currentUser!.nationalTeam,
        preferredLeague: currentUser!.preferredLeague,
      );
    }
  }

  Future<void> changePassword(String current, String next) async {
    await Future.delayed(const Duration(milliseconds: 600));
  }

  Future<void> updateUsername(String username) async {
    await Future.delayed(const Duration(milliseconds: 350));
    _takenUsernames.add(username.trim().toLowerCase());
    if (currentUser != null) {
      currentUser!.username = username.trim();
    }
  }
}
