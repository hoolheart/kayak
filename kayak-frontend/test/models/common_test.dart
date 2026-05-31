import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/models/common.dart';

void main() {
  group('ApiResponse', () {
    test('fromJson parses success response', () {
      final json = {
        'code': 200,
        'message': 'success',
        'data': {'id': 'test'},
        'timestamp': '2024-01-01T00:00:00Z',
      };

      final response = ApiResponse<Map<String, dynamic>>.fromJson(
        json,
        (data) => data as Map<String, dynamic>,
      );

      expect(response.code, 200);
      expect(response.message, 'success');
      expect(response.data['id'], 'test');
    });

    test('toJson serializes correctly', () {
      const response = ApiResponse<String>(
        code: 200,
        message: 'success',
        data: 'test',
      );

      final json = response.toJson((data) => data);

      expect(json['code'], 200);
      expect(json['data'], 'test');
    });
  });
}
