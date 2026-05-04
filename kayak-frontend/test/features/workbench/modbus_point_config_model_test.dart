/// ModbusPointConfig 模型单元测试
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/workbench/models/modbus_point_config.dart';

void main() {
  group('ModbusFunctionCode', () {
    test('fromCode returns correct enum for each code', () {
      expect(ModbusFunctionCode.fromCode(1), ModbusFunctionCode.fc01);
      expect(ModbusFunctionCode.fromCode(2), ModbusFunctionCode.fc02);
      expect(ModbusFunctionCode.fromCode(3), ModbusFunctionCode.fc03);
      expect(ModbusFunctionCode.fromCode(4), ModbusFunctionCode.fc04);
    });

    test('fromCode returns fc03 for invalid code', () {
      expect(ModbusFunctionCode.fromCode(99), ModbusFunctionCode.fc03);
    });

    test('code returns correct values', () {
      expect(ModbusFunctionCode.fc01.code, 1);
      expect(ModbusFunctionCode.fc02.code, 2);
      expect(ModbusFunctionCode.fc03.code, 3);
      expect(ModbusFunctionCode.fc04.code, 4);
    });

    test('isBoolLocked returns true for FC01/FC02 only', () {
      expect(ModbusFunctionCode.fc01.isBoolLocked, isTrue);
      expect(ModbusFunctionCode.fc02.isBoolLocked, isTrue);
      expect(ModbusFunctionCode.fc03.isBoolLocked, isFalse);
      expect(ModbusFunctionCode.fc04.isBoolLocked, isFalse);
    });

    test('isReadOnly returns true for FC02/FC04 only', () {
      expect(ModbusFunctionCode.fc01.isReadOnly, isFalse);
      expect(ModbusFunctionCode.fc02.isReadOnly, isTrue);
      expect(ModbusFunctionCode.fc03.isReadOnly, isFalse);
      expect(ModbusFunctionCode.fc04.isReadOnly, isTrue);
    });

    test('displayText has correct format', () {
      expect(ModbusFunctionCode.fc01.displayText, '01 - Coil (线圈)');
      expect(
        ModbusFunctionCode.fc03.displayText,
        '03 - Holding Register (保持寄存器)',
      );
    });

    test('defaultDataType returns correct type', () {
      expect(ModbusFunctionCode.fc01.defaultDataType, 'bool');
      expect(ModbusFunctionCode.fc03.defaultDataType, 'uint16');
    });
  });

  group('ModbusDataType', () {
    test('fromString returns correct enum', () {
      expect(ModbusDataType.fromString('uint16'), ModbusDataType.uint16);
      expect(ModbusDataType.fromString('int16'), ModbusDataType.int16);
      expect(ModbusDataType.fromString('float32'), ModbusDataType.float32);
      expect(ModbusDataType.fromString('bool'), ModbusDataType.bool_);
    });

    test('fromString returns uint16 for invalid string', () {
      expect(ModbusDataType.fromString('unknown'), ModbusDataType.uint16);
    });

    test('value returns correct strings', () {
      expect(ModbusDataType.uint16.value, 'uint16');
      expect(ModbusDataType.int16.value, 'int16');
      expect(ModbusDataType.float32.value, 'float32');
      expect(ModbusDataType.bool_.value, 'bool');
    });

    test('genericDataType returns correct types', () {
      expect(ModbusDataType.uint16.genericDataType, 'integer');
      expect(ModbusDataType.int16.genericDataType, 'integer');
      expect(ModbusDataType.float32.genericDataType, 'number');
      expect(ModbusDataType.bool_.genericDataType, 'boolean');
    });
  });

  group('ModbusPointConfig', () {
    test('defaults create correct config', () {
      final config = ModbusPointConfig.defaults();
      expect(config.functionCode, ModbusFunctionCode.fc03);
      expect(config.address, 0);
      expect(config.quantity, 1);
      expect(config.dataType, ModbusDataType.uint16);
      expect(config.scale, 1.0);
      expect(config.offset, 0.0);
    });

    test('fromJson parses correctly', () {
      final json = {
        'function_code': 3,
        'address': 100,
        'quantity': 5,
        'data_type': 'uint16',
        'scale': 2.5,
        'offset': 10.0,
      };
      final config = ModbusPointConfig.fromJson(json);
      expect(config.functionCode, ModbusFunctionCode.fc03);
      expect(config.address, 100);
      expect(config.quantity, 5);
      expect(config.dataType, ModbusDataType.uint16);
      expect(config.scale, 2.5);
      expect(config.offset, 10.0);
    });

    test('toJson produces correct format', () {
      const config = ModbusPointConfig(
        functionCode: ModbusFunctionCode.fc04,
        address: 200,
        quantity: 3,
        dataType: ModbusDataType.float32,
        offset: -5.0,
      );
      final json = config.toJson();
      expect(json['function_code'], 4);
      expect(json['address'], 200);
      expect(json['quantity'], 3);
      expect(json['data_type'], 'float32');
      expect(json['scale'], 1.0);
      expect(json['offset'], -5.0);
    });

    test('copyWith replaces specified fields', () {
      final config = ModbusPointConfig.defaults();
      final updated = config.copyWith(
        functionCode: ModbusFunctionCode.fc01,
        address: 42,
      );
      expect(updated.functionCode, ModbusFunctionCode.fc01);
      expect(updated.address, 42);
      expect(updated.quantity, 1); // unchanged
    });

    test('addressRange for non-float32 types', () {
      const config = ModbusPointConfig(
        address: 10,
        quantity: 5,
      );
      final (start, end) = config.addressRange;
      expect(start, 10);
      expect(end, 14); // 10 + 5 - 1
    });

    test('addressRange for float32 type (each quantity = 2 registers)', () {
      const config = ModbusPointConfig(
        address: 10,
        quantity: 3,
        dataType: ModbusDataType.float32,
      );
      final (start, end) = config.addressRange;
      expect(start, 10);
      expect(end, 15); // 10 + 3*2 - 1
    });

    test('registerCount for non-float32 types', () {
      const config = ModbusPointConfig(
        address: 0,
        quantity: 5,
      );
      expect(config.registerCount, 5);
    });

    test('registerCount for float32 type', () {
      const config = ModbusPointConfig(
        address: 0,
        quantity: 5,
        dataType: ModbusDataType.float32,
      );
      expect(config.registerCount, 10);
    });

    group('overlapsWith', () {
      test('完全重叠检测', () {
        const a = ModbusPointConfig(
          address: 0,
          quantity: 5,
        );
        const b = ModbusPointConfig(
          address: 0,
          quantity: 3,
        );
        expect(a.overlapsWith(b), isTrue);
      });

      test('部分重叠检测', () {
        const a = ModbusPointConfig(
          address: 0,
          quantity: 5,
        );
        const b = ModbusPointConfig(
          address: 3,
          quantity: 5,
        );
        expect(a.overlapsWith(b), isTrue);
      });

      test('非重叠检测 (应通过)', () {
        const a = ModbusPointConfig(
          address: 0,
          quantity: 5,
        );
        const b = ModbusPointConfig(
          address: 6,
          quantity: 1,
        );
        expect(a.overlapsWith(b), isFalse);
      });

      test('紧邻边界不重叠', () {
        const a = ModbusPointConfig(
          address: 0,
          quantity: 5,
        );
        const b = ModbusPointConfig(
          address: 5,
          quantity: 1,
        );
        // a: [0,4], b: [5,5] - no overlap
        expect(a.overlapsWith(b), isFalse);
      });

      test('float32 重叠检测', () {
        const a = ModbusPointConfig(
          address: 0,
          quantity: 3,
          dataType: ModbusDataType.float32,
        ); // registers [0, 5]
        const b = ModbusPointConfig(
          address: 3,
          quantity: 1,
        ); // registers [3, 3]
        expect(a.overlapsWith(b), isTrue);
      });
    });

    test('equality comparison', () {
      const a = ModbusPointConfig(address: 0, quantity: 1);
      const b = ModbusPointConfig(address: 0, quantity: 1);
      expect(a, equals(b));
    });

    test('hashCode consistency', () {
      const a = ModbusPointConfig(address: 0, quantity: 1);
      const b = ModbusPointConfig(address: 0, quantity: 1);
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('PointConfigFormState', () {
    test('initial creates correct defaults', () {
      final state = PointConfigFormState.initial();
      expect(state.functionCode, ModbusFunctionCode.fc03);
      expect(state.address, '');
      expect(state.quantity, '');
      expect(state.dataType, ModbusDataType.uint16);
      expect(state.scale, '1.0');
      expect(state.offset, '0.0');
      expect(state.isValid, isTrue);
    });

    test('fromConfig pre-fills all fields', () {
      const config = ModbusPointConfig(
        functionCode: ModbusFunctionCode.fc01,
        address: 42,
        quantity: 3,
        dataType: ModbusDataType.bool_,
        scale: 2.0,
        offset: -1.0,
      );
      final state = PointConfigFormState.fromConfig(config);
      expect(state.functionCode, ModbusFunctionCode.fc01);
      expect(state.address, '42');
      expect(state.quantity, '3');
      expect(state.dataType, ModbusDataType.bool_);
      expect(state.scale, '2.0');
      expect(state.offset, '-1.0');
    });

    test('tryCreateConfig succeeds with valid data', () {
      const state = PointConfigFormState(
        address: '100',
        quantity: '5',
      );
      final config = state.tryCreateConfig();
      expect(config, isNotNull);
      expect(config!.address, 100);
      expect(config.quantity, 5);
    });

    test('tryCreateConfig returns null with invalid data', () {
      const state = PointConfigFormState(
        address: 'abc',
        quantity: '5',
      );
      expect(state.tryCreateConfig(), isNull);
    });

    test('isValid returns false when errors present', () {
      const state = PointConfigFormState(
        addressError: 'Error',
      );
      expect(state.isValid, isFalse);
    });

    test('copyWith with clear errors works', () {
      const state = PointConfigFormState(
        addressError: 'Error',
        quantityError: 'Error',
      );
      final cleared = state.copyWith(
        clearAddressError: true,
        clearQuantityError: true,
      );
      expect(cleared.addressError, isNull);
      expect(cleared.quantityError, isNull);
    });
  });
}
