// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_tree_node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeviceTreeNodeImpl _$$DeviceTreeNodeImplFromJson(Map<String, dynamic> json) =>
    _$DeviceTreeNodeImpl(
      device: Device.fromJson(json['device'] as Map<String, dynamic>),
      children: (json['children'] as List<dynamic>)
          .map((e) => DeviceTreeNode.fromJson(e as Map<String, dynamic>))
          .toList(),
      isExpanded: json['isExpanded'] as bool? ?? false,
    );

Map<String, dynamic> _$$DeviceTreeNodeImplToJson(
        _$DeviceTreeNodeImpl instance) =>
    <String, dynamic>{
      'device': instance.device,
      'children': instance.children,
      'isExpanded': instance.isExpanded,
    };
