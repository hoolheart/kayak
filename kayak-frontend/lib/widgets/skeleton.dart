import 'package:flutter/material.dart';

/// 骨架屏类型。
enum SkeletonType {
  /// 列表项骨架屏：圆形头像 + 标题行 + 描述行。
  list,

  /// 卡片骨架屏：16:9 图片区域 + 标题 + 描述。
  card,

  /// 纯文本骨架屏：1-3 行文字占位。
  text,

  /// 圆形头像骨架屏。
  avatar,
}

/// 骨架屏组件。
///
/// 用于内容加载过程中的占位展示，通过 shimmer 动画减轻用户等待焦虑。
///
/// 用法：
/// ```dart
/// // 列表骨架屏（4 项）
/// const Skeleton(type: SkeletonType.list, count: 4)
///
/// // 卡片骨架屏
/// const Skeleton(type: SkeletonType.card)
///
/// // 文本骨架屏（3 行）
/// const Skeleton(type: SkeletonType.text, count: 3)
/// ```
class Skeleton extends StatefulWidget {
  const Skeleton({
    super.key,
    this.type = SkeletonType.list,
    this.count,
  });

  /// 骨架屏类型。
  final SkeletonType type;

  /// 显示项数。
  ///
  /// - 列表骨架屏：默认为响应式值（Mobile=3, Tablet=4, Desktop=5）
  /// - 文本骨架屏：默认为 3 行
  /// - 卡片骨架屏：默认为 1
  /// - 头像骨架屏：默认为 1
  final int? count;

  @override
  State<Skeleton> createState() => _SkeletonState();
}

class _SkeletonState extends State<Skeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _defaultCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    switch (widget.type) {
      case SkeletonType.list:
        if (width < 600) return 3;
        if (width < 1024) return 4;
        return 5;
      case SkeletonType.text:
        return 3;
      case SkeletonType.card:
        return 1;
      case SkeletonType.avatar:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.count ?? _defaultCount(context);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return _ShimmerContainer(
          animation: _controller,
          child: child!,
        );
      },
      child: _buildContent(context, count),
    );
  }

  Widget _buildContent(BuildContext context, int count) {
    switch (widget.type) {
      case SkeletonType.list:
        return _buildListSkeleton(count);
      case SkeletonType.card:
        return _buildCardSkeleton();
      case SkeletonType.text:
        return _buildTextSkeleton(count);
      case SkeletonType.avatar:
        return _buildAvatarSkeleton();
    }
  }

  Widget _buildListSkeleton(int count) {
    return Column(
      children: List.generate(count, (index) {
        final showBottomPadding = index < count - 1;
        return Padding(
          padding: EdgeInsets.only(
            bottom: showBottomPadding ? 16.0 : 0,
            left: 16,
            right: 16,
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ShimmerPlaceholder(
                width: 40,
                height: 40,
                borderRadius: 20,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ShimmerPlaceholder(
                      width: double.infinity,
                      height: 16,
                      widthFraction: 0.6,
                    ),
                    SizedBox(height: 8),
                    _ShimmerPlaceholder(
                      width: double.infinity,
                      height: 14,
                    ),
                    SizedBox(height: 4),
                    _ShimmerPlaceholder(
                      width: double.infinity,
                      height: 14,
                      widthFraction: 0.7,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildCardSkeleton() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 16:9 图片区域
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: _ShimmerPlaceholder(
                width: double.infinity,
                height: double.infinity,
                borderRadius: 0,
              ),
            ),
          ),
          SizedBox(height: 16),
          // 标题
          _ShimmerPlaceholder(
            width: double.infinity,
            height: 16,
            widthFraction: 0.6,
          ),
          SizedBox(height: 8),
          // 描述行1
          _ShimmerPlaceholder(
            width: double.infinity,
            height: 14,
          ),
          SizedBox(height: 4),
          // 描述行2
          _ShimmerPlaceholder(
            width: double.infinity,
            height: 14,
            widthFraction: 0.85,
          ),
          SizedBox(height: 12),
          // 底部信息
          Row(
            children: [
              _ShimmerPlaceholder(
                width: 80,
                height: 12,
              ),
              Spacer(),
              _ShimmerPlaceholder(
                width: 100,
                height: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTextSkeleton(int lines) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lines, (index) {
          final isLastLine = index == lines - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: index < lines - 1 ? 8.0 : 0),
            child: _ShimmerPlaceholder(
              width: double.infinity,
              height: 14,
              widthFraction: isLastLine ? 0.7 : 1.0,
            ),
          );
        }),
      ),
    );
  }

  Widget _buildAvatarSkeleton() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: _ShimmerPlaceholder(
          width: 80,
          height: 80,
          borderRadius: 40,
        ),
      ),
    );
  }
}

/// Shimmer 动画容器，使用 ShaderMask 实现光泽扫过效果。
class _ShimmerContainer extends StatelessWidget {
  const _ShimmerContainer({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final baseColor = colorScheme.surfaceContainerHighest.withAlpha(128);
    final shimmerColor = colorScheme.surfaceContainerHighest.withAlpha(204);

    return ShaderMask(
      blendMode: BlendMode.srcATop,
      shaderCallback: (bounds) {
        return LinearGradient(
          colors: [
            baseColor,
            baseColor,
            shimmerColor,
            baseColor,
            baseColor,
          ],
          stops: [
            0.0,
            animation.value - 0.3,
            animation.value,
            animation.value + 0.3,
            1.0,
          ],
        ).createShader(bounds);
      },
      child: child,
    );
  }
}

/// Shimmer 占位块。
class _ShimmerPlaceholder extends StatelessWidget {
  const _ShimmerPlaceholder({
    required this.width,
    required this.height,
    this.borderRadius = 4,
    this.widthFraction,
  });

  final double width;
  final double height;
  final double borderRadius;
  final double? widthFraction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: widthFraction != null ? width * widthFraction! : width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withAlpha(128),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}
