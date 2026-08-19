import 'package:flutter/material.dart';
import 'package:nyarongo_wholesale/features/videos/video_list_screen.dart';
import 'package:nyarongo_wholesale/screens/assistant/ai_chat_assistant_screen.dart';
import 'package:nyarongo_wholesale/screens/categories/category_screen.dart';
import 'package:nyarongo_wholesale/screens/orders/orders_screen.dart';
import 'package:nyarongo_wholesale/screens/profile/profile_settings_screen.dart';
import 'package:nyarongo_wholesale/screens/customer/messages_screen.dart';
import 'package:nyarongo_wholesale/utils/constants.dart';
import 'package:nyarongo_wholesale/utils/enums.dart';

class CustomerHomeScreen extends StatefulWidget {
  final String displayName;
  final VoidCallback onSignOut;
  final bool firebaseReady;

  const CustomerHomeScreen({
    super.key,
    required this.displayName,
    required this.onSignOut,
    required this.firebaseReady,
  });

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
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
            title: Text(_customerNavItems[_selectedIndex].label),
            actions: [
              if (!isWide) ...[
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
              IconButton(
                tooltip: 'Messages',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CustomerMessagesScreen()),
                  );
                },
                icon: CircleAvatar(
                  radius: 16,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
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
                  destinations: _customerNavItems
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
                      _DashboardSidebar(
                        title: 'Customer Panel',
                        displayName: widget.displayName,
                        accentColor: const Color(0xFF4F9B66),
                        selectedIndex: _selectedIndex,
                        isCollapsed: _isSidebarCollapsed,
                        items: _customerNavItems,
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
                        onLogoTap: _openMessages,
                      ),
                      Expanded(
                        child: Container(
                          color: const Color(0xFFF5F8F4),
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
        return _CustomerOverview(
          displayName: widget.displayName,
          firebaseReady: widget.firebaseReady,
          onNavigateToShop: () => setState(() => _selectedIndex = 1),
          onNavigateToOrders: () => setState(() => _selectedIndex = 2),
          onNavigateToVideos: () => setState(() => _selectedIndex = 3),
          onNavigateToDeals: () => setState(() => _selectedIndex = 4),
          onNavigateToProfile: () => setState(() => _selectedIndex = 5),
          onAssistantTap: _openAssistant,
        );
      case 1:
        return const CategoryScreen(embedded: true);
      case 2:
        return const OrdersScreen(
          mode: OrdersViewMode.customer,
          title: 'Orders',
          embedded: true,
        );
      case 3:
        return _CustomerVideosPanel(firebaseReady: widget.firebaseReady);
      case 4:
        return const _CustomerDealsPanel();
      case 5:
        return ProfileSettingsScreen(
          displayName: widget.displayName,
          role: UserRole.customer,
          embedded: true,
        );
      default:
        return const SizedBox.shrink();
    }
  }

  void _openAssistant() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AiChatAssistantScreen(roleLabel: 'Customer'),
      ),
    );
  }

  void _openMessages() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const CustomerMessagesScreen()),
    );
  }
}

class _CustomerOverview extends StatelessWidget {
  final String displayName;
  final bool firebaseReady;
  final VoidCallback onNavigateToShop;
  final VoidCallback onNavigateToOrders;
  final VoidCallback onNavigateToVideos;
  final VoidCallback onNavigateToDeals;
  final VoidCallback onNavigateToProfile;
  final VoidCallback onAssistantTap;

  const _CustomerOverview({
    required this.displayName,
    required this.firebaseReady,
    required this.onNavigateToShop,
    required this.onNavigateToOrders,
    required this.onNavigateToVideos,
    required this.onNavigateToDeals,
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
          _DashboardHeader(
            title: 'Welcome, $displayName',
            subtitle:
                'Browse products, watch adverts, track orders, and manage your account.',
            color: const Color(0xFF4F9B66),
          ),
          const SizedBox(height: 18),
          // Search bar only; messages open from the app header.
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search products, categories...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  ),
                  onSubmitted: (query) {
                    if (query.trim().isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Search: "${query.trim()}"')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _OverviewActionCard(
                title: 'Shop',
                subtitle: 'Browse products and categories',
                icon: Icons.storefront_rounded,
                accentColor: const Color(0xFF4F9B66),
                onTap: onNavigateToShop,
              ),
              _OverviewActionCard(
                title: 'Orders',
                subtitle: 'Track your order history',
                icon: Icons.receipt_long_rounded,
                accentColor: const Color(0xFF4F9B66),
                onTap: onNavigateToOrders,
              ),
              _OverviewActionCard(
                title: 'Videos',
                subtitle: firebaseReady
                    ? 'Watch video adverts'
                    : 'Firebase required for video adverts',
                icon: Icons.ondemand_video_rounded,
                accentColor: const Color(0xFF4F9B66),
                onTap: onNavigateToVideos,
              ),
              _OverviewActionCard(
                title: 'Daily Deals',
                subtitle: 'Flash sales and bundle offers',
                icon: Icons.local_offer_rounded,
                accentColor: const Color(0xFFD97B14),
                onTap: onNavigateToDeals,
              ),
              _OverviewActionCard(
                title: 'Profile',
                subtitle: 'Manage account settings',
                icon: Icons.manage_accounts_rounded,
                accentColor: const Color(0xFF4F9B66),
                onTap: onNavigateToProfile,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _AssistantCard(
            accentColor: const Color(0xFF4F9B66),
            onTap: onAssistantTap,
          ),
        ],
      ),
    );
  }
}

