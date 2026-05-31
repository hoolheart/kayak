import 'package:flutter_test/flutter_test.dart';
import 'package:kayak_frontend/models/workbench.dart';

void main() {
  group('Workbench Model', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'wb-1',
        'name': 'Test Workbench',
        'description': 'Test Description',
        'owner_type': 'personal',
        'owner_id': 'user-1',
        'status': 'active',
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      final workbench = Workbench.fromJson(json);

      expect(workbench.id, 'wb-1');
      expect(workbench.name, 'Test Workbench');
      expect(workbench.ownerType, 'personal');
    });

    test('CreateWorkbenchRequest serializes correctly', () {
      const request = CreateWorkbenchRequest(
        name: 'New Workbench',
        description: 'Description',
        ownerType: 'personal',
        ownerId: 'user-1',
      );

      final json = request.toJson();

      expect(json['name'], 'New Workbench');
      expect(json['owner_id'], 'user-1');
    });
  });
}
