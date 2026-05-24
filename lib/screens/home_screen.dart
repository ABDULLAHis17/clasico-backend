import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/league.dart';
import '../models/match.dart';
import '../data/sample_data.dart';
import '../data/mock_match_data.dart';
import '../services/api_service.dart';
import '../services/local_data_service.dart';
import '../widgets/smart_logo.dart';
import '../widgets/date_bar.dart';
import '../widgets/league_card.dart';
import '../widgets/match_card.dart';
import '../widgets/app_drawer.dart';
import '../utils/app_strings.dart';
import '../utils/app_themes.dart';
import '../utils/app_images.dart';
import '../services/notification_service.dart';
import 'news_screen.dart';
import 'transfers_screen.dart';
import 'favorites_screen.dart';
import 'search/search_hub_screen.dart';
import 'league_details_screen.dart';
import 'notifications_screen.dart';

class HomeScreen extends StatefulWidget {
  final bool isGuest;

  const HomeScreen({Key? key, required this.isGuest}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? selectedLeagueId;
  DateTime selectedDate = DateTime.now();
  List<League> leagues = [];
  List<Match> matches = [];
  List<Match> filteredMatches = [];
  
  // ignore: unused_field
  bool _isLoading = true;
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _loadData();
  }


  Future<void> _loadData() async {
    final apiService = ApiService();
    final localData = LocalDataService();
    await localData.init();

    // Load leagues from API or local
    try {
      final leaguesJson = await apiService.getLeagues();
      leagues = leaguesJson.map((j) => League(
        id: j['id']?.toString() ?? '',
        name: j['name'] as String? ?? 'League',
        logo: j['logo_url'] as String? ?? '🏆',
        country: j['country'] as String?,
        upcomingMatches: 0,
      )).toList();
    } catch (_) {
      final rawLeagues = localData.getLeagues();
      leagues = rawLeagues.map((j) => League(
        id: j['leagueid']?.toString() ?? j['index'].toString(),
        name: j['name'] as String? ?? 'League',
        logo: j['image'] as String? ?? '🏆',
        upcomingMatches: 0,
      )).toList();
    }

    // Try API matches first
    bool apiMatchesLoaded = false;
    try {
      var matchesJson = await apiService.getMatches();
      // Auto-generate mock matches on API if DB is empty
      if (matchesJson.isEmpty) {
        await apiService.generateMockMatches();
        matchesJson = await apiService.getMatches();
      }
      if (matchesJson.isNotEmpty) {
        matches = matchesJson.map((j) => Match(
          id: j['id'] as String? ?? '',
          homeTeam: j['home_team']?['name'] as String? ?? 'Home',
          awayTeam: j['away_team']?['name'] as String? ?? 'Away',
          homeTeamLogo: j['home_team']?['logo_url'] as String? ?? '⚽',
          awayTeamLogo: j['away_team']?['logo_url'] as String? ?? '⚽',
          matchTime: j['match_date'] != null ? DateTime.parse(j['match_date'] as String).toLocal() : DateTime.now(),
          leagueId: j['league_id'] as String? ?? '',
          isPlayed: j['status'] == 'finished',
          homeScore: j['home_score'] as int?,
          awayScore: j['away_score'] as int?,
        )).toList();
        apiMatchesLoaded = true;
      }
    } catch (_) {
      // API not available
    }

    // If API returned no matches, generate mock data locally
    if (!apiMatchesLoaded) {
      if (!MockMatchDataService.initialized) {
        await MockMatchDataService.initialize(localData);
      }

      final rawLeagues = localData.getLeagues();
      leagues = rawLeagues.map((j) => League(
        id: j['leagueid']?.toString() ?? j['index'].toString(),
        name: j['name'] as String? ?? 'League',
        logo: j['image'] as String? ?? '🏆',
        upcomingMatches: 0,
      )).toList();

      final sampleMatches = SampleData.getMatches();
      matches = sampleMatches.map((m) {
        final homeTeamData = localData.getTeamByName(m.homeTeam);
        final awayTeamData = localData.getTeamByName(m.awayTeam);

        String hLogo = m.homeTeamLogo;
        String aLogo = m.awayTeamLogo;
        if (homeTeamData != null) {
          hLogo = localData.normalizeTeamData(homeTeamData)['logo_url'] ?? hLogo;
        }
        if (awayTeamData != null) {
          aLogo = localData.normalizeTeamData(awayTeamData)['logo_url'] ?? aLogo;
        }
        return Match(
          id: m.id, homeTeam: m.homeTeam, awayTeam: m.awayTeam,
          homeTeamLogo: hLogo, awayTeamLogo: aLogo,
          matchTime: m.matchTime, leagueId: m.leagueId,
          isPlayed: m.isPlayed, homeScore: m.homeScore, awayScore: m.awayScore,
        );
      }).toList();
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
        _filterMatches();
      });
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  void _filterMatches() {
    setState(() {
      filteredMatches = matches.where((match) {
        bool leagueMatch = selectedLeagueId == null || match.leagueId == selectedLeagueId;
        bool dateMatch = _isSameDay(match.matchTime, selectedDate);
        return leagueMatch && dateMatch;
      }).toList();
    });
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  void _onLeagueSelected(String? leagueId) {
    setState(() {
      selectedLeagueId = leagueId;
      _filterMatches();
    });
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      selectedDate = date;
      _filterMatches();
    });
  }

  void _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2005, 1, 1),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      _onDateSelected(picked);
    }
  }

  void _showSearchDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SearchHubScreen(),
      ),
    );
  }

  Widget _buildFilterItem({
    required String? title,
    required String logo,
    required bool isSelected,
    required VoidCallback onTap,
    int? count,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 12, top: 4, bottom: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected 
                    ? colorScheme.primary 
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected 
                      ? colorScheme.primary 
                      : (isDark ? Colors.white.withValues(alpha: 0.1) : colorScheme.outlineVariant.withValues(alpha: 0.5)),
                  width: 1.5,
                ),
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] : [],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SmartLogo(
                        logo: logo,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (title != null)
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : colorScheme.onSurface),
                      ),
                    ),
                ],
              ),
            ),
            if (count != null && count > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.3),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showExitDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // أيقونة كبيرة وجميلة
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFFF6B6B),
                        Color(0xFFEE5A6F),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                
                // العنوان
                Text(
                  AppStrings.t(context, 'exit_app'),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                
                // الرسالة
                Text(
                  AppStrings.t(context, 'exit_app_message'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                
                // الأزرار
                Row(
                  children: [
                    // زر الإلغاء
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            AppStrings.t(context, 'cancel'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // زر الخروج
                    Expanded(
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFF6B6B),
                              Color(0xFFEE5A6F),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppStrings.t(context, 'exit'),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    // حساب حجم اللوجو في AppBar بناءً على حجم الشاشة - حجم أصغر لإعطاء مساحة أكبر للنص
    final appBarLogoSize = screenWidth < 600 ? 45.0 : screenWidth < 1200 ? 55.0 : 65.0;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        
        final bool shouldPop = await _showExitDialog(context) ?? false;
        if (shouldPop && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Container(
        decoration: isDark 
            ? AppThemes.backgroundGradient(context)
            : const BoxDecoration(color: Colors.white),
        child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: appBarLogoSize + 20,
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.85),
                        colorScheme.secondary.withValues(alpha: 0.7),
                      ]
                    : [
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.9),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                // Decorative circles
                Positioned(
                  top: -20,
                  right: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.03),
                    ),
                  ),
                ),
              ],
            ),
          ),
        leading: Builder(
          builder: (context) => Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu, color: Colors.white, size: 22),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        title: GestureDetector(
          onTap: () {
            // Start rotation animation
            _rotationController.forward(from: 0.0);
            // Refresh the page by resetting filters
            setState(() {
              selectedLeagueId = null;
              selectedDate = DateTime.now();
              _filterMatches();
            });
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: appBarLogoSize,
                height: appBarLogoSize,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.1),
                      Colors.white.withValues(alpha: 0.03),
                      Colors.transparent,
                    ],
                    stops: const [0.3, 0.7, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: RotationTransition(
                    turns: _rotationController,
                    child: Image.asset(
                      AppImages.logo,
                      width: appBarLogoSize * 0.85,
                      height: appBarLogoSize * 0.85,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.t(context, 'home_title'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 24,
                          letterSpacing: 0.5,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        AppStrings.t(context, 'live_matches'),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Notifications Button
          StatefulBuilder(
            builder: (context, setState) {
              final unreadCount = NotificationService().getUnreadCount();
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsScreen(),
                          ),
                        );
                        setState(() {}); // Refresh to update badge
                      },
                      tooltip: 'Notifications',
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.white, size: 20),
              onPressed: _showDatePicker,
              tooltip: 'Select Date',
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(Icons.search, color: Colors.white, size: 20),
              onPressed: _showSearchDialog,
              tooltip: AppStrings.t(context, 'search'),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
      drawer: AppDrawer(isGuest: widget.isGuest),
      body: Column(
        children: [
          // Fixed Beautiful Date Bar with Separator
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        const Color(0xFF1E293B),
                        const Color(0xFF334155),
                      ]
                    : [
                        Colors.white,
                        colorScheme.primaryContainer.withValues(alpha: 0.1),
                      ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
              border: Border(
                bottom: BorderSide(
                  color: isDark 
                    ? colorScheme.primary.withValues(alpha: 0.3)
                    : colorScheme.primary.withValues(alpha: 0.1),
                  width: 2,
                ),
              ),
            ),
            child: Column(
              children: [
                // Decorative top line
                Container(
                  height: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary.withValues(alpha: 0.0),
                        colorScheme.primary,
                        colorScheme.secondary,
                        colorScheme.primary,
                        colorScheme.primary.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                // Date Bar Content
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: DateBar(
                    selectedDate: selectedDate,
                    onDateSelected: _onDateSelected,
                  ),
                ),
                // Bottom decorative accent
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        height: 4,
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.3),
                              colorScheme.primary,
                              colorScheme.secondary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 4,
                        width: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colorScheme.secondary,
                              colorScheme.primary,
                              colorScheme.primary.withValues(alpha: 0.3),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- FIXED LEAGUE NAVIGATION BAR ---
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: SizedBox(
              height: 48,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: leagues.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    final totalMatchesToday = matches.where((m) => _isSameDay(m.matchTime, selectedDate)).length;
                    return _buildFilterItem(
                      title: AppStrings.t(context, 'all_leagues'),
                      logo: '🏆', 
                      isSelected: selectedLeagueId == null,
                      count: totalMatchesToday,
                      onTap: () => _onLeagueSelected(null),
                    );
                  }
                  
                  final league = leagues[index - 1];
                  final matchCountForLeague = matches.where((match) {
                    return match.leagueId == league.id && 
                           _isSameDay(match.matchTime, selectedDate);
                  }).length;
                  
                  return _buildFilterItem(
                    title: league.name,
                    logo: league.logo,
                    isSelected: selectedLeagueId == league.id,
                    count: matchCountForLeague,
                    onTap: () => _onLeagueSelected(league.id),
                  );
                },
              ),
            ),
          ),
          
          // Scrollable Content (Matches)
          Expanded(
            child: filteredMatches.isEmpty
                ? CustomScrollView(
                    slivers: [
                      // Empty State
                      SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                size: 64,
                                color: colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppStrings.t(context, 'no_matches'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : CustomScrollView(
                    slivers: [
                      // Matches List always grouped by league to show the correct logo above each group/match
                      ..._buildGroupedMatchesByLeague(colorScheme, theme, isDark)
                    ],
                  ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  List<Widget> _buildGroupedMatchesByLeague(ColorScheme colorScheme, ThemeData theme, bool isDark) {
    // Group matches by league
    final Map<String, List<Match>> matchesByLeague = {};
    for (var match in filteredMatches) {
      if (!matchesByLeague.containsKey(match.leagueId)) {
        matchesByLeague[match.leagueId] = [];
      }
      matchesByLeague[match.leagueId]!.add(match);
    }

    final List<Widget> slivers = [];
    final leagueIds = matchesByLeague.keys.toList();

    for (int i = 0; i < leagueIds.length; i++) {
      final leagueId = leagueIds[i];
      final leagueMatches = matchesByLeague[leagueId]!;
      final league = leagues.firstWhere(
        (l) => l.id == leagueId,
        orElse: () => League(id: '', name: 'Unknown', logo: '⚽', upcomingMatches: 0),
      );

      // League Header
      slivers.add(
        SliverToBoxAdapter(
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => LeagueDetailsScreen(
                    leagueId: league.id,
                    leagueName: league.name,
                  ),
                ),
              );
            },
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                    ? [
                        colorScheme.primary.withValues(alpha: 0.2),
                        colorScheme.secondary.withValues(alpha: 0.15),
                      ]
                    : [
                        colorScheme.primary.withValues(alpha: 0.1),
                        colorScheme.primaryContainer.withValues(alpha: 0.3),
                      ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.7),
                      shape: BoxShape.circle,
                    ),
                    child: SmartLogo(
                      logo: league.logo,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      league.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : colorScheme.primary,
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${leagueMatches.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Matches for this league
      slivers.add(
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                return MatchCard(
                  match: leagueMatches[index],
                  showLeagueName: false,
                );
              },
              childCount: leagueMatches.length,
            ),
          ),
        ),
      );

      // Divider between leagues (except after the last one)
      if (i < leagueIds.length - 1) {
        slivers.add(
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            colorScheme.primary.withValues(alpha: 0.3),
                            colorScheme.secondary.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.primary,
                            colorScheme.secondary,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            colorScheme.secondary.withValues(alpha: 0.3),
                            colorScheme.primary.withValues(alpha: 0.3),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      } else {
        // Add bottom padding after last league
        slivers.add(
          const SliverToBoxAdapter(
            child: SizedBox(height: 16),
          ),
        );
      }
    }

    return slivers;
  }
}
