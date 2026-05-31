import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Helper to parse an ARB file from the lib/l10n directory.
Map<String, dynamic> _parseArbFile(String fileName) {
  final file = File('lib/l10n/$fileName');
  expect(file.existsSync(), isTrue, reason: '$fileName not found');
  final content = file.readAsStringSync();
  return jsonDecode(content) as Map<String, dynamic>;
}

void main() {
  const allRequiredKeys = <String>{
    // 通用操作
    'save', 'cancel', 'delete', 'confirm', 'create', 'edit', 'search',
    'submit', 'retry', 'loading', 'noData',
    // 认证
    'login', 'register', 'logout', 'email', 'password', 'username',
    // 导航
    'dashboard', 'workbenches', 'methods', 'experiments', 'analysis', 'settings',
    // 列表
    'workbenchList', 'methodList', 'experimentList',
    // 错误
    'loginError', 'networkError', 'sessionExpired',
    // 通用
    'appTitle',
  };

  group('TC-001: app_en.arb file exists and is valid JSON', () {
    test('app_en.arb exists and is valid JSON', () {
      final json = _parseArbFile('app_en.arb');

      expect(json['@@locale'], equals('en'));
      expect(json['appTitle'], isA<String>());
    });

    test('app_en.arb @@locale is en', () {
      final json = _parseArbFile('app_en.arb');
      expect(json['@@locale'], equals('en'));
    });
  });

  group('TC-002: app_zh.arb file exists and is valid JSON', () {
    test('app_zh.arb exists and is valid JSON', () {
      final json = _parseArbFile('app_zh.arb');

      expect(json['@@locale'], equals('zh'));
      expect(json['appTitle'], isA<String>());
    });

    test('app_zh.arb @@locale is zh', () {
      final json = _parseArbFile('app_zh.arb');
      expect(json['@@locale'], equals('zh'));
    });
  });

  group('TC-003: en and zh ARB keys one-to-one correspondence', () {
    test('zh ARB contains all en ARB keys (full coverage)', () {
      final enJson = _parseArbFile('app_en.arb');
      final zhJson = _parseArbFile('app_zh.arb');

      final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();
      final zhKeys = zhJson.keys.where((k) => !k.startsWith('@')).toSet();

      // zh must contain all en keys
      final missingInZh = enKeys.difference(zhKeys);
      expect(missingInZh, isEmpty,
          reason: 'Missing keys in zh: ${missingInZh.toList()}');

      // no extra keys in zh (strict matching)
      final extraInZh = zhKeys.difference(enKeys);
      expect(extraInZh, isEmpty,
          reason: 'Extra keys in zh not present in en: ${extraInZh.toList()}');
    });
  });

  group('TC-023: en ARB contains all required common action keys', () {
    test('app_en.arb contains all required common action keys', () {
      final enJson = _parseArbFile('app_en.arb');

      const requiredKeys = <String>[
        'save', 'cancel', 'delete', 'confirm', 'retry', 'loading', 'noData',
        'networkError', 'create', 'edit', 'search', 'submit',
      ];

      for (final key in requiredKeys) {
        expect(enJson.containsKey(key), isTrue, reason: 'Missing key: $key');
        expect(enJson[key], isA<String>(), reason: 'Key $key is not a String');
        expect((enJson[key] as String).isNotEmpty, isTrue,
            reason: 'Key $key has empty value');
      }
    });
  });

  group('TC-024: en ARB contains all navigation/auth/functional keys', () {
    test('app_en.arb contains all required navigation/auth/functional keys', () {
      final enJson = _parseArbFile('app_en.arb');
      final allKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();

      // 验证所有必需 key
      final missingKeys = allRequiredKeys.difference(allKeys);
      expect(missingKeys, isEmpty,
          reason: 'Missing required keys: ${missingKeys.toList()}, '
              'actual keys: ${allKeys.toList()}');
    });
  });

  group('TC-025: zh ARB translations differ from en (non-proper-noun)', () {
    test('zh ARB translations differ from en for translatable keys', () {
      final enJson = _parseArbFile('app_en.arb');
      final zhJson = _parseArbFile('app_zh.arb');

      // 允许相同的专有名词 key
      const properNounKeys = <String>{'appTitle'};

      final enKeys = enJson.keys.where((k) => !k.startsWith('@')).toSet();
      for (final key in enKeys) {
        expect(zhJson.containsKey(key), isTrue,
            reason: 'Key "$key" missing in zh ARB');

        final enValue = enJson[key] as String;
        final zhValue = zhJson[key] as String;

        if (properNounKeys.contains(key)) {
          // 专有名词允许相同
          continue;
        }

        // 通用词汇必须翻译
        expect(zhValue, isNot(equals(enValue)),
            reason: 'Key "$key" has identical value in en and zh: "$enValue". '
                'It should be translated.');
        expect(zhValue.isNotEmpty, isTrue,
            reason: 'Key "$key" has empty Chinese translation.');
      }
    });
  });

  group('TC-026: ARB metadata keys correctly reference translation keys', () {
    test('ARB metadata keys correctly reference translation keys', () {
      final enJson = _parseArbFile('app_en.arb');

      final allKeys = enJson.keys.toSet();
      final metaKeys = allKeys
          .where((k) => k.startsWith('@') && k != '@@locale');
      final translationKeys = allKeys.where((k) => !k.startsWith('@'));

      for (final metaKey in metaKeys) {
        // 每个 @xxx 应该对应一个存在的翻译 key xxx
        final translationKey = metaKey.substring(1); // 去掉 @ 前缀
        expect(translationKeys.contains(translationKey), isTrue,
            reason:
                'Metadata "$metaKey" has no corresponding translation key "$translationKey"');
      }
    });
  });
}