class _CustomerVideosPanel extends StatelessWidget {
  final bool firebaseReady;

  const _CustomerVideosPanel({required this.firebaseReady});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppConstants.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Video Adverts',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            firebaseReady
                ? 'Watch the latest product videos and promotions.'
                : 'Video adverts are unavailable until Firebase is configured for this platform.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppConstants.textSecondaryColor,
                ),
          ),
          const SizedBox(height: 20),
          _OverviewActionCard(
            title: 'Open Video Feed',
            subtitle: firebaseReady
                ? 'View published product adverts'
                : 'Currently unavailable',
            icon: Icons.play_circle_fill_rounded,
            accentColor: const Color(0xFF4F9B66),
            onTap: () {
              if (!firebaseReady) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Video adverts are unavailable until Firebase is configured for this platform.',
                    ),
                  ),
                );
                return;
              }

              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const VideoListScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CustomerDealsPanel extends StatelessWidget {
  const _CustomerDealsPanel();

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
                const Icon(
                  Icons.local_offer_rounded,
                  size: 40,
                  color: Color(0xFFD97B14),
                ),
                const SizedBox(height: 16),
                Text(
                  'Daily Deals',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  'This section is ready for flash sales, bundle offers, and daily promotions when that customer flow is added.',
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

class _DashboardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _DashboardHeader({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.82)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.92),
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
  final Color accentColor;
  final VoidCallback onTap;

  const _OverviewActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
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
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: accentColor.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: accentColor.withValues(alpha: 0.14),
                child: Icon(icon, color: accentColor),
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

class _AssistantCard extends StatelessWidget {
  final Color accentColor;
  final VoidCallback onTap;

  const _AssistantCard({
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: accentColor.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: accentColor.withValues(alpha: 0.12),
              child: Icon(Icons.smart_toy_rounded, color: accentColor),
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
            Icon(Icons.chevron_right_rounded, color: accentColor),
          ],
        ),
      ),
    );
  }
}

class _DashboardSidebar extends StatelessWidget {
  final String title;
  final String displayName;
  final Color accentColor;
  final int selectedIndex;
  final bool isCollapsed;
  final List<_DashboardNavItem> items;
  final ValueChanged<int> onSelected;
  final VoidCallback onToggleCollapse;
  final VoidCallback onAssistantTap;
  final VoidCallback onSignOutTap;
  final VoidCallback onLogoTap;

  const _DashboardSidebar({
    required this.title,
    required this.displayName,
    required this.accentColor,
    required this.selectedIndex,
    required this.isCollapsed,
    required this.items,
    required this.onSelected,
    required this.onToggleCollapse,
    required this.onAssistantTap,
    required this.onSignOutTap,
    required this.onLogoTap,
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
              Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: onLogoTap,
                  child: Container(
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
                ),
              ),
              if (!isCollapsed) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
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
                        ? accentColor.withValues(alpha: 0.12)
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
                                  ? accentColor
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
                                            ? accentColor
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

class _DashboardNavItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const _DashboardNavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });
}

const List<_DashboardNavItem> _customerNavItems = [
  _DashboardNavItem(
    label: 'Overview',
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
  ),
  _DashboardNavItem(
    label: 'Shop',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront_rounded,
  ),
  _DashboardNavItem(
    label: 'Orders',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
  ),
  _DashboardNavItem(
    label: 'Videos',
    icon: Icons.ondemand_video_outlined,
    selectedIcon: Icons.ondemand_video_rounded,
  ),
  _DashboardNavItem(
    label: 'Deals',
    icon: Icons.local_offer_outlined,
    selectedIcon: Icons.local_offer_rounded,
  ),
  _DashboardNavItem(
    label: 'Profile',
    icon: Icons.manage_accounts_outlined,
    selectedIcon: Icons.manage_accounts_rounded,
  ),
];
