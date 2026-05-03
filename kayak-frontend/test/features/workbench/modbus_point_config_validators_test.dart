/// Modbus 测点配置验证器单元测试
///
/// 覆盖 R1-S2-002-A 测试用例:
///   TC-ADDR-001 ~ TC-ADDR-007 (地址范围验证)
///   TC-QTY-001 ~ TC-QTY-007 (数量验证)
///   TC-SO-001 ~ TC-SO-007 (缩放因子/偏移量验证)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/workbench/validators/device_validators.dart';

void main() {
  group('DeviceValidators - ModbusAddress', () {
    test('TC-ADDR-001: 合法地址最小值 (0)', () {
      expect(DeviceValidators.modbusAddress('0'), isNull);
    });

    test('TC-ADDR-002: 合法地址最大值 (65535)', () {
      expect(DeviceValidators.modbusAddress('65535'), isNull);
    });

    test('TC-ADDR-003: 超出最大值 (65536)', () {
      final result = DeviceValidators.modbusAddress('65536');
      expect(result, isNotNull);
      expect(result, contains('0-65535'));
    });

    test('TC-ADDR-004: 负值输入 (-1)', () {
      final result = DeviceValidators.modbusAddress('-1');
      expect(result, isNotNull);
      expect(result, contains('0-65535'));
    });

    test('TC-ADDR-005: 空输入', () {
      final result = DeviceValidators.modbusAddress('');
      expect(result, isNotNull);
      expect(result, contains('请输入'));
    });

    test('TC-ADDR-005: null输入', () {
      final result = DeviceValidators.modbusAddress(null);
      expect(result, isNotNull);
      expect(result, contains('请输入'));
    });

    test('TC-ADDR-006: 非数字输入', () {
      final result = DeviceValidators.modbusAddress('abc123');
      expect(result, isNotNull);
      expect(result, contains('数字'));
    });

    test('合法中间地址 (30001)', () {
      expect(DeviceValidators.modbusAddress('30001'), isNull);
    });
  });

  group('DeviceValidators - ModbusQuantity', () {
    test('TC-QTY-001: 合法数量最小值 (1)', () {
      expect(DeviceValidators.modbusQuantity('1'), isNull);
    });

    test('TC-QTY-002: 合法数量最大值 (125)', () {
      expect(DeviceValidators.modbusQuantity('125'), isNull);
    });

    test('TC-QTY-003: 超出最大值 (126)', () {
      final result = DeviceValidators.modbusQuantity('126');
      expect(result, isNotNull);
      expect(result, contains('1-125'));
    });

    test('TC-QTY-004: 非法值 (0)', () {
      final result = DeviceValidators.modbusQuantity('0');
      expect(result, isNotNull);
      expect(result, contains('1-125'));
    });

    test('TC-QTY-005: 空输入', () {
      final result = DeviceValidators.modbusQuantity('');
      expect(result, isNotNull);
      expect(result, contains('请输入'));
    });

    test('TC-QTY-005: null输入', () {
      final result = DeviceValidators.modbusQuantity(null);
      expect(result, isNotNull);
      expect(result, contains('请输入'));
    });

    test('TC-QTY-006: 负值输入 (-5)', () {
      final result = DeviceValidators.modbusQuantity('-5');
      expect(result, isNotNull);
      expect(result, contains('1-125'));
    });

    test('合法数量中间值 (62)', () {
      expect(DeviceValidators.modbusQuantity('62'), isNull);
    });
  });

  group('DeviceValidators - ModbusAddressQuantity 联合约束', () {
    test('TC-ADDR-007: 基本越界 - address+quantity > 65536', () {
      final result = DeviceValidators.modbusAddressQuantity('65530', '10');
      expect(result, isNotNull);
      expect(result!, contains('地址+数量超出范围'));
    });

    test('TC-ADDR-007: 边界通过 - address+quantity = 65536', () {
      expect(DeviceValidators.modbusAddressQuantity('65535', '1'), isNull);
    });

    test('TC-ADDR-007: 边界+1失败 - address+quantity = 65537', () {
      final result = DeviceValidators.modbusAddressQuantity('65535', '2');
      expect(result, isNotNull);
      expect(result!, contains('地址+数量超出范围'));
    });

    test('合法范围 - address+quantity < 65536', () {
      expect(DeviceValidators.modbusAddressQuantity('0', '125'), isNull);
      expect(DeviceValidators.modbusAddressQuantity('65400', '100'), isNull);
    });

    test('地址为空时不验证联合约束', () {
      expect(DeviceValidators.modbusAddressQuantity('', '1'), isNull);
      expect(DeviceValidators.modbusAddressQuantity(null, '1'), isNull);
    });

    test('数量为空时不验证联合约束', () {
      expect(DeviceValidators.modbusAddressQuantity('100', ''), isNull);
      expect(DeviceValidators.modbusAddressQuantity('100', null), isNull);
    });
  });

  group('DeviceValidators - ModbusQuantityForFloat32 双重约束', () {
    test('TC-QTY-007: float32数量本身越界 - 63*2=126>125', () {
      final result = DeviceValidators.modbusQuantityForFloat32('63', '0');
      expect(result, isNotNull);
      expect(result, contains('62'));
    });

    test('TC-QTY-007: float32边界通过 - quantity=62', () {
      expect(
        DeviceValidators.modbusQuantityForFloat32('62', '0'),
        isNull,
      );
    });

    test('TC-QTY-007: float32联合边界通过 - 65520+8*2=65536', () {
      expect(
        DeviceValidators.modbusQuantityForFloat32('8', '65520'),
        isNull,
      );
    });

    test('TC-QTY-007: float32联合边界失败 - 65520+9*2=65538', () {
      final result = DeviceValidators.modbusQuantityForFloat32('9', '65520');
      expect(result, isNotNull);
      expect(result, contains('地址+数量超出范围'));
    });

    test('float32合法值 - 10', () {
      expect(
        DeviceValidators.modbusQuantityForFloat32('10', '0'),
        isNull,
      );
    });

    test('float32数量为0时失败', () {
      final result = DeviceValidators.modbusQuantityForFloat32('0', '0');
      expect(result, isNotNull);
      expect(result, contains('1-125'));
    });

    test('address为空时不验证联合约束', () {
      expect(
        DeviceValidators.modbusQuantityForFloat32('10', ''),
        isNull,
      );
      expect(
        DeviceValidators.modbusQuantityForFloat32('10', null),
        isNull,
      );
    });
  });

  group('DeviceValidators - ModbusScale', () {
    test('TC-SO-002: 合法缩放因子 2.5', () {
      expect(DeviceValidators.modbusScale('2.5'), isNull);
    });

    test('TC-SO-004: 缩放因子为 0', () {
      expect(DeviceValidators.modbusScale('0'), isNull);
    });

    test('TC-SO-005: 缩放因子非数字输入', () {
      final result = DeviceValidators.modbusScale('abc');
      expect(result, isNotNull);
      expect(result, contains('数字'));
    });

    test('TC-SO-007: 缩放因子超大值', () {
      expect(DeviceValidators.modbusScale('999999999999'), isNull);
    });

    test('缩放因子负值', () {
      expect(DeviceValidators.modbusScale('-2.5'), isNull);
    });

    test('缩放因子空值', () {
      final result = DeviceValidators.modbusScale('');
      expect(result, isNotNull);
      expect(result, contains('数字'));
    });

    test('缩放因子null值', () {
      final result = DeviceValidators.modbusScale(null);
      expect(result, isNotNull);
      expect(result, contains('数字'));
    });

    test('缩放因子科学计数法', () {
      expect(DeviceValidators.modbusScale('1.5e3'), isNull);
    });
  });

  group('DeviceValidators - ModbusOffset', () {
    test('TC-SO-003: 合法偏移量 -10.5', () {
      expect(DeviceValidators.modbusOffset('-10.5'), isNull);
    });

    test('TC-SO-006: 偏移量空值处理', () {
      final result = DeviceValidators.modbusOffset('');
      expect(result, isNotNull);
      expect(result, contains('数字'));
    });

    test('TC-SO-007: 偏移量超大负值', () {
      expect(DeviceValidators.modbusOffset('-999999999999'), isNull);
    });

    test('偏移量正值', () {
      expect(DeviceValidators.modbusOffset('100.0'), isNull);
    });

    test('偏移量为0', () {
      expect(DeviceValidators.modbusOffset('0'), isNull);
    });

    test('偏移量null值', () {
      final result = DeviceValidators.modbusOffset(null);
      expect(result, isNotNull);
      expect(result, contains('数字'));
    });

    test('偏移量非数字输入', () {
      final result = DeviceValidators.modbusOffset('xyz');
      expect(result, isNotNull);
      expect(result, contains('数字'));
    });
  });
}
