import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/mcp_service.dart';
import '../../lib/models/mcp_server.dart';
import '../../lib/core/result.dart';

McpServer _makeServer(String id, {bool enabled = true}) => McpServer(
      id: id,
      name: 'Test $id',
      command: 'node',
      args: ['server.js'],
      env: {},
      transport: McpTransport.stdio,
      enabled: enabled,
    );

void main() {
  group('McpService CRUD', () {
    late File mcpFile;
    String? _backup;

    setUpAll(() {
      final home =
          Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'] ?? '';
      mcpFile = File('$home/.openclaw/mcp.json');
    });

    setUp(() async {
      if (await mcpFile.exists()) {
        _backup = await mcpFile.readAsString();
        await mcpFile.delete();
      } else {
        _backup = null;
      }
    });

    tearDown(() async {
      if (_backup != null) {
        await mcpFile.parent.create(recursive: true);
        await mcpFile.writeAsString(_backup!);
      } else if (await mcpFile.exists()) {
        await mcpFile.delete();
      }
    });

    test('getAll returns empty list when file missing', () async {
      final result = await McpService.getAll();
      expect(result, isEmpty);
    });

    test('add then getAll returns the server', () async {
      final server = _makeServer('test-mcp');
      await McpService.add(server);
      final all = await McpService.getAll();
      expect(all.any((s) => s.id == 'test-mcp'), isTrue);
    });

    test('add duplicate returns Failure', () async {
      final server = _makeServer('dup');
      await McpService.add(server);
      final result = await McpService.add(server);
      expect(result.isFailure, isTrue);
    });

    test('update overwrites existing server', () async {
      await McpService.add(_makeServer('upd'));
      final updated = _makeServer('upd').copyWith(name: 'Updated Name');
      await McpService.update(updated);
      final all = await McpService.getAll();
      expect(all.firstWhere((s) => s.id == 'upd').name, 'Updated Name');
    });

    test('remove deletes server', () async {
      await McpService.add(_makeServer('del'));
      await McpService.remove('del');
      final all = await McpService.getAll();
      expect(all.any((s) => s.id == 'del'), isFalse);
    });

    test('toggle sets enabled state', () async {
      await McpService.add(_makeServer('tog', enabled: true));
      await McpService.toggle('tog', false);
      final all = await McpService.getAll();
      expect(all.firstWhere((s) => s.id == 'tog').enabled, isFalse);
    });

    test('toggle nonexistent returns Failure', () async {
      final result = await McpService.toggle('ghost', true);
      expect(result.isFailure, isTrue);
    });

    test('enabledCount counts enabled servers', () async {
      await McpService.add(_makeServer('e1', enabled: true));
      await McpService.add(_makeServer('e2', enabled: false));
      final count = await McpService.enabledCount();
      expect(count, 1);
    });
  });
}
