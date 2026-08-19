import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/screens/assistant/ai_chat_assistant_screen.dart';
import 'package:nyarongo_wholesale/screens/profile/profile_settings_screen.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';
import 'package:nyarongo_wholesale/utils/enums.dart';

class WorkerDashboardScreen extends StatefulWidget {
  final String displayName;
  final VoidCallback onSignOut;

  const WorkerDashboardScreen({
    super.key,
    required this.displayName,
    required this.onSignOut,
  });

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  int _selectedIndex = 0;
  bool _isSidebarCollapsed = false;

  static const double _sidebarBreakpoint = 900;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= _sidebarBreakpoint;

        return Scaffold(
          appBar: AppBar(
            title: Text(_workerNavItems[_selectedIndex].label),
            actions: isWide
                ? null
                : [
                    IconButton(
                      tooltip: 'AI Assistant',
                      onPressed: _openAssistant,
                      icon: const Icon(Icons.smart_toy_rounded),
                    ),
                    IconButton(
                      tooltip: 'Sign Out',
                      onPressed: widget.onSignOut,
                      icon: const Icon(Icons.power_settings_new_rounded),
                    ),
                  ],
          ),
          bottomNavigationBar: isWide
              ? null
              : NavigationBar(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  destinations: _workerNavItems
                      .map(
                        (item) => NavigationDestination(
                          icon: Icon(item.icon),
                          selectedIcon: Icon(item.selectedIcon),
                          label: item.label,
                        ),
                      )
                      .toList(growable: false),
                ),
          body: SafeArea(
            child: isWide
                ? Row(
                    children: [
                      _WorkerSidebar(
                        displayName: widget.displayName,
                        selectedIndex: _selectedIndex,
                        isCollapsed: _isSidebarCollapsed,
                        items: _workerNavItems,
                        onSelected: (index) {
                          setState(() => _selectedIndex = index);
                        },
                        onToggleCollapse: () {
                          setState(() {
                            _isSidebarCollapsed = !_isSidebarCollapsed;
                          });
                        },
                        onAssistantTap: _openAssistant,
                        onSignOutTap: widget.onSignOut,
                      ),
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF4F7FC),
                          child: _buildSelectedContent(),
                        ),
                      ),
                    ],
                  )
                : _buildSelectedContent(),
          ),
        );
      },
    );
  }

  Widget _buildSelectedContent() {
    switch (_selectedIndex) {
      case 0:
        return _WorkerOverview(
          displayName: widget.displayName,
          onNavigateToAssigned: () => setState(() => _selectedIndex = 1),
          onNavigateToStatus: () => setState(() => _selectedIndex = 2),
          onNavigateToAlerts: () => setState(() => _selectedIndex = 3),
          onNavigateToProfile: () => setState(() => _selectedIndex = 4),
          onAssistantTap: _openAssistant,
        );
      case 1:
        return const _WorkerTaskPanel(
          title: 'Assigned Orders',
          description:
              'This section is ready for assigned deliveries, routes, and order details for workers.',
          icon: Icons.assignment_turned_in_rounded,
        );
      case 2:
        return const _WorkerTaskPanel(
          title: 'Update Status',
          description:
              'This section is ready for marking delivery progress, delays, and completed drop-offs.',
          icon: Icons.local_shipping_rounded,
        );
      case 3:
        return const _WorkerTaskPanel(
          title: 'Task Notifications',
          description:
              'This section is ready for task alerts, assignment changes, and operational updates.',
          icon: Icons.notifications_active_rounded,
        );
      case 4:
        return ProfileSettingsScreen(
          displayName: widget.displayName,
          role: UserRole.worker,
          embedded: true,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _openAssistant() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AiChatAssistantScreen(roleLabel: 'Worker'),
      ),
    );
  }
}

class _WorkerOverview extends StatelessWidget {
  final String displayName;
  final VoidCallback onNavigateToAssigned;
  final VoidCallback onNavigateToStatus;
  final VoidCallback onNavigateToAlerts;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onAssistantTap;

