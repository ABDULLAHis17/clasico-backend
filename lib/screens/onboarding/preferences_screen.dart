import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../models/league.dart';
import '../../utils/app_strings.dart';
import '../../data/sample_data.dart';
import '../../services/api_service.dart';
import '../home_screen.dart';
import 'phone_screen.dart';

class PreferencesScreen extends StatefulWidget {
  final UserProfile profile;
  const PreferencesScreen({Key? key, required this.profile}) : super(key: key);

  @override
  State<PreferencesScreen> createState() => _PreferencesScreenState();
}

class _PreferencesScreenState extends State<PreferencesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _player = TextEditingController();
  final _team = TextEditingController();
  final _nationalTeam = TextEditingController();
  final _leagueController = TextEditingController();
  String? _preferredLeagueId;
  List<League> _leagues = [];

  @override
  void initState() {
    super.initState();
    _loadLeagues();
  }

  Future<void> _loadLeagues() async {
    try {
      final api = ApiService();
      if (await api.isApiAvailable()) {
        final data = await api.getLeagues();
        if (mounted) setState(() {
          _leagues = data.map((j) => League(
            id: j['id'] as String,
            name: j['name'] as String,
            logo: j['logo_url'] as String? ?? '⚽',
            upcomingMatches: 0,
          )).toList();
        });
      } else {
        if (mounted) setState(() => _leagues = SampleData.getLeagues());
      }
    } catch (_) {
      if (mounted) setState(() => _leagues = SampleData.getLeagues());
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _team.dispose();
    _nationalTeam.dispose();
    _leagueController.dispose();
    super.dispose();
  }

  Future<Iterable<String>> _searchPlayers(TextEditingValue textEditingValue) async {
    if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
    try {
      final results = await ApiService().getPlayers(search: textEditingValue.text, limit: 10);
      return results.map((e) => e['name'] as String);
    } catch (_) {
      return const Iterable<String>.empty();
    }
  }

  Future<Iterable<String>> _searchTeams(TextEditingValue textEditingValue, {String? type}) async {
    if (textEditingValue.text.isEmpty) return const Iterable<String>.empty();
    try {
      final results = await ApiService().getTeams(search: textEditingValue.text, teamType: type, limit: 10);
      return results.map((e) => e['name'] as String);
    } catch (_) {
      return const Iterable<String>.empty();
    }
  }

  Future<Iterable<String>> _searchLeagues(TextEditingValue textEditingValue) async {
    if (textEditingValue.text.isEmpty) return _leagues.map((e) => e.name);
    return _leagues
        .where((l) => l.name.toLowerCase().contains(textEditingValue.text.toLowerCase()))
        .map((e) => e.name);
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) return;
    
    final selectedLeagueName = _leagueController.text.trim();
    if (selectedLeagueName.isNotEmpty) {
      try {
        final lg = _leagues.firstWhere((l) => l.name == selectedLeagueName);
        _preferredLeagueId = lg.id;
      } catch (_) {
        _preferredLeagueId = null;
      }
    }

    widget.profile
      ..favoritePlayer = _player.text.trim()
      ..favoriteTeam = _team.text.trim()
      ..nationalTeam = _nationalTeam.text.trim()
      ..preferredLeague = _preferredLeagueId;

    // Save profile to backend
    await ApiService().updateProfile(
      username: widget.profile.username,
      phoneNumber: widget.profile.phoneNumber,
      displayName: widget.profile.displayName,
      favoritePlayer: _player.text.trim(),
      favoriteTeam: _team.text.trim(),
      favoriteNationalTeam: _nationalTeam.text.trim(),
      favoriteLeague: _leagueController.text.trim(),
    );

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(isGuest: false),
      ),
      (route) => false,
    );
  }

  Widget _buildSearchField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required Future<Iterable<String>> Function(TextEditingValue) optionsBuilder,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Autocomplete<String>(
      optionsBuilder: optionsBuilder,
      onSelected: (String selection) {
        controller.text = selection;
      },
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        textEditingController.addListener(() {
          if (controller.text != textEditingController.text) {
            controller.text = textEditingController.text;
          }
        });
        
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            labelText: labelText,
            hintText: hintText,
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: colorScheme.primary,
                width: 2,
              ),
            ),
          ),
          validator: validator ?? (v) => (v ?? '').trim().isEmpty ? AppStrings.t(context, 'required') : null,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(16),
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 250, maxWidth: MediaQuery.of(context).size.width - 48),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final leagues = _leagues;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      appBar: AppBar(
        title: Text(AppStrings.t(context, 'your_preferences')),
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => PhoneScreen(profile: widget.profile),
              ),
            );
          },
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    const Color(0xFF0F172A),
                    const Color(0xFF1E293B),
                  ]
                : [
                    Colors.white,
                    Colors.grey[50]!,
                  ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.t(context, 'personalize_experience'),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSearchField(
                    controller: _player,
                    labelText: AppStrings.t(context, 'favorite_player'),
                    hintText: AppStrings.t(context, 'favorite_player_hint'),
                    optionsBuilder: _searchPlayers,
                  ),
                  const SizedBox(height: 16),

                  _buildSearchField(
                    controller: _team,
                    labelText: AppStrings.t(context, 'favorite_team'),
                    hintText: AppStrings.t(context, 'favorite_team_hint'),
                    optionsBuilder: (text) => _searchTeams(text, type: 'Club'),
                  ),
                  const SizedBox(height: 16),

                  _buildSearchField(
                    controller: _nationalTeam,
                    labelText: AppStrings.t(context, 'national_team'),
                    hintText: AppStrings.t(context, 'national_team_hint'),
                    optionsBuilder: (text) => _searchTeams(text, type: 'National'),
                  ),
                  const SizedBox(height: 16),

                  _buildSearchField(
                    controller: _leagueController,
                    labelText: AppStrings.t(context, 'preferred_league'),
                    hintText: AppStrings.t(context, 'choose_league'),
                    optionsBuilder: _searchLeagues,
                    validator: (v) => (v ?? '').trim().isEmpty ? AppStrings.t(context, 'choose_league') : null,
                  ),

                  const SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colorScheme.primary,
                          colorScheme.secondary,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _finish,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        AppStrings.t(context, 'finish'),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
