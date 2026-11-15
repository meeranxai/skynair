import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/notification_provider.dart';
import '../../models/notification_model.dart';
import '../../services/permission_service.dart';
import '../../services/session_service.dart';
import '../../widgets/top_notification_banner.dart';


class NavigationItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final String route;

  const NavigationItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.route,
  });
}

class MainLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MainLayout({super.key, required this.child});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _selectedIndex = 0;
  String? _lastNotificationId;
  OverlayEntry? _notificationOverlay;

  @override
  void initState() {
    super.initState();
    // Initialize session usage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionServiceProvider).initSession();
    });
  }

  void _showTopNotification(NotificationModel notification) {
    _notificationOverlay?.remove();
    _notificationOverlay = OverlayEntry(
      builder: (context) => TopNotificationBanner(
        title: 'New Notification',
        message: notification.message,
        type: notification.type,
        onTap: () => context.push('/notifications'),
        onDismiss: () {
          _notificationOverlay?.remove();
          _notificationOverlay = null;
        },
      ),
    );
    Overlay.of(context).insert(_notificationOverlay!);
  }


  // Phase 1: Articles-focused navigation
  final List<NavigationItem> _navigationItems = [
    NavigationItem(
      icon: Icons.photo_library_outlined,
      selectedIcon: Icons.photo_library,
      label: 'Home',
      route: '/home',
    ),
    NavigationItem(
      icon: Icons.add_box_outlined,
      selectedIcon: Icons.add_box,
      label: 'Create',
      route: '/create',
    ),
    NavigationItem(
      icon: Icons.explore_outlined,
      selectedIcon: Icons.explore,
      label: 'Explore',
      route: '/explore',
    ),
    NavigationItem(
      icon: Icons.person_outline,
      selectedIcon: Icons.person,
      label: 'Profile',
      route: '/profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Global Notification Listener
    ref.listen<AsyncValue<List<NotificationModel>>>(
      notificationsStreamProvider,
      (previous, next) {
        next.whenData((notifications) {
          if (notifications.isEmpty) return;

          final latest = notifications.first;
          
          // If this is the first load, just set the ID (don't spam popup)
          if (_lastNotificationId == null) {
            _lastNotificationId = latest.id;
            return;
          }

          // If we have a new notification ID that is different from the last one
          // AND it is not read (optional, but good for UX)
          if (latest.id != _lastNotificationId) {
            _lastNotificationId = latest.id;

            // Show Top Notification
            _showTopNotification(latest);
          }
        });
      },
    );

    final currentLocation = GoRouterState.of(context).matchedLocation;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final isKeyboardVisible = mediaQuery.viewInsets.bottom > 0;

    // Update selected index based on current route
    _selectedIndex = _navigationItems.indexWhere(
      (item) => currentLocation.startsWith(item.route),
    );
    if (_selectedIndex == -1) _selectedIndex = 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: widget.child,
      bottomNavigationBar: isKeyboardVisible 
          ? null 
          : Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (index) {
                  if (index == 1) { // Create
                    context.push('/create?type=media');
                  } else if (index != _selectedIndex) {
                    context.go(_navigationItems[index].route);
                  }
                },
                backgroundColor: theme.colorScheme.surface,
                elevation: 0, 
                height: 65,
                surfaceTintColor: Colors.transparent,
                indicatorColor: Colors.transparent,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                destinations: _navigationItems.map((item) {
                  final isSelected = _navigationItems.indexOf(item) == _selectedIndex;
                  return NavigationDestination(
                    icon: Icon(
                      item.icon,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: isSelected ? 1.0 : 0.6),
                      size: 26,
                    ),
                    selectedIcon: Icon(
                      item.selectedIcon,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    label: item.label,
                  );
                }).toList(),
              ),
            ),
    );
  }
}

