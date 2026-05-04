/// 测点配置 Provider
///
/// 管理 Modbus 测点配置表单状态和测点列表的增删改查。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/modbus_point_config.dart';
import '../validators/device_validators.dart';

/// 测点配置表单 Notifier
class PointConfigFormNotifier extends StateNotifier<PointConfigFormState> {
  PointConfigFormNotifier() : super(PointConfigFormState.initial());

  /// 编辑中的测点索引 (-1 表示新增)
  int _editingIndex = -1;

  /// 获取当前编辑索引
  int get editingIndex => _editingIndex;

  /// 是否处于编辑模式
  bool get isEditing => _editingIndex >= 0;

  /// 更新功能码
  void updateFunctionCode(ModbusFunctionCode fc) {
    // FC01/FC02 锁定数据类型为 BOOL
    final newDataType = fc.isBoolLocked ? ModbusDataType.bool_ : state.dataType;

    // 如果之前是 FC01/FC02 且切换到 FC03/FC04，恢复默认数据类型
    final effectiveDataType =
        (state.functionCode.isBoolLocked && !fc.isBoolLocked)
            ? ModbusDataType.uint16
            : newDataType;

    state = state.copyWith(
      functionCode: fc,
      dataType: effectiveDataType,
      // 清除之前验证错误 (功能码变化可能改变约束)
      clearAddressError: true,
      clearQuantityError: true,
    );

    // 功能码变化后重新验证 (如果已有输入)
    _validateAfterChange();
  }

  /// 更新地址
  void updateAddress(String value) {
    final error = DeviceValidators.modbusAddress(value);
    state = state.copyWith(address: value, addressError: error);
    // 联合约束重新验证
    _revalidateJointConstraints();
  }

  /// 更新数量
  void updateQuantity(String value) {
    String? error;

    if (state.dataType == ModbusDataType.float32) {
      error = DeviceValidators.modbusQuantityForFloat32(value, state.address);
    } else {
      error = DeviceValidators.modbusQuantity(value);
    }

    state = state.copyWith(quantity: value, quantityError: error);

    // 联合约束重新验证
    _revalidateJointConstraints();
  }

  /// 更新数据类型
  void updateDataType(ModbusDataType dt) {
    state = state.copyWith(
      dataType: dt,
      clearQuantityError: true,
    );

    // 类型变化可能改变数量约束，重新验证数量
    if (state.quantity.isNotEmpty) {
      _revalidateJointConstraints();
    }
  }

  /// 更新缩放因子
  void updateScale(String value) {
    final error = DeviceValidators.modbusScale(value);
    state = state.copyWith(scale: value, scaleError: error);
  }

  /// 更新偏移量
  void updateOffset(String value) {
    final error = DeviceValidators.modbusOffset(value);
    state = state.copyWith(offset: value, offsetError: error);
  }

  /// 重置为初始状态
  void reset() {
    _editingIndex = -1;
    state = PointConfigFormState.initial();
  }

  /// 加载配置用于编辑
  void loadForEdit(int index, ModbusPointConfig config) {
    _editingIndex = index;
    state = PointConfigFormState.fromConfig(config);
  }

  /// 验证整个表单
  bool validate() {
    final addressError = DeviceValidators.modbusAddress(state.address);
    String? quantityError;

    if (state.dataType == ModbusDataType.float32) {
      quantityError = DeviceValidators.modbusQuantityForFloat32(
        state.quantity,
        state.address,
      );
    } else {
      quantityError = DeviceValidators.modbusQuantity(state.quantity);
    }

    final scaleError = DeviceValidators.modbusScale(state.scale);
    final offsetError = DeviceValidators.modbusOffset(state.offset);

    // 非 float32 的联合约束
    String? jointError;
    if (state.dataType != ModbusDataType.float32) {
      jointError =
          DeviceValidators.modbusAddressQuantity(state.address, state.quantity);
    }

    state = state.copyWith(
      addressError: addressError,
      quantityError: quantityError,
      scaleError: scaleError,
      offsetError: offsetError,
    );

    // 如果有联合约束错误且没有独立的地址/数量错误，添加到数量错误
    if (jointError != null && quantityError == null && addressError == null) {
      state = state.copyWith(quantityError: jointError);
    }

    return state.isValid;
  }

  /// 功能码变化后重新验证
  void _validateAfterChange() {
    if (state.address.isNotEmpty) {
      updateAddress(state.address);
    }
    if (state.quantity.isNotEmpty) {
      // 直接重新验证
      _revalidateJointConstraints();
    }
  }

  /// 重新验证联合约束 (地址+数量)
  void _revalidateJointConstraints() {
    if (state.address.isEmpty || state.quantity.isEmpty) return;

    String? jointError;
    if (state.dataType == ModbusDataType.float32) {
      final qtyError = DeviceValidators.modbusQuantityForFloat32(
        state.quantity,
        state.address,
      );
      if (qtyError != null) {
        state = state.copyWith(quantityError: qtyError);
      }
    } else {
      jointError =
          DeviceValidators.modbusAddressQuantity(state.address, state.quantity);
      if (jointError != null &&
          state.addressError == null &&
          state.quantityError == null) {
        state = state.copyWith(quantityError: jointError);
      }
    }
  }
}

/// 测点配置列表 Notifier
///
/// 管理配置的测点列表，支持增删改查和重叠检测。
class PointConfigListNotifier extends StateNotifier<List<ModbusPointConfig>> {
  PointConfigListNotifier() : super([]);

  /// 获取测点数量
  int get count => state.length;

  /// 是否为空
  bool get isEmpty => state.isEmpty;

  /// 添加测点配置
  /// 返回 true 表示添加成功，false 表示存在重叠冲突
  bool addConfig(ModbusPointConfig config) {
    // 检测地址重叠
    for (final existing in state) {
      if (config.overlapsWith(existing)) {
        return false; // 冲突
      }
    }
    state = [...state, config];
    return true;
  }

  /// 更新指定索引的测点配置
  /// 返回 true 表示更新成功，false 表示存在重叠冲突
  bool updateConfig(int index, ModbusPointConfig config) {
    if (index < 0 || index >= state.length) return false;

    // 检测地址重叠 (排除自身)
    for (int i = 0; i < state.length; i++) {
      if (i == index) continue;
      if (config.overlapsWith(state[i])) {
        return false; // 冲突
      }
    }

    final updated = List<ModbusPointConfig>.from(state);
    updated[index] = config;
    state = updated;
    return true;
  }

  /// 删除指定索引的测点配置
  void removeConfig(int index) {
    if (index < 0 || index >= state.length) return;
    final updated = List<ModbusPointConfig>.from(state);
    updated.removeAt(index);
    state = updated;
  }

  /// 清空所有测点配置
  void clearAll() {
    state = [];
  }

  /// 根据索引获取配置
  ModbusPointConfig? getConfig(int index) {
    if (index < 0 || index >= state.length) return null;
    return state[index];
  }
}

/// Provider: 测点配置表单状态
final pointConfigFormProvider =
    StateNotifierProvider<PointConfigFormNotifier, PointConfigFormState>((ref) {
  return PointConfigFormNotifier();
});

/// Provider: 测点配置列表 (单个设备的配置列表)
final pointConfigListProvider =
    StateNotifierProvider<PointConfigListNotifier, List<ModbusPointConfig>>(
        (ref) {
  return PointConfigListNotifier();
});
