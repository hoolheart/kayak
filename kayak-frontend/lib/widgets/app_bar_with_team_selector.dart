/// AppBar with team selector integration
library;

import 'package:flutter/material.dart';

import '../../features/team/widgets/team_selector.dart';

/// AppBar with integrated team selector
class AppBarWithTeamSelector extends StatelessWidget
    implements PreferredSizeWidget {
  const AppBarWithTeamSelector({
    super.key,
    this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
  });
  final Widget? title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Row(
        children: [
          if (title != null) title!,
          if (title != null) const SizedBox(width: 16),
          const TeamSelector(),
        ],
      ),
      actions: actions,
    );
  }
}
