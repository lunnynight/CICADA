import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/mcp_service.dart';
import '../../lib/models/mcp_server.dart';
import '../../lib/core/result.dart';

McpServer _makeServer(String id, {bool enabled = true, String? description, String? source}) => McpServer(
      id: id,
      name: 'Test $id',
      command: 'node',
      args: ['server.js'],
      env: {},
      transport: McpTransport.stdio,
      enabled: enabled,
      description: description,
      source: source,
    );

void main() {
  late Directory tempDir;
  late String mcpConfigPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mcp_service_test_');
    mcpConfigPath = '${tempDir.path}/mcp.json';
    McpService.overrideMcpConfigPathForTest(mcpConfigPath);
  });

  tearDown(() async {
    McpService.overrideMcpConfigPathForTest(null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('McpService.getAll', () {
    test('returns empty list when file missing', () async {
      final result = await McpService.getAll();
      expect(result, isEmpty);
    });

    test('returns empty list when file is empty', () async {
      await File(mcpConfigPath).writeAsString('');
      final result = await McpService.getAll();
      expect(result, isEmpty);
    });

    test('returns empty list when mcpServers key missing', () async {
      await File(mcpConfigPath).writeAsString('{"other":"data"}');
      final result = await McpService.getAll();
      expect(result, isEmpty);
    });

    test('returns empty list on malformed JSON', () async {
      await File(mcpConfigPath).writeAsString('{bad json}');
      final result = await McpService.getAll();
      expect(result, isEmpty);
    });

    test('returns servers from config', () async {
      final data = {
        'mcpServers': {
          'my-server': {
            'command': 'node',
            'args': ['index.js'],
            'env': {},
            'enabled': true,
            'transport': 'stdio',
            'name': 'My Server',
          }
        }
      };
      await File(mcpConfigPath).writeAsString(jsonEncode(data));
      final servers = await McpService.getAll();
      expect(servers.length, equals(1));
      expect(servers.first.id, equals('my-server'));
      expect(servers.first.name, equals('My Server'));
    });
  });

  group('McpService.add', () {
    test('adds a server to empty config', () async {
      final result = await McpService.add(_makeServer('test-mcp'));
      expect(result.isSuccess, isTrue);
      final all = await McpService.getAll();
      expect(all.any((s) => s.id == 'test-mcp'), isTrue);
    });

    test('add duplicate returns Failure', () async {
      await McpService.add(_makeServer('dup'));
      final result = await McpService.add(_makeServer('dup'));
      expect(result.isFailure, isTrue);
    });

    test('adds multiple servers', () async {
      await McpService.add(_makeServer('s1'));
      await McpService.add(_makeServer('s2'));
      final all = await McpService.getAll();
      expect(all.length, equals(2));
    });

    test('persists description and source', () async {
      await McpService.add(_makeServer('rich', description: 'A desc', source: 'manual'));
      final content = await File(mcpConfigPath).readAsString();
      final data = jsonDecode(content) as Map<String, dynamic>;
      final serverData = (data['mcpServers'] as Map)['rich'] as Map;
      expect(serverData['description'], equals('A desc'));
      expect(serverData['source'], equals('manual'));
    });
  });

  group('McpService.update', () {
    test('update overwrites existing server', () async {
      await McpService.add(_makeServer('upd'));
      final updated = _makeServer('upd').copyWith(name: 'Updated Name');
      final result = await McpService.update(updated);
      expect(result.isSuccess, isTrue);
      final all = await McpService.getAll();
      expect(all.firstWhere((s) => s.id == 'upd').name, equals('Updated Name'));
    });

    test('update creates entry if not exists', () async {
      final result = await McpService.update(_makeServer('new-one'));
      expect(result.isSuccess, isTrue);
      final all = await McpService.getAll();
      expect(all.any((s) => s.id == 'new-one'), isTrue);
    });
  });

  group('McpService.remove', () {
    test('remove deletes server', () async {
      await McpService.add(_makeServer('del'));
      final result = await McpService.remove('del');
      expect(result.isSuccess, isTrue);
      final all = await McpService.getAll();
      expect(all.any((s) => s.id == 'del'), isFalse);
    });

    test('remove nonexistent succeeds', () async {
      final result = await McpService.remove('ghost');
      expect(result.isSuccess, isTrue);
    });
  });

  group('McpService.toggle', () {
    test('toggle sets enabled state to false', () async {
      await McpService.add(_makeServer('tog', enabled: true));
      final result = await McpService.toggle('tog', false);
      expect(result.isSuccess, isTrue);
      final all = await McpService.getAll();
      expect(all.firstWhere((s) => s.id == 'tog').enabled, isFalse);
    });

    test('toggle sets enabled state to true', () async {
      await McpService.add(_makeServer('tog2', enabled: false));
      await McpService.toggle('tog2', true);
      final all = await McpService.getAll();
      expect(all.firstWhere((s) => s.id == 'tog2').enabled, isTrue);
    });

    test('toggle nonexistent returns Failure', () async {
      final result = await McpService.toggle('ghost', true);
      expect(result.isFailure, isTrue);
    });
  });

  group('McpService.enabledCount', () {
    test('returns 0 when no servers', () async {
      final count = await McpService.enabledCount();
      expect(count, equals(0));
    });

    test('counts only enabled servers', () async {
      await McpService.add(_makeServer('e1', enabled: true));
      await McpService.add(_makeServer('e2', enabled: false));
      await McpService.add(_makeServer('e3', enabled: true));
      final count = await McpService.enabledCount();
      expect(count, equals(2));
    });
  });
}
