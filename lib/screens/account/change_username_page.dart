import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/app_strings.dart';
import '../../services/api_service.dart';

class ChangeUsernamePage extends StatefulWidget {
  const ChangeUsernamePage({Key? key}) : super(key: key);

  @override
  State<ChangeUsernamePage> createState() => _ChangeUsernamePageState();
}

class _ChangeUsernamePageState extends State<ChangeUsernamePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  Timer? _debounce;
  bool _checking = false;
  bool? _available;
  bool _saving = false;

  String _currentUsername = 'Loading...';

  @override
  void initState() {
    super.initState();
    _usernameCtrl.addListener(_onChanged);
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    final profile = await ApiService().getCurrentUserProfile();
    if (mounted && profile != null) {
      setState(() {
        _currentUsername = profile['username'] ?? profile['display_name'] ?? '-';
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _usernameCtrl.removeListener(_onChanged);
    _usernameCtrl.dispose();
    super.dispose();
  }

  void _onChanged() {
    _debounce?.cancel();
    _available = null;
    setState(() {});
    _debounce = Timer(const Duration(milliseconds: 350), _checkAvailability);
  }

  Future<void> _checkAvailability() async {
    final u = _usernameCtrl.text.trim();
    if (u.isEmpty || !_validPattern(u)) return;
    setState(() => _checking = true);
    try {
      final results = await ApiService().searchUsers(u);
      final ok = !results.any((r) => r['username'] == u);
      if (mounted) setState(() => _available = ok);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  bool _validPattern(String u) {
    return RegExp(r'^[A-Za-z0-9_]{3,20}$').hasMatch(u);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_available == false) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.t(context, 'confirm')),
        content: Text(AppStrings.t(context, 'username_change_affects')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppStrings.t(context, 'cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(AppStrings.t(context, 'change'))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _saving = true);
    try {
      await ApiService().updateProfile(username: _usernameCtrl.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final u = _usernameCtrl.text.trim();
    final valid = _validPattern(u);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.t(context, 'change_username'),
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.t(context, 'current_username'),
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Text(_currentUsername, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _usernameCtrl,
                      decoration: InputDecoration(
                        labelText: AppStrings.t(context, 'new_username'),
                        border: const OutlineInputBorder(),
                        filled: true,
                        suffixIcon: _checking
                            ? const Padding(
                                padding: EdgeInsets.all(12.0),
                                child: SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              )
                            : _availabilityIcon(),
                      ),
                      validator: (v) {
                        final val = (v ?? '').trim();
                        if (val.isEmpty) return AppStrings.t(context, 'required');
                        if (!_validPattern(val)) return AppStrings.t(context, 'username_validation');
                        if (_available == false) return AppStrings.t(context, 'username_taken');
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: !_saving && valid && _available != false ? _save : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(AppStrings.t(context, 'save_username')),
                      ),
                    ),
                  ],
                ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget? _availabilityIcon() {
    if (_available == null || _usernameCtrl.text.trim().isEmpty) return null;
    return Icon(
      _available == true ? Icons.check_circle : Icons.error_outline,
      color: _available == true ? Colors.green : Colors.red,
    );
  }
}
