import 'package:flutter/material.dart';

import '../../../widgets/skeleton.dart' show ShimmerBlock;

/// 仪表盘整体骨架屏组件。
///
/// 包含所有区域的加载占位：
/// - 欢迎区域：问候语 + 日期文字骨架
/// - 快捷操作：4 个卡片骨架
/// - 统计概览：3 个数字卡片骨架
/// - 最近工作台：4 个水平卡片骨架
///
/// 各区域骨架屏随各自数据就绪独立消失。
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 600;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isCompact ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 欢迎区域骨架
          _buildWelcomeSkeleton(),
          const SizedBox(height: 24),

          // 快捷操作骨架
          _buildQuickActionsSkeleton(isCompact),
          const SizedBox(height: 24),

          // 统计概览骨架
          _buildStatsSkeleton(isCompact, colorScheme),
          const SizedBox(height: 24),

          // 最近工作台骨架
          _buildRecentSectionSkeleton(cardWidth: isCompact ? 180 : 240),
        ],
      ),
    );
  }

  Widget _buildWelcomeSkeleton() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerBlock(width: 200, height: 32),
        SizedBox(height: 8),
        ShimmerBlock(width: 160, height: 20),
      ],
    );
  }

  Widget _buildQuickActionsSkeleton(bool isCompact) {
    final crossAxisCount = isCompact ? 2 : 4;
    final gap = isCompact ? 8.0 : 16.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        childAspectRatio: 1.5,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ShimmerBlock(width: 48, height: 48, borderRadius: 8),
              SizedBox(height: 8),
              ShimmerBlock(width: 100, height: 16),
              SizedBox(height: 4),
              ShimmerBlock(width: 80, height: 14),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsSkeleton(bool isCompact, ColorScheme colorScheme) {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: index < 2 ? (isCompact ? 8.0 : 16.0) : 0,
            ),
            child: _buildStatCardSkeleton(isCompact, colorScheme),
          ),
        );
      }),
    );
  }

  Widget _buildStatCardSkeleton(bool isCompact, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ShimmerBlock(width: 28, height: 28, borderRadius: 14),
          SizedBox(height: 8),
          ShimmerBlock(width: 48, height: 48),
          SizedBox(height: 4),
          ShimmerBlock(width: 60, height: 16),
        ],
      ),
    );
  }

  Widget _buildRecentSectionSkeleton({required double cardWidth}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ShimmerBlock(width: 160, height: 24),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Container(
                  width: cardWidth,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerBlock(width: 24, height: 24, borderRadius: 12),
                      SizedBox(height: 8),
                      ShimmerBlock(width: 120, height: 16),
                      SizedBox(height: 8),
                      ShimmerBlock(width: 80, height: 14),
                      SizedBox(height: 4),
                      ShimmerBlock(width: 60, height: 14),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
