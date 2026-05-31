// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/models/user.dart';

void main() {
  group('User Model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'test-id',
        'email': 'test@example.com',
        'username': 'testuser',
        'avatar_url': 'https://example.com/avatar.png',
        'status': 'active',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final user = User.fromJson(json);

      expect(user.id, 'test-id');
      expect(user.email, 'test@example.com');
      expect(user.username, 'testuser');
      expect(user.avatarUrl, 'https://example.com/avatar.png');
      expect(user.status, 'active');
    });

    test('fromJson parses minimal JSON', () {
      final json = {
        'id': 'u1',
        'email': 'test@kayak.local',
        'status': 'active',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };
      final user = User.fromJson(json);
      expect(user.id, 'u1');
      expect(user.email, 'test@kayak.local');
    });

    test('toJson serializes correctly', () {
      final user = User(
        id: 'test-id',
        email: 'test@example.com',
        username: 'testuser',
        status: 'active',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );

      final json = user.toJson();

      expect(json['id'], 'test-id');
      expect(json['email'], 'test@example.com');
    });

    test('copyWith works', () {
      final user = User(
        id: 'u1',
        email: 'test@kayak.local',
        username: 'Old',
        status: 'active',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: DateTime(2024, 1, 1),
      );
      final updated = user.copyWith(username: 'NewName');
      expect(updated.username, 'NewName');
      expect(user.username, 'Old');
    });
  });
}
