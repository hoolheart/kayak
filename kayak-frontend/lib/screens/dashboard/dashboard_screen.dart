/// @deprecated Dashboard screen has been moved
///
/// The DashboardScreen has been migrated to:
/// lib/features/dashboard/screens/dashboard_screen.dart
///
/// Please import and use the new location instead.
///
/// This file is kept for backward compatibility with imports.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';

@Deprecated('Use DashboardScreen from features/dashboard/screens/ instead')
class OldDashboardScreen extends ConsumerStatefulWidget {
  const OldDashboardScreen({super.key});

  @override
  ConsumerState<OldDashboardScreen> createState() => _OldDashboardScreenState();
}

class _OldDashboardScreenState extends ConsumerState<OldDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    return const DashboardScreen();
  }
}
