import 'package:flutter/material.dart';
import '../../utils/app_strings.dart';
import '../../services/api_service.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _loading = false;
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String _strengthLabel(String pass) {
    int score = 0;
    if (pass.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pass)) score++;
    if (RegExp(r'[a-z]').hasMatch(pass)) score++;
    if (RegExp(r'\d').hasMatch(pass)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(pass)) score++;
    switch (score) {
      case 0:
      case 1:
        return 'Very Weak';
      case 2:
        return 'Weak';
      case 3:
        return 'Medium';
      case 4:
        return 'Strong';
      default:
        return 'Very Strong';
    }
  }

  Color _strengthColor(String pass) {
    final label = _strengthLabel(pass);
    switch (label) {
      case 'Very Weak':
      case 'Weak':
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Strong':
      case 'Very Strong':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(AppStrings.t(context, 'confirm')),
        content: Text(AppStrings.t(context, 'confirm_password_change')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(AppStrings.t(context, 'cancel'))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text(AppStrings.t(context, 'change'))),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final success = await ApiService().changePassword(
        currentPassword: _currentCtrl.text,
        newPassword: _newCtrl.text,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully!')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed: Current password may be incorrect.')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pwd = _newCtrl.text;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppStrings.t(context, 'change_password'),
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
                  children: [
                    TextFormField(
                      controller: _currentCtrl,
                      obscureText: !_showCurrent,
                      decoration: InputDecoration(
                        labelText: AppStrings.t(context, 'current_password'),
                        border: const OutlineInputBorder(),
                        filled: true,
                        suffixIcon: IconButton(
                          icon: Icon(_showCurrent ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _showCurrent = !_showCurrent),
                        ),
                      ),
                      validator: (v) => (v ?? '').isEmpty ? AppStrings.t(context, 'required') : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _newCtrl,
                      obscureText: !_showNew,
                      decoration: InputDecoration(
                        labelText: AppStrings.t(context, 'new_password'),
                        border: const OutlineInputBorder(),
                        filled: true,
                        suffixIcon: IconButton(
                          icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _showNew = !_showNew),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                      validator: (v) {
                        final val = (v ?? '');
                        if (val.length < 8) return AppStrings.t(context, 'min_8_chars');
                        if (!RegExp(r'[A-Z]').hasMatch(val)) return AppStrings.t(context, 'add_uppercase');
                        if (!RegExp(r'[a-z]').hasMatch(val)) return AppStrings.t(context, 'add_lowercase');
                        if (!RegExp(r'\d').hasMatch(val)) return AppStrings.t(context, 'add_digit');
                        if (!RegExp(r'[^A-Za-z0-9]').hasMatch(val)) return AppStrings.t(context, 'add_symbol');
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          Container(width: 10, height: 10, decoration: BoxDecoration(color: _strengthColor(pwd), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(
                            '${AppStrings.t(context, 'strength')}: ${_strengthLabel(pwd)}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: !_showConfirm,
                      decoration: InputDecoration(
                        labelText: AppStrings.t(context, 'confirm_new_password'),
                        border: const OutlineInputBorder(),
                        filled: true,
                        suffixIcon: IconButton(
                          icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility),
                          onPressed: () => setState(() => _showConfirm = !_showConfirm),
                        ),
                      ),
                      validator: (v) => v != _newCtrl.text ? AppStrings.t(context, 'passwords_not_match') : null,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: _loading
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(AppStrings.t(context, 'save_password')),
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
}
