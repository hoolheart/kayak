import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kayak_frontend/theme/typography.dart';

void main() {
  group('TC-017: Monospace font configuration', () {
    test('typography defines monospace font family', () {
      const monoStyle = AppTypography.monospace;

      expect(monoStyle.fontFamily, anyOf(
        equals('RobotoMono'),
        equals('FiraCode'),
        equals('monospace'),
        equals('JetBrainsMono'),
      ));
    });

    test('typography monospace has fallback', () {
      const monoStyle = AppTypography.monospace;
      expect(monoStyle.fontFamilyFallback, isNotEmpty);
      expect(monoStyle.fontFamilyFallback, contains('monospace'));
    });

    test('monospace style is const', () {
      const style = AppTypography.monospace;
      expect(style, isA<TextStyle>());
    });
  });

  group('TC-018: Text styles integrated in theme', () {
    test('monospace text style can be used with theme', () {
      // Verify the style is accessible and well-formed
      const monoStyle = AppTypography.monospace;

      expect(monoStyle.fontFamily, isNotNull);
      expect(monoStyle.fontFamilyFallback, isNotNull);
    });
  });
}
