/// 登录状态管理测试

library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/features/auth/providers/login_provider.dart';

void main() {
  group('LoginProvider', () {
    test('初始状态为idle', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(loginProvider);
      expect(state.status, equals(LoginStatus.idle));
      expect(state.errorMessage, isNull);
      expect(state.errorType, isNull);
    });

    test('setLoading转换到loading状态', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loginProvider.notifier).setLoading();
      final state = container.read(loginProvider);
      expect(state.status, equals(LoginStatus.loading));
    });

    test('setSuccess转换到success状态', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(loginProvider.notifier).setSuccess();
      final state = container.read(loginProvider);
      expect(state.status, equals(LoginStatus.success));
    });

    test('setError转换到error状态', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(loginProvider.notifier)
          .setError(LoginErrorType.invalidCredentials);
      final state = container.read(loginProvider);
      expect(state.status, equals(LoginStatus.error));
      expect(state.errorType, equals(LoginErrorType.invalidCredentials));
      expect(state.errorMessage, equals('邮箱或密码错误'));
    });

    test('reset回到idle状态', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(loginProvider.notifier)
          .setError(LoginErrorType.networkError);
      container.read(loginProvider.notifier).reset();
      final state = container.read(loginProvider);
      expect(state.status, equals(LoginStatus.idle));
    });
  });

  group('LoginState', () {
    test('getErrorMessage返回正确的错误消息', () {
      expect(
        LoginState.getErrorMessage(LoginErrorType.invalidCredentials),
        equals('邮箱或密码错误'),
      );
      expect(
        LoginState.getErrorMessage(LoginErrorType.networkError),
        equals('网络错误，请检查网络连接'),
      );
      expect(
        LoginState.getErrorMessage(LoginErrorType.serverError),
        equals('服务器错误，请稍后重试'),
      );
      expect(
        LoginState.getErrorMessage(LoginErrorType.sessionExpired),
        equals('会话已过期，请重新登录'),
      );
      expect(
        LoginState.getErrorMessage(LoginErrorType.unknown),
        equals('发生未知错误，请稍后重试'),
      );
    });

    test('工厂方法创建正确的状态', () {
      expect(LoginState.idle().status, equals(LoginStatus.idle));
      expect(LoginState.loading().status, equals(LoginStatus.loading));
      expect(LoginState.success().status, equals(LoginStatus.success));
      expect(
        LoginState.error(LoginErrorType.networkError).status,
        equals(LoginStatus.error),
      );
    });
  });

  group('LoginStatus', () {
    test('枚举值正确', () {
      expect(LoginStatus.values, contains(LoginStatus.idle));
      expect(LoginStatus.values, contains(LoginStatus.loading));
      expect(LoginStatus.values, contains(LoginStatus.success));
      expect(LoginStatus.values, contains(LoginStatus.error));
    });
  });
}
