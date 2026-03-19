/// 验证器单元测试

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/validators/validators.dart';

void main() {
  group('Validators', () {
    group('validateEmail', () {
      test('空邮箱返回错误消息', () {
        expect(Validators.validateEmail(null), equals('邮箱不能为空'));
        expect(Validators.validateEmail(''), equals('邮箱不能为空'));
      });

      test('无效邮箱格式返回错误消息', () {
        expect(Validators.validateEmail('test'), equals('邮箱格式无效'));
        expect(Validators.validateEmail('test@'), equals('邮箱格式无效'));
        expect(Validators.validateEmail('@test.com'), equals('邮箱格式无效'));
        expect(Validators.validateEmail('test@test'), equals('邮箱格式无效'));
      });

      test('有效邮箱返回null', () {
        expect(Validators.validateEmail('test@example.com'), isNull);
        expect(Validators.validateEmail('user.name@domain.co.uk'), isNull);
        expect(Validators.validateEmail('user+tag@gmail.com'), isNull);
      });

      test('required为false时空邮箱返回null', () {
        expect(Validators.validateEmail(null, required: false), isNull);
        expect(Validators.validateEmail('', required: false), isNull);
      });
    });

    group('validatePassword', () {
      test('空密码返回错误消息', () {
        expect(Validators.validatePassword(null), equals('密码不能为空'));
        expect(Validators.validatePassword(''), equals('密码不能为空'));
      });

      test('密码少于6个字符返回错误消息', () {
        expect(Validators.validatePassword('12345'), equals('密码至少6个字符'));
        expect(Validators.validatePassword('abc'), equals('密码至少6个字符'));
      });

      test('有效密码返回null', () {
        expect(Validators.validatePassword('123456'), isNull);
        expect(Validators.validatePassword('password123'), isNull);
        expect(Validators.validatePassword('abcdefgh'), isNull);
      });

      test('required为false时空密码返回null', () {
        expect(Validators.validatePassword(null, required: false), isNull);
        expect(Validators.validatePassword('', required: false), isNull);
      });
    });
  });
}
