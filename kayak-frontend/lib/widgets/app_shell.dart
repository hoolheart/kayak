import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../generated/app_localizations.dart';

/// 导航项定义
class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String path;
}

/// 导航项列表
const _navItems = <_NavItem>[
  _NavItem(
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
    path: '/dashboard',
  ),
  _NavItem(
    icon: Icons.build_outlined,
    selectedIcon: Icons.build,
    path: '/workbenches',
  ),
  _NavItem(
    icon: Icons.science_outlined,
    selectedIcon: Icons.science,
    path: '/methods',
  ),
  _NavItem(
    icon: Icons.biotech_outlined,
    selectedIcon: Icons.biotech,
    path: '/experiments',
  ),
  _NavItem(
    icon: Icons.analytics_outlined,
    selectedIcon: Icons.analytics,
    path: '/analysis',
  ),
  _NavItem(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    path: '/settings',
  ),
];

/// 根据 AppLocalizations 获取导航项标签
List<String> _navLabels(AppLocalizations loc) => [
      loc.dashboard,
      loc.workbenches,
      loc.methods,
      loc.experiments,
      loc.analysis,
      loc.settings,
    ];

/// 应用外壳 — 响应式导航布局
///
/// 根据屏幕宽度自动切换导航模式：
/// - < 600px: BottomNavigationBar（底部导航）
/// - 600-1200px: NavigationRail（左侧可折叠）
/// - > 1200px: NavigationRail（左侧常驻展开）
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return _MobileLayout(child: child);
        } else if (constraints.maxWidth < 1200) {
          return _TabletLayout(child: child);
        } else {
          return _DesktopLayout(child: child);
        }
      },
    );
  }
}

/// 小屏布局（< 600px）— BottomNavigationBar 底部导航
class _MobileLayout extends ConsumerWidget {
  const _MobileLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final loc = AppLocalizations.of(context)!;
    final labels = _navLabels(loc);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(currentPath),
        onDestinationSelected: (index) {
          if (index >= 0 && index < _navItems.length) {
            context.go(_navItems[index].path);
          }
        },
        destinations: _navItems.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          return NavigationDestination(
            icon: Icon(item.icon),
            selectedIcon: Icon(item.selectedIcon),
            label: i < labels.length ? labels[i] : '',
          );
        }).toList(),
      ),
    );
  }
}

/// 中屏布局（600-1200px）— NavigationRail 可折叠（默认折叠）
class _TabletLayout extends ConsumerStatefulWidget {
  const _TabletLayout({required this.child});

  final Widget child;

  @override
  ConsumerState<_TabletLayout> createState() => _TabletLayoutState();
}

class _TabletLayoutState extends ConsumerState<_TabletLayout> {
  bool _isRailExtended = false;

  @override
  Widget build(BuildContext context) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final loc = AppLocalizations.of(context)!;
    final labels = _navLabels(loc);

    return Row(
      children: [
        NavigationRail(
          extended: _isRailExtended,
          selectedIndex: _calculateSelectedIndex(currentPath),
          onDestinationSelected: (index) {
            if (index >= 0 && index < _navItems.length) {
              context.go(_navItems[index].path);
            }
          },
          leading: _buildLeading(context),
          trailing: _buildTrailing(context),
          labelType: _isRailExtended
              ? NavigationRailLabelType.none
              : NavigationRailLabelType.all,
          destinations: _navItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: Text(i < labels.length ? labels[i] : ''),
            );
          }).toList(),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: widget.child),
      ],
    );
  }

  Widget _buildLeading(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Icon(
            Icons.kayaking,
            color: Theme.of(context).colorScheme.primary,
            size: 32,
          ),
        ),
        if (_isRailExtended)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Kayak',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
        const Divider(),
      ],
    );
  }

  Widget _buildTrailing(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: IconButton(
        icon: Icon(
          _isRailExtended ? Icons.chevron_left : Icons.chevron_right,
        ),
        onPressed: () {
          setState(() {
            _isRailExtended = !_isRailExtended;
          });
        },
        tooltip: _isRailExtended ? 'Collapse' : 'Expand',
      ),
    );
  }
}

/// 大屏布局（> 1200px）— NavigationRail 常驻展开
class _DesktopLayout extends ConsumerWidget {
  const _DesktopLayout({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final loc = AppLocalizations.of(context)!;
    final labels = _navLabels(loc);

    return Row(
      children: [
        NavigationRail(
          extended: true,
          selectedIndex: _calculateSelectedIndex(currentPath),
          onDestinationSelected: (index) {
            if (index >= 0 && index < _navItems.length) {
              context.go(_navItems[index].path);
            }
          },
          leading: _buildLeading(context),
          labelType: NavigationRailLabelType.none,
          minExtendedWidth: 220,
          destinations: _navItems.asMap().entries.map((entry) {
            final i = entry.key;
            final item = entry.value;
            return NavigationRailDestination(
              icon: Icon(item.icon),
              selectedIcon: Icon(item.selectedIcon),
              label: Text(i < labels.length ? labels[i] : ''),
            );
          }).toList(),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: child),
      ],
    );
  }

  Widget _buildLeading(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.kayaking,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                'Kayak',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
        ),
        const Divider(),
      ],
    );
  }
}

/// 根据当前路径计算导航项索引
int _calculateSelectedIndex(String currentLocation) {
  // 对每个导航项，检查当前路径是否以导航项路径开头
  for (int i = 0; i < _navItems.length; i++) {
    final path = _navItems[i].path;
    // 精确匹配或以 path/ 开头（匹配子路径如 /workbenches/123）
    if (currentLocation == path || currentLocation.startsWith('$path/')) {
      return i;
    }
  }
  return 0; // 默认选中首页
}
