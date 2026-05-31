import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/services/token_storage.dart';
import 'package:mocktail/mocktail.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  group('TokenStorage', () {
    test('save and read tokens', () async {
      final mockStorage = MockFlutterSecureStorage();

      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) => Future<void>.value());

      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((invocation) async {
        if (invocation.namedArguments[const Symbol('key')] == 'access_token') {
          return 'access123';
        }
        if (invocation.namedArguments[const Symbol('key')] == 'refresh_token') {
          return 'refresh456';
        }
        return null;
      });

      final storage = TokenStorage(storage: mockStorage);

      await storage.saveTokens(accessToken: 'access123', refreshToken: 'refresh456');

      final accessToken = await storage.getAccessToken();
      final refreshToken = await storage.getRefreshToken();

      expect(accessToken, 'access123');
      expect(refreshToken, 'refresh456');
    });

    test('clear tokens', () async {
      final mockStorage = MockFlutterSecureStorage();

      when(() => mockStorage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((_) => Future<void>.value());

      // ignore: unnecessary_lambdas
      when(() => mockStorage.deleteAll()).thenAnswer((_) => Future<void>.value());

      final storage = TokenStorage(storage: mockStorage);

      await storage.saveTokens(accessToken: 'access123', refreshToken: 'refresh456');
      await storage.clearTokens();

      // Verify that deleteAll was called
      verify(mockStorage.deleteAll).called(1);
    });
  });
}