  const _WorkerOverview({
    required this.displayName,
    required this.onNavigateToAssigned,
    required this.onNavigateToStatus,
    required this.onNavigateToAlerts,
    required this.onNavigateToProfile,
    required this.onAssistantTap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(
                colors: [Color(0xFF2C79D4), Color(0xFF1E63B5)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $displayName',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Check assigned deliveries, update status, and follow worker alerts.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _WorkerActionCard(
                title: 'Assigned Orders',
                subtitle: 'View assigned deliveries',
                icon: Icons.assignment_turned_in_rounded,
                onTap: onNavigateToAssigned,
              ),
              _WorkerActionCard(
                title: 'Update Status',
                subtitle: 'Mark deliveries as completed',
                icon: Icons.local_shipping_rounded,
                onTap: onNavigateToStatus,
              ),
              _WorkerActionCard(
                title: 'Task Notifications',
                subtitle: 'Alerts and assigned tasks',
                icon: Icons.notifications_active_rounded,
                onTap: onNavigateToAlerts,
              ),
              _WorkerActionCard(
                title: 'Profile & Settings',
                subtitle: 'Worker account and preferences',
                icon: Icons.manage_accounts_rounded,
                onTap: onNavigateToProfile,
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: onAssistantTap,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF2C79D4).withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        const Color(0xFF2C79D4).withValues(alpha: 0.12),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      color: Color(0xFF2C79D4),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'AI Chat Assistant',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF2C79D4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkerTaskPanel extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _WorkerTaskPanel({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 40, color: const Color(0xFF2C79D4)),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppConstants.textSecondaryColor,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WorkerActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _WorkerActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 300),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFF2C79D4).withValues(alpha: 0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    const Color(0xFF2C79D4).withValues(alpha: 0.12),
                child: Icon(icon, color: const Color(0xFF2C79D4)),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkerSidebar extends StatelessWidget {
  final String displayName;
  final int selectedIndex;
  final bool isCollapsed;
  final List<_WorkerNavItem> items;
  final ValueChanged<int> onSelected;
  final VoidCallback onToggleCollapse;
  final VoidCallback onAssistantTap;
  final VoidCallback onSignOutTap;

  const _WorkerSidebar({
    required this.displayName,
    required this.selectedIndex,
    required this.isCollapsed,
    required this.items,
    required this.onSelected,
    required this.onToggleCollapse,
    required this.onAssistantTap,
    required this.onSignOutTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: isCollapsed ? 92 : 280,
      padding: EdgeInsets.fromLTRB(isCollapsed ? 12 : 20, 24, isCollapsed ? 12 : 20, 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                ),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Worker Panel',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        displayName,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: isCollapsed ? Alignment.center : Alignment.centerRight,
            child: IconButton.filledTonal(
              tooltip: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
              onPressed: onToggleCollapse,
              icon: Icon(
                isCollapsed
                    ? Icons.keyboard_double_arrow_right_rounded
                    : Icons.keyboard_double_arrow_left_rounded,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = index == selectedIndex;

                return Tooltip(
                  message: item.label,
                  child: Material(
                    color: isSelected
                        ? const Color(0xFF2C79D4).withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => onSelected(index),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        child: Row(
                          mainAxisAlignment: isCollapsed
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            Icon(
                              isSelected ? item.selectedIcon : item.icon,
                              color: isSelected
                                  ? const Color(0xFF2C79D4)
                                  : Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                            if (!isCollapsed) ...[
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? const Color(0xFF2C79D4)
                                            : Theme.of(context).colorScheme.onSurface,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (isCollapsed)
            Center(
              child: Column(
                children: [
                  IconButton.filled(
                    tooltip: 'AI Assistant',
                    onPressed: onAssistantTap,
                    icon: const Icon(Icons.smart_toy_rounded),
                  ),
                  const SizedBox(height: 12),
                  IconButton.outlined(
                    tooltip: 'Sign Out',
                    onPressed: onSignOutTap,
                    icon: const Icon(Icons.power_settings_new_rounded),
                  ),
                ],
              ),
            )
          else
            FilledButton.icon(
              onPressed: onAssistantTap,
              icon: const Icon(Icons.smart_toy_rounded),
              label: const Text('AI Assistant'),
            ),
          const SizedBox(height: 12),
          if (!isCollapsed)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSignOutTap,
                icon: const Icon(Icons.power_settings_new_rounded),
                label: const Text('Sign Out'),
              ),
            ),
        ],
      ),
    );
  }
}

class _WorkerNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _WorkerNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

const List<_WorkerNavItem> _workerNavItems = [
  _WorkerNavItem(
    label: 'Overview',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  _WorkerNavItem(
    label: 'Assigned',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment_turned_in_rounded,
  ),
  _WorkerNavItem(
    label: 'Status',
    icon: Icons.local_shipping_outlined,
    selectedIcon: Icons.local_shipping_rounded,
  ),
  _WorkerNavItem(
    label: 'Alerts',
    icon: Icons.notifications_outlined,
    selectedIcon: Icons.notifications_active_rounded,
  ),
  _WorkerNavItem(
    label: 'Profile',
    icon: Icons.manage_accounts_outlined,
    selectedIcon: Icons.manage_accounts_rounded,
  ),
];
