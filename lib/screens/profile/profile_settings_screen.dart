import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/theme_manager.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';
import 'package:nyarongo_wholesale/utils/enums.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final String displayName;
  final UserRole role;
  final bool embedded;

  const ProfileSettingsScreen({
    super.key,
    required this.displayName,
    required this.role,
    this.embedded = false,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  bool pushAlerts = true;
  bool orderUpdates = true;
  bool darkMode = false;

  @override
  void initState() {
    super.initState();
    darkMode = themeModeNotifier.value == ThemeMode.dark;
    _nameController = TextEditingController(text: widget.displayName);
    _emailController = TextEditingController(
      text: '${widget.displayName.toLowerCase().replaceAll(' ', '.')}@nyarongo.com',
    );
    _phoneController = TextEditingController(text: '+254 700 000 000');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = _roleColor(widget.role);
    final content = SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.embedded) ...[
            Text(
              'Profile & Settings',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 18),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: accentColor.withValues(alpha: 0.14),
                  child: Icon(Icons.person_rounded, color: accentColor, size: 34),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _roleLabel(widget.role),
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppConstants.textSecondaryColor,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _emailController,
            decoration: const InputDecoration(
              labelText: 'Email address',
              prefixIcon: Icon(Icons.email_rounded),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              prefixIcon: Icon(Icons.phone_rounded),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Preferences',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            title: 'Push alerts',
            subtitle: 'Receive important app notifications',
            value: pushAlerts,
            onChanged: (value) => setState(() => pushAlerts = value),
          ),
          _SettingsTile(
            title: 'Order updates',
            subtitle: 'Get notified when order status changes',
            value: orderUpdates,
            onChanged: (value) => setState(() => orderUpdates = value),
          ),
          _SettingsTile(
            title: 'Dark mode preference',
            subtitle: 'Store theme preference for later use',
            value: darkMode,
            onChanged: (value) {
              setState(() => darkMode = value);
              themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile settings saved')),
                );
              },
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Changes'),
            ),
          ),
        ],
      ),
    );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile & Settings')),
      body: content,
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return const Color(0xFF4F9B66);
      case UserRole.admin:
        return const Color(0xFFD97B14);
      case UserRole.worker:
        return const Color(0xFF2C79D4);
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Customer Account';
      case UserRole.admin:
        return 'Admin Account';
      case UserRole.worker:
        return 'Worker Account';
    }
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
