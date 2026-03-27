import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'breadcrumb_nav.dart';
import 'sidebar.dart';

/// AppShell component that provides the main application layout
/// with responsive sidebar and content area
class AppShell extends StatefulWidget {
  final Widget child;
  final String? selectedRoute;

  const AppShell({
    super.key,
    required this.child,
    this.selectedRoute,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive breakpoint: collapse sidebar when width < 900px
        final isWideScreen = constraints.maxWidth > 900;

        // Auto-collapse on smaller screens
        final shouldAutoCollapse = constraints.maxWidth <= 1200;

        // Update sidebar collapsed state based on screen size
        if (isWideScreen && shouldAutoCollapse) {
          // Wide but not very wide - collapse
          if (!_isSidebarCollapsed && constraints.maxWidth <= 1200) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _isSidebarCollapsed = true);
              }
            });
          }
        } else if (constraints.maxWidth > 1200) {
          // Very wide - expand
          if (_isSidebarCollapsed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _isSidebarCollapsed = false);
              }
            });
          }
        }

        return Scaffold(
          body: Row(
            children: [
              // Sidebar
              Sidebar(
                isCollapsed: _isSidebarCollapsed,
                selectedRoute: widget.selectedRoute,
                onToggleCollapse: () {
                  setState(() {
                    _isSidebarCollapsed = !_isSidebarCollapsed;
                  });
                },
              ),

              // Main content area
              Expanded(
                child: Column(
                  children: [
                    // Breadcrumb navigation
                    const BreadcrumbNav(),

                    // Content
                    Expanded(
                      child: Container(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerLowest,
                        child: widget.child,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shell route wrapper that provides AppShell context
class AppShellRouteWrapper extends StatelessWidget {
  final Widget child;
  final String location;

  const AppShellRouteWrapper({
    super.key,
    required this.child,
    required this.location,
  });

  @override
  Widget build(BuildContext context) {
    return AppShell(
      selectedRoute: location,
      child: child,
    );
  }
}

/// Redirects to the appropriate sub-route when accessing a parent route
class AppShellRedirect extends StatelessWidget {
  final String targetLocation;

  const AppShellRedirect({
    super.key,
    required this.targetLocation,
  });

  @override
  Widget build(BuildContext context) {
    // Perform immediate redirect
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.go(targetLocation);
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
