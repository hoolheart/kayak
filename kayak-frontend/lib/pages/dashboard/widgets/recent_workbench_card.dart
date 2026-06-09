import 'package:flutter/material.dart';

import '../../../generated/app_localizations.dart';
import '../../../services/dashboard_service.dart';

/// 最近工作台卡片组件。
///
/// 显示工作台名称、设备数量、相对更新时间。
/// 整张卡片可点击导航到工作台详情。
class RecentWorkbenchCard extends StatefulWidget {
  const RecentWorkbenchCard({
    super.key,
    required this.workbench,
    required this.onTap,
    this.width = 240,
    this.compact = false,
  });

  /// 工作台摘要数据
  final WorkbenchSummary workbench;

  /// 点击回调
  final VoidCallback onTap;

  /// 卡片宽度
  final double width;

  /// 紧凑模式
  final bool compact;

  @override
  State<RecentWorkbenchCard> createState() => _RecentWorkbenchCardState();
}

class _RecentWorkbenchCardState extends State<RecentWorkbenchCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final loc = AppLocalizations.of(context)!;

    final wb = widget.workbench;

    // 设备数量文本
    final deviceCountText = wb.deviceCount != null
        ? loc.deviceCountWithUnit(wb.deviceCount!)
        : null;

    // 相对时间文本
    final relativeTime = _formatRelativeTime(wb.updatedAt, loc);

    final transformMatrix = _isHovered
        ? Matrix4.diagonal3Values(0.98, 0.98, 1.0)
        : Matrix4.identity();

    return Semantics(
      label: '${wb.name}, ${deviceCountText ?? ''}, $relativeTime',
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            transform: transformMatrix,
            width: widget.width,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outlineVariant),
              boxShadow: [
                if (_isHovered)
                  BoxShadow(
                    color: colorScheme.shadow.withAlpha(26),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: widget.onTap,
                child: Container(
                  decoration: _isHovered
                      ? BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: colorScheme.primary,
                              width: 3,
                            ),
                          ),
                        )
                      : null,
                  padding: EdgeInsets.all(widget.compact ? 12 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 图标
                      Icon(
                        Icons.build_outlined,
                        size: widget.compact ? 20 : 24,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      // 名称
                      Text(
                        wb.name,
                        style:
                            (widget.compact
                                    ? textTheme.bodyLarge
                                    : textTheme.titleMedium)
                                ?.copyWith(color: colorScheme.onSurface),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // 设备数量
                      if (deviceCountText != null)
                        Text(
                          deviceCountText,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      // 更新时间
                      Text(
                        relativeTime,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withAlpha(153),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 将 [DateTime] 格式化为相对时间字符串。
  String _formatRelativeTime(DateTime dateTime, AppLocalizations loc) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) return loc.justNow;
    if (diff.inMinutes < 60) return loc.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return loc.hoursAgo(diff.inHours);
    if (diff.inDays < 7) return loc.daysAgo(diff.inDays);
    if (diff.inDays < 30) return loc.weeksAgo(diff.inDays ~/ 7);
    return loc.monthsAgo(diff.inDays ~/ 30);
  }
}
