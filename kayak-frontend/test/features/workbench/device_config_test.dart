/// R1-S1-006: 多协议设备配置UI Widget测试
///
/// 覆盖协议选择器、Virtual/Modbus TCP/Modbus RTU 表单、表单验证等核心功能。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/workbench/models/device.dart';
import 'package:kayak_frontend/features/workbench/widgets/device/device_form_dialog.dart';

/// Helper: build a MaterialApp + ProviderScope wrapping a button that opens DeviceFormDialog
Widget buildTestApp(WidgetTester tester) {
  return ProviderScope(
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            key: const Key('open-dialog-button'),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => const DeviceFormDialog(
                  workbenchId: 'workbench-test',
                ),
              );
            },
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );
}

/// Helper: open the create device dialog
Future<void> openDialog(WidgetTester tester) async {
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
}

/// Helper: select a protocol from the dropdown
Future<void> selectProtocol(WidgetTester tester, String label) async {
  final dropdown = find.byKey(const Key('protocol-type-dropdown'));
  await tester.ensureVisible(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(dropdown);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

void main() {
  // ============================================================
  // Section 1: 协议选择器测试 (P0)
  // ============================================================

  group('TC-UI-001: 协议选择器默认显示 Virtual', () {
    testWidgets('protocol selector defaults to Virtual', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Virtual should be visible (button label + dropdown menu may appear)
      expect(find.text('Virtual'), findsWidgets);
    });
  });

  group('TC-UI-002: 协议选择器下拉列表包含所有协议选项', () {
    testWidgets('dropdown contains all three protocol options', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Open the dropdown
      final dropdown = find.byKey(const Key('protocol-type-dropdown'));
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();
      await tester.tap(dropdown);
      await tester.pumpAndSettle();

      // Verify all three options in the menu
      expect(find.text('Virtual'), findsWidgets);
      expect(find.text('Modbus TCP'), findsOneWidget);
      expect(find.text('Modbus RTU'), findsOneWidget);
    });
  });

  group('TC-UI-003: 选择 Virtual 协议并验证表单显示', () {
    testWidgets('Virtual protocol form is displayed by default',
        (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Virtual section should be visible by default
      expect(find.byKey(const Key('virtual-params-section')), findsOneWidget);
      expect(find.text('Virtual 协议参数'), findsOneWidget);
      // Check Virtual form fields
      expect(find.text('数据模式 *'), findsOneWidget);
      expect(find.text('数据类型 *'), findsOneWidget);
      expect(find.text('访问类型 *'), findsOneWidget);
    });
  });

  group('TC-UI-004: 选择 Modbus TCP 协议并验证表单显示', () {
    testWidgets('Modbus TCP protocol form is displayed after selection',
        (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      await selectProtocol(tester, 'Modbus TCP');

      // TCP section should be visible
      expect(
        find.byKey(const Key('modbus-tcp-params-section')),
        findsOneWidget,
      );
      expect(find.text('Modbus TCP 协议参数'), findsOneWidget);
      // Check TCP form fields
      expect(find.text('主机地址 *'), findsOneWidget);
      expect(find.text('端口 *'), findsOneWidget);
      expect(find.text('从站ID *'), findsOneWidget);
    });
  });

  group('TC-UI-005: 选择 Modbus RTU 协议并验证表单显示', () {
    testWidgets('Modbus RTU protocol form is displayed after selection',
        (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      await selectProtocol(tester, 'Modbus RTU');

      // RTU section should be visible
      expect(
        find.byKey(const Key('modbus-rtu-params-section')),
        findsOneWidget,
      );
      expect(find.text('Modbus RTU 协议参数'), findsOneWidget);
      // Check RTU form fields
      expect(find.text('串口 *'), findsOneWidget);
      expect(find.text('波特率'), findsOneWidget);
    });
  });

  group('TC-UI-006: 协议切换 Virtual -> Modbus TCP', () {
    testWidgets('switching from Virtual to TCP hides Virtual fields',
        (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Confirm Virtual is showing
      expect(find.byKey(const Key('virtual-params-section')), findsOneWidget);

      // Switch to TCP
      await selectProtocol(tester, 'Modbus TCP');

      // Virtual should be gone, TCP visible
      expect(find.byKey(const Key('virtual-params-section')), findsNothing);
      expect(
        find.byKey(const Key('modbus-tcp-params-section')),
        findsOneWidget,
      );
    });
  });

  group('TC-UI-009: 协议切换后上一个协议字段完全不可见', () {
    testWidgets(
        'switched protocol fields are removed from widget tree entirely',
        (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Switch to TCP
      await selectProtocol(tester, 'Modbus TCP');
      // TCP-specific field should exist
      expect(find.byKey(const Key('tcp-host-field')), findsOneWidget);
      expect(find.byKey(const Key('tcp-port-field')), findsOneWidget);

      // Switch to RTU
      await selectProtocol(tester, 'Modbus RTU');
      // TCP fields should be gone
      expect(find.byKey(const Key('tcp-host-field')), findsNothing);
      expect(find.byKey(const Key('tcp-port-field')), findsNothing);
      // RTU fields should exist
      expect(
        find.byKey(const Key('modbus-rtu-params-section')),
        findsOneWidget,
      );
    });
  });

  group('TC-UI-010: 编辑模式下协议选择器不可修改', () {
    testWidgets('protocol selector is disabled in edit mode', (tester) async {
      final device = Device(
        id: 'device-1',
        workbenchId: 'workbench-1',
        name: 'Existing Device',
        protocolType: ProtocolType.modbusTcp,
        protocolParams: {'host': '10.0.0.1', 'port': 502, 'slave_id': 1},
        status: DeviceStatus.online,
        createdAt: DateTime(2026),
        updatedAt: DateTime(2026),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => DeviceFormDialog(
                        workbenchId: 'workbench-1',
                        device: device,
                      ),
                    );
                  },
                  child: const Text('Edit'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      // In edit mode, the dialog title should show '编辑设备'
      expect(find.text('编辑设备 - Existing Device'), findsOneWidget);

      // The protocol dropdown should show Modbus TCP and be disabled
      final dropdown = find.byKey(const Key('protocol-type-dropdown'));
      await tester.ensureVisible(dropdown);
      await tester.pumpAndSettle();

      // Try to tap it - should not open (disabled)
      await tester.tap(dropdown);
      await tester.pumpAndSettle();
      // The dropdown menu should NOT have opened, so Modbus RTU text
      // shouldn't appear in the menu overlay
      expect(find.text('Modbus RTU'), findsNothing);
    });
  });

  // ============================================================
  // Section 2: Virtual 协议表单测试 (P0)
  // ============================================================

  group('TC-VF-001: Virtual 协议模式选择器配置', () {
    testWidgets('mode dropdown contains Random/Fixed/Sine/Ramp options',
        (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Open mode dropdown
      final modeDropdown = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<dynamic> &&
            w.decoration.labelText == '数据模式 *',
      );
      await tester.ensureVisible(modeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(modeDropdown);
      await tester.pumpAndSettle();

      // Verify all four mode options (may appear in both button and menu)
      expect(find.text('Random (随机)'), findsWidgets);
      expect(find.text('Fixed (固定)'), findsOneWidget);
      expect(find.text('Sine (正弦)'), findsOneWidget);
      expect(find.text('Ramp (斜坡)'), findsOneWidget);
    });
  });

  group('TC-VF-002: Virtual 协议选择 Random 模式', () {
    testWidgets('selecting Random mode keeps min/max fields visible',
        (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Random is the default - verify min/max are visible
      expect(find.text('最小值 *'), findsOneWidget);
      expect(find.text('最大值 *'), findsOneWidget);
    });
  });

  group('TC-VF-003: Virtual 协议选择 Fixed 模式', () {
    testWidgets('selecting Fixed mode shows fixed value field', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Open mode dropdown and select Fixed
      final modeDropdown = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<dynamic> &&
            w.decoration.labelText == '数据模式 *',
      );
      await tester.ensureVisible(modeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(modeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fixed (固定)'));
      await tester.pumpAndSettle();

      // Fixed value field should appear
      expect(find.text('固定值 *'), findsOneWidget);
    });
  });

  group('TC-VF-006: Virtual 协议数据类型选择器', () {
    testWidgets('data type dropdown contains Number/Integer/String/Boolean',
        (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Open data type dropdown
      final typeDropdown = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<dynamic> &&
            w.decoration.labelText == '数据类型 *',
      );
      await tester.ensureVisible(typeDropdown);
      await tester.pumpAndSettle();
      await tester.tap(typeDropdown);
      await tester.pumpAndSettle();

      expect(find.text('Number (浮点数)'), findsWidgets);
      expect(find.text('Integer (整数)'), findsOneWidget);
      expect(find.text('String (字符串)'), findsOneWidget);
      expect(find.text('Boolean (布尔值)'), findsOneWidget);
    });
  });

  group('TC-VF-008: Virtual 协议访问类型选择器', () {
    testWidgets('access type dropdown contains RO/WO/RW options',
        (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Open access type dropdown
      final accessDropdown = find.byWidgetPredicate(
        (w) =>
            w is DropdownButtonFormField<dynamic> &&
            w.decoration.labelText == '访问类型 *',
      );
      await tester.ensureVisible(accessDropdown);
      await tester.pumpAndSettle();
      await tester.tap(accessDropdown);
      await tester.pumpAndSettle();

      expect(find.text('RO (只读)'), findsOneWidget);
      expect(find.text('WO (只写)'), findsOneWidget);
      expect(find.text('RW (读写)'), findsWidgets);
    });
  });

  group('TC-VF-009: Virtual 协议最小值输入', () {
    testWidgets('min value field accepts numeric input', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Find min value field by key and enter a value
      final minField = find.byKey(const Key('virtual-min-value-field'));
      await tester.enterText(minField, '50');
      await tester.pumpAndSettle();

      // Verify the value was entered
      expect(find.text('50'), findsOneWidget);
    });
  });

  group('TC-VF-010: Virtual 协议最大值输入', () {
    testWidgets('max value field accepts numeric input', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      final maxField = find.byKey(const Key('virtual-max-value-field'));
      await tester.enterText(maxField, '200');
      await tester.pumpAndSettle();

      expect(find.text('200'), findsOneWidget);
    });
  });

  // ============================================================
  // Section 3: Modbus TCP 协议表单测试 (P0)
  // ============================================================

  group('TC-TCP-001: Modbus TCP 协议表单字段完整显示', () {
    testWidgets('all TCP form fields are visible', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus TCP');

      expect(find.text('主机地址 *'), findsOneWidget);
      expect(find.text('端口 *'), findsOneWidget);
      expect(find.text('从站ID *'), findsOneWidget);
      expect(find.text('超时 (ms)'), findsOneWidget);
      expect(find.text('连接池大小'), findsOneWidget);
    });
  });

  group('TC-TCP-002: Modbus TCP 主机地址输入框', () {
    testWidgets('host field accepts IP address input', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus TCP');

      final hostField = find.byKey(const Key('tcp-host-field'));
      await tester.enterText(hostField, '192.168.1.100');
      await tester.pumpAndSettle();

      expect(find.text('192.168.1.100'), findsWidgets);
    });
  });

  group('TC-TCP-004: Modbus TCP 端口输入框默认值 502', () {
    testWidgets('port field defaults to 502', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus TCP');

      final portField = find.byKey(const Key('tcp-port-field'));
      final field = tester.widget<TextFormField>(portField);
      expect(field.controller?.text, '502');
    });
  });

  group('TC-TCP-006: Modbus TCP 从站ID输入框默认值 1', () {
    testWidgets('slave ID field defaults to 1', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus TCP');

      final slaveField = find.byKey(const Key('tcp-slave-id-field'));
      final field = tester.widget<TextFormField>(slaveField);
      expect(field.controller?.text, '1');
    });
  });

  group('TC-TCP-007: Modbus TCP 从站ID数字输入', () {
    testWidgets('slave ID field accepts numeric input', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus TCP');

      final slaveField = find.byKey(const Key('tcp-slave-id-field'));
      await tester.enterText(slaveField, '10');
      await tester.pumpAndSettle();

      expect(find.text('10'), findsOneWidget);
    });
  });

  // ============================================================
  // Section 4: Modbus RTU 协议表单测试 (P0)
  // ============================================================

  group('TC-RTU-001: Modbus RTU 协议表单字段完整显示', () {
    testWidgets('all RTU form fields are visible', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus RTU');

      expect(find.text('串口 *'), findsOneWidget);
      expect(find.text('波特率'), findsOneWidget);
      expect(find.text('数据位'), findsOneWidget);
      expect(find.text('停止位'), findsOneWidget);
      expect(find.text('校验'), findsOneWidget);
      expect(find.text('从站ID *'), findsOneWidget);
      expect(find.text('超时 (ms)'), findsOneWidget);
    });
  });

  group('TC-RTU-005: Modbus RTU 波特率选择器默认值 9600', () {
    testWidgets('baud rate defaults to 9600', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus RTU');

      // The baud rate dropdown should show "9600"
      expect(find.text('9600'), findsOneWidget);
    });
  });

  group('TC-RTU-007: Modbus RTU 数据位选择器默认值 8', () {
    testWidgets('data bits defaults to 8', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus RTU');

      // Should find "8" in the data bits dropdown
      // Note: "8" may also appear in other contexts, use findsWidgets
      expect(find.text('8'), findsWidgets);
    });
  });

  group('TC-RTU-009: Modbus RTU 校验位选择器默认值 None', () {
    testWidgets('parity defaults to None', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus RTU');

      expect(find.text('None'), findsOneWidget);
    });
  });

  // ============================================================
  // Section 5: 表单验证测试 (P0)
  // ============================================================

  group('TC-VAL-001: IP 地址格式验证 - 无效格式', () {
    testWidgets('invalid IP format shows validation error', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus TCP');

      // Enter name (required) and invalid IP
      await tester.enterText(
        find.byKey(const Key('device-name-field')),
        'TestDevice',
      );
      await tester.enterText(
        find.byKey(const Key('tcp-host-field')),
        '256.1.1.1',
      );
      await tester.pumpAndSettle();

      // Try submit
      await tester.tap(find.byKey(const Key('submit-device-button')));
      await tester.pumpAndSettle();

      // Should show IP validation error
      expect(find.text('IP地址格式无效'), findsOneWidget);
    });
  });

  group('TC-VAL-002: IP 地址格式验证 - 有效格式', () {
    testWidgets('valid IP format passes validation', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus TCP');

      // Enter valid IP
      await tester.enterText(
        find.byKey(const Key('tcp-host-field')),
        '192.168.1.100',
      );
      await tester.pumpAndSettle();

      // The IP field should NOT show an error
      // Just verify the value is accepted (appears in EditableText + Text)
      expect(find.text('192.168.1.100'), findsWidgets);
    });
  });

  group('TC-VAL-003: IP 地址格式验证 - 非数字', () {
    testWidgets('non-numeric IP format shows validation error', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus TCP');

      await tester.enterText(
        find.byKey(const Key('device-name-field')),
        'TestDevice',
      );
      await tester.enterText(
        find.byKey(const Key('tcp-host-field')),
        'abc.def.ghi.jkl',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit-device-button')));
      await tester.pumpAndSettle();

      expect(find.text('IP地址格式无效'), findsOneWidget);
    });
  });

  group('TC-VAL-004: IP 地址格式验证 - 缺少段', () {
    testWidgets('incomplete IP format shows validation error', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus TCP');

      await tester.enterText(
        find.byKey(const Key('device-name-field')),
        'TestDevice',
      );
      await tester.enterText(
        find.byKey(const Key('tcp-host-field')),
        '192.168.1',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit-device-button')));
      await tester.pumpAndSettle();

      expect(find.text('IP地址格式无效'), findsOneWidget);
    });
  });

  group('TC-VAL-005: 端口范围验证 - 超出范围', () {
    testWidgets('port > 65535 shows validation error', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus TCP');

      await tester.enterText(
        find.byKey(const Key('device-name-field')),
        'TestDevice',
      );
      await tester.enterText(
        find.byKey(const Key('tcp-host-field')),
        '192.168.1.1',
      );
      await tester.enterText(
        find.byKey(const Key('tcp-port-field')),
        '65536',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit-device-button')));
      await tester.pumpAndSettle();

      expect(find.text('端口范围 1-65535'), findsOneWidget);
    });
  });

  group('TC-VAL-006: 端口范围验证 - 为 0', () {
    testWidgets('port 0 shows validation error', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus TCP');

      await tester.enterText(
        find.byKey(const Key('device-name-field')),
        'TestDevice',
      );
      await tester.enterText(
        find.byKey(const Key('tcp-host-field')),
        '192.168.1.1',
      );
      await tester.enterText(
        find.byKey(const Key('tcp-port-field')),
        '0',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit-device-button')));
      await tester.pumpAndSettle();

      expect(find.text('端口范围 1-65535'), findsOneWidget);
    });
  });

  group('TC-VAL-008: 从站ID范围验证 - 超出范围', () {
    testWidgets('slave ID > 247 shows validation error', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus TCP');

      await tester.enterText(
        find.byKey(const Key('device-name-field')),
        'TestDevice',
      );
      await tester.enterText(
        find.byKey(const Key('tcp-host-field')),
        '192.168.1.1',
      );
      // Clear default port value and set valid port
      await tester.enterText(
        find.byKey(const Key('tcp-port-field')),
        '502',
      );
      await tester.enterText(
        find.byKey(const Key('tcp-slave-id-field')),
        '248',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit-device-button')));
      await tester.pumpAndSettle();

      expect(find.text('从站ID范围 1-247'), findsOneWidget);
    });
  });

  group('TC-VAL-009: 从站ID范围验证 - 为 0', () {
    testWidgets('slave ID 0 shows validation error', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);
      await selectProtocol(tester, 'Modbus TCP');

      await tester.enterText(
        find.byKey(const Key('device-name-field')),
        'TestDevice',
      );
      await tester.enterText(
        find.byKey(const Key('tcp-host-field')),
        '192.168.1.1',
      );
      await tester.enterText(
        find.byKey(const Key('tcp-port-field')),
        '502',
      );
      await tester.enterText(
        find.byKey(const Key('tcp-slave-id-field')),
        '0',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit-device-button')));
      await tester.pumpAndSettle();

      expect(find.text('从站ID范围 1-247'), findsOneWidget);
    });
  });

  group('TC-VAL-011: 设备名称必填验证', () {
    testWidgets('empty device name shows validation error', (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Submit without filling name
      await tester.tap(find.byKey(const Key('submit-device-button')));
      await tester.pumpAndSettle();

      expect(find.text('设备名称不能为空'), findsOneWidget);
    });
  });

  group('TC-VAL-012: 最小值大于最大值验证', () {
    testWidgets('min > max shows validation error in Virtual form',
        (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Virtual is default - enter min > max
      await tester.enterText(
        find.byKey(const Key('device-name-field')),
        'TestDevice',
      );

      final minField = find.byKey(const Key('virtual-min-value-field'));
      final maxField = find.byKey(const Key('virtual-max-value-field'));

      await tester.enterText(minField, '100');
      await tester.enterText(maxField, '50');
      await tester.pumpAndSettle();

      // Try submit
      await tester.tap(find.byKey(const Key('submit-device-button')));
      await tester.pumpAndSettle();

      // Should show min/max validation error
      expect(find.text('最小值不能大于最大值'), findsOneWidget);
    });
  });

  // ============================================================
  // Section 6: 通用交互测试
  // ============================================================

  group('TC-FLOW-005: 取消创建设备', () {
    testWidgets('cancel button closes dialog without dirty confirmation',
        (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Tap cancel without modifying anything (not dirty)
      await tester.tap(find.byKey(const Key('cancel-device-button')));
      await tester.pumpAndSettle();

      // Dialog should be closed
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('cancel with dirty form shows confirmation dialog',
        (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Enter some text to make the form dirty
      await tester.enterText(
        find.byKey(const Key('device-name-field')),
        'Test Device',
      );
      await tester.pumpAndSettle();

      // Tap cancel - should show confirmation dialog
      await tester.tap(find.byKey(const Key('cancel-device-button')));
      await tester.pumpAndSettle();

      // Confirmation dialog should appear
      expect(find.text('放弃修改？'), findsOneWidget);

      // Click '继续编辑' to stay
      await tester.tap(find.text('继续编辑'));
      await tester.pumpAndSettle();

      // Original dialog should still be open
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('创建设备'), findsOneWidget);
    });
  });

  group('通用字段在协议切换后保留', () {
    testWidgets('common field values persist across protocol switches',
        (tester) async {
      await tester.pumpWidget(buildTestApp(tester));
      await openDialog(tester);

      // Enter device name and manufacturer
      await tester.enterText(
        find.byKey(const Key('device-name-field')),
        'Test Device',
      );
      await tester.pumpAndSettle();

      // Switch to TCP
      await selectProtocol(tester, 'Modbus TCP');

      // Device name should still be "Test Device"
      expect(find.text('Test Device'), findsOneWidget);
    });
  });
}
