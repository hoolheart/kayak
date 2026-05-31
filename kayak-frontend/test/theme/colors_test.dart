import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kayak_frontend/theme/colors.dart';

void main() {
  group('TC-015: Color constants are correctly defined', () {
    test('AppColors defines valid const Color values', () {
      expect(AppColors.primary, equals(const Color(0xFF1976D2)));
    });

    test('infoBlue is defined', () {
      expect(AppColors.infoBlue, equals(const Color(0xFF2196F3)));
    });

    test('successGreen is defined', () {
      expect(AppColors.successGreen, equals(const Color(0xFF4CAF50)));
    });

    test('warningOrange is defined', () {
      expect(AppColors.warningOrange, equals(const Color(0xFFFF9800)));
    });

    test('errorRed is defined', () {
      expect(AppColors.errorRed, equals(const Color(0xFFE53935)));
    });
  });

  group('TC-016: Color constants do not conflict with ColorScheme', () {
    test('custom colors serve specific purposes beyond ColorScheme', () {
      // These custom colors are for specific status indicators
      // not available in the standard ColorScheme
      expect(AppColors.successGreen, isNot(equals(AppColors.primary)));
      expect(AppColors.warningOrange, isNot(equals(AppColors.primary)));
      expect(AppColors.errorRed, isNot(equals(AppColors.primary)));
      expect(AppColors.infoBlue, isNot(equals(AppColors.primary)));
    });
  });
}
