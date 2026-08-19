import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/features/videos/upload_video_screen.dart';
import 'package:nyarongo_wholesale/features/videos/video_list_screen.dart';
import 'package:nyarongo_wholesale/screens/admin/manage_products_screen.dart';
import 'package:nyarongo_wholesale/screens/assistant/ai_chat_assistant_screen.dart';
import 'package:nyarongo_wholesale/screens/orders/orders_screen.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String displayName;
  final VoidCallback onSignOut;
  final bool firebaseReady;

  const AdminDashboardScreen({
    super.key,
    required this.displayName,
    required this.onSignOut,
    required this.firebaseReady,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
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
            title: Text(_navItems[_selectedIndex].label),
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
                  destinations: _navItems
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
                      _AdminSidebar(
                        displayName: widget.displayName,
                        selectedIndex: _selectedIndex,
                        isCollapsed: _isSidebarCollapsed,
                        items: _navItems,
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
                          color: const Color(0xFFF8F6F0),
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
        return _AdminOverview(
          displayName: widget.displayName,
          firebaseReady: widget.firebaseReady,
          onOpenAssistant: _openAssistant,
          onNavigateToProducts: () => setState(() => _selectedIndex = 1),
          onNavigateToOrders: () => setState(() => _selectedIndex = 2),
          onNavigateToUsers: () => setState(() => _selectedIndex = 3),
          onNavigateToMedia: () => setState(() => _selectedIndex = 4),
        );
      case 1:
        return const ManageProductsScreen(embedded: true);
      case 2:
        return const OrdersScreen(
          mode: OrdersViewMode.admin,
          title: 'Manage Orders',
          embedded: true,
        );
      case 3:
        return const _AdminUsersPanel();
      case 4:
        return _AdminMediaPanel(firebaseReady: widget.firebaseReady);
      default:
        return const SizedBox.shrink();
    }
  }

  void _openAssistant() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AiChatAssistantScreen(roleLabel: 'Admin'),
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final String displayName;
  final int selectedIndex;
  final bool isCollapsed;
  final List<_AdminNavItem> items;
  final ValueChanged<int> onSelected;
  final VoidCallback onToggleCollapse;
  final VoidCallback onAssistantTap;
  final VoidCallback onSignOutTap;

  const _AdminSidebar({
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
                        'Admin Panel',
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
                        ? const Color(0xFFD97B14).withValues(alpha: 0.12)
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
                                  ? const Color(0xFFD97B14)
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
                                            ? const Color(0xFFD97B14)
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

class _AdminOverview extends StatelessWidget {
  final String displayName;
  final bool firebaseReady;
  final VoidCallback onOpenAssistant;
  final VoidCallback onNavigateToProducts;
  final VoidCallback onNavigateToOrders;
  final VoidCallback onNavigateToUsers;
  final VoidCallback onNavigateToMedia;

  const _AdminOverview({
    required this.displayName,
    required this.firebaseReady,
    required this.onOpenAssistant,
    required this.onNavigateToProducts,
    required this.onNavigateToOrders,
    required this.onNavigateToUsers,
    required this.onNavigateToMedia,
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
                colors: [Color(0xFFD97B14), Color(0xFFF59E0B)],
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
                  'Manage products, orders, users, and promotional content from one place.',
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
              _OverviewActionCard(
                title: 'Manage Products',
                subtitle: 'Add and edit listings',
                icon: Icons.inventory_2_rounded,
                onTap: onNavigateToProducts,
              ),
              _OverviewActionCard(
                title: 'Manage Orders',
                subtitle: 'Track and fulfill orders',
                icon: Icons.assignment_turned_in_rounded,
                onTap: onNavigateToOrders,
              ),
              _OverviewActionCard(
                title: 'Manage Users',
                subtitle: 'Roles and account access',
                icon: Icons.supervised_user_circle_rounded,
                onTap: onNavigateToUsers,
              ),
              _OverviewActionCard(
                title: 'Media Tools',
                subtitle: firebaseReady
                    ? 'Upload and review videos'
                    : 'Firebase required for video tools',
                icon: Icons.video_library_rounded,
                onTap: onNavigateToMedia,
              ),
            ],
          ),
          const SizedBox(height: 20),
          InkWell(
            onTap: onOpenAssistant,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFF2C79D4).withValues(alpha: 0.4),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Chat Assistant',
                          style:
                              Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Get quick admin help without leaving the dashboard.',
                          style:
                              Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _OverviewActionCard({
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
              color: const Color(0xFFD97B14).withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor:
                    const Color(0xFFD97B14).withValues(alpha: 0.12),
                child: Icon(icon, color: const Color(0xFFD97B14)),
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

class _AdminUsersPanel extends StatelessWidget {
  const _AdminUsersPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
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
                const Icon(
                  Icons.supervised_user_circle_rounded,
                  size: 40,
                  color: Color(0xFFD97B14),
                ),
                const SizedBox(height: 16),
                Text(
                  'Manage Users',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This area is ready for customer, worker, and admin account controls once the user management flow is added.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyLarge
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminMediaPanel extends StatelessWidget {
  final bool firebaseReady;

  const _AdminMediaPanel({required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Media Tools',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            firebaseReady
                ? 'Upload new promo videos or review the content already published.'
                : 'Firebase is not configured for this platform yet, so media actions are disabled.',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MediaActionCard(
                title: 'Upload Promo Video',
                subtitle: 'Add a new product or marketing video',
                icon: Icons.video_call_rounded,
                enabled: firebaseReady,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const UploadVideoScreen()),
                  );
                },
              ),
              _MediaActionCard(
                title: 'View Uploaded Videos',
                subtitle: 'Preview the latest published videos',
                icon: Icons.ondemand_video_rounded,
                enabled: firebaseReady,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VideoListScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MediaActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _MediaActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 220, maxWidth: 320),
      child: InkWell(
        onTap: enabled
            ? onTap
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Firebase is not configured for this platform yet, so this feature is disabled.',
                    ),
                  ),
                );
              },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFD97B14).withValues(
                alpha: enabled ? 0.35 : 0.18,
              ),
            ),
          ),
          child: Opacity(
            opacity: enabled ? 1 : 0.55,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor:
                      const Color(0xFFD97B14).withValues(alpha: 0.12),
                  child: Icon(icon, color: const Color(0xFFD97B14)),
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
      ),
    );
  }
}

class _AdminNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

const List<_AdminNavItem> _navItems = [
  _AdminNavItem(
    label: 'Overview',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  _AdminNavItem(
    label: 'Products',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2_rounded,
  ),
  _AdminNavItem(
    label: 'Orders',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
  ),
  _AdminNavItem(
    label: 'Users',
    icon: Icons.groups_outlined,
    selectedIcon: Icons.groups_rounded,
  ),
  _AdminNavItem(
    label: 'Media',
    icon: Icons.video_library_outlined,
    selectedIcon: Icons.video_library_rounded,
  ),
];
