import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'navigation_item.dart';

/// Breadcrumb navigation component
/// Auto-generates breadcrumbs from current route and displays clickable navigation links
class BreadcrumbNav extends StatelessWidget {
  final String? currentRoute;

  const BreadcrumbNav({
    super.key,
    this.currentRoute,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final location = currentRoute ?? GoRouterState.of(context).uri.path;
    final breadcrumbs = BreadcrumbItem.fromRoute(location);

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.place,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _buildBreadcrumbItems(context, breadcrumbs),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbItems(
    BuildContext context,
    List<BreadcrumbItem> breadcrumbs,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final items = <Widget>[];

    for (int i = 0; i < breadcrumbs.length; i++) {
      final item = breadcrumbs[i];

      if (i > 0) {
        // Add separator
        items.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              Icons.chevron_right,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        );
      }

      // Add breadcrumb item
      items.add(
        _BreadcrumbText(
          label: item.label,
          isClickable: !item.isCurrent && item.route != null,
          isCurrent: item.isCurrent,
          onTap: item.route != null ? () => context.go(item.route!) : null,
        ),
      );
    }

    return items;
  }
}

/// Individual breadcrumb text item with styling
class _BreadcrumbText extends StatelessWidget {
  final String label;
  final bool isClickable;
  final bool isCurrent;
  final VoidCallback? onTap;

  const _BreadcrumbText({
    required this.label,
    required this.isClickable,
    required this.isCurrent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isClickable) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: isCurrent
                  ? colorScheme.onSurface
                  : colorScheme.onSurfaceVariant,
              fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
            ),
      ),
    );
  }
}
