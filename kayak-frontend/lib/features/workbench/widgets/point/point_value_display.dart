/// 测点值显示组件
///
/// 根据数据类型格式化显示测点值
library;

import 'package:flutter/material.dart';
import '../../models/point.dart';

/// 测点值显示组件
class PointValueDisplay extends StatelessWidget {
  const PointValueDisplay({
    super.key,
    required this.value,
    required this.dataType,
  });
  final PointValue value;
  final DataType dataType;

  @override
  Widget build(BuildContext context) {
    final formattedValue = _formatValue(value.value);

    if (dataType == DataType.boolean) {
      final bool boolValue = value.value is bool
          ? value.value as bool
          : (value.value is num && (value.value as num) != 0);
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            boolValue ? Icons.toggle_on : Icons.toggle_off,
            color: boolValue ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(formattedValue),
        ],
      );
    }

    return Text(
      formattedValue,
      key: Key('point-value-display-${value.pointId}'),
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'monospace',
          ),
    );
  }

  String _formatValue(dynamic val) {
    if (val == null) return '--';

    switch (dataType) {
      case DataType.number:
        if (val is num) {
          return val.toStringAsFixed(2);
        }
        return val.toString();
      case DataType.integer:
        if (val is num) {
          return val.toInt().toString();
        }
        return val.toString();
      case DataType.string:
      case DataType.boolean:
        return val.toString();
    }
  }
}
