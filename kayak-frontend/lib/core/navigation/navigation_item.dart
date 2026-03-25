/// Navigation item model for sidebar navigation
class NavigationItem {
  final String label;
  final String icon;
  final String route;
  final List<NavigationItem>? children;

  const NavigationItem({
    required this.label,
    required this.icon,
    required this.route,
    this.children,
  });

  /// Navigation items for main sidebar
  static const List<NavigationItem> mainItems = [
    NavigationItem(
      label: '首页',
      icon: 'home',
      route: '/dashboard',
    ),
    NavigationItem(
      label: '工作台',
      icon: 'dashboard',
      route: '/workbenches',
    ),
    NavigationItem(
      label: '试验',
      icon: 'science',
      route: '/experiments',
    ),
    NavigationItem(
      label: '方法',
      icon: 'description',
      route: '/methods',
    ),
    NavigationItem(
      label: '设置',
      icon: 'settings',
      route: '/settings',
    ),
  ];
}

/// Breadcrumb item model for breadcrumb navigation
class BreadcrumbItem {
  final String label;
  final String? route;
  final bool isCurrent;

  const BreadcrumbItem({
    required this.label,
    this.route,
    this.isCurrent = false,
  });

  /// Generate breadcrumbs from current route path
  static List<BreadcrumbItem> fromRoute(String path) {
    final items = <BreadcrumbItem>[];

    // Handle root path
    if (path == '/') {
      items.add(const BreadcrumbItem(label: '首页', route: '/dashboard'));
      return items;
    }

    // Parse path segments
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    // Add Dashboard as home
    items.add(const BreadcrumbItem(label: '首页', route: '/dashboard'));

    String currentPath = '';
    for (int i = 0; i < segments.length; i++) {
      currentPath += '/${segments[i]}';
      final isLast = i == segments.length - 1;

      // Generate label from segment
      String label = _generateLabelFromSegment(segments[i]);

      // Handle special routes
      if (segments[i] == 'workbenches' && segments.length > 1) {
        label = '工作台详情';
      } else if (segments[i] == 'experiments' && segments.length > 1) {
        label = '试验详情';
      } else if (segments[i] == 'methods' && segments.length > 1 && i > 0) {
        label = '方法编辑';
      }

      items.add(BreadcrumbItem(
        label: label,
        route: isLast ? null : currentPath,
        isCurrent: isLast,
      ));
    }

    return items;
  }

  /// Generate a human-readable label from URL segment
  static String _generateLabelFromSegment(String segment) {
    // Handle common patterns
    switch (segment) {
      case 'dashboard':
        return '首页';
      case 'workbenches':
        return '工作台';
      case 'experiments':
        return '试验';
      case 'methods':
        return '方法';
      case 'settings':
        return '设置';
      case 'edit':
        return '编辑';
      case 'detail':
        return '详情';
      default:
        // Convert kebab-case or camelCase to readable label
        return segment
            .replaceAll('-', ' ')
            .replaceAll('_', ' ')
            .split(RegExp(r'(?=[A-Z])'))
            .map((word) => word.isEmpty
                ? ''
                : '${word[0].toUpperCase()}${word.substring(1)}')
            .join(' ');
    }
  }
}
