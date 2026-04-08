import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/models/mcp_server.dart';

void main() {
  group('McpTransport', () {
    test('enum has stdio and sse values', () {
      expect(McpTransport.values, containsAll([McpTransport.stdio, McpTransport.sse]));
    });
  });

  group('McpServer.fromJson', () {
    test('parses all fields from JSON', () {
      final json = {
        'id': 'server-1',
        'name': 'Test Server',
        'command': 'npx',
        'args': ['-y', 'some-mcp'],
        'env': {'API_KEY': 'abc123'},
        'enabled': true,
        'transport': 'stdio',
        'description': 'A test server',
        'source': 'manual',
        'createdAt': '2026-04-08T00:00:00.000Z',
      };
      final server = McpServer.fromJson(json);
      expect(server.id, 'server-1');
      expect(server.name, 'Test Server');
      expect(server.command, 'npx');
      expect(server.args, ['-y', 'some-mcp']);
      expect(server.env, {'API_KEY': 'abc123'});
      expect(server.enabled, true);
      expect(server.transport, McpTransport.stdio);
      expect(server.description, 'A test server');
      expect(server.source, 'manual');
      expect(server.createdAt, isNotNull);
    });

    test('parses sse transport', () {
      final json = {
        'id': 'sse-server',
        'name': 'SSE Server',
        'command': '',
        'transport': 'sse',
        'url': 'http://localhost:3000/sse',
      };
      final server = McpServer.fromJson(json);
      expect(server.transport, McpTransport.sse);
      expect(server.url, 'http://localhost:3000/sse');
    });

    test('uses defaults for missing optional fields', () {
      final json = {'id': 'x', 'name': 'X', 'command': 'cmd'};
      final server = McpServer.fromJson(json);
      expect(server.args, isEmpty);
      expect(server.env, isEmpty);
      expect(server.enabled, true);
      expect(server.transport, McpTransport.stdio);
      expect(server.url, isNull);
      expect(server.description, isNull);
      expect(server.source, isNull);
      expect(server.createdAt, isNull);
    });
  });

  group('McpServer.toJson', () {
    test('round-trip fromJson → toJson preserves all fields', () {
      final original = {
        'id': 'server-1',
        'name': 'Test Server',
        'command': 'npx',
        'args': ['-y', 'some-mcp'],
        'env': {'KEY': 'val'},
        'enabled': false,
        'transport': 'stdio',
        'description': 'desc',
        'source': 'clawhub',
        'createdAt': '2026-04-08T00:00:00.000Z',
      };
      final server = McpServer.fromJson(original);
      final json = server.toJson();
      expect(json['id'], 'server-1');
      expect(json['name'], 'Test Server');
      expect(json['command'], 'npx');
      expect(json['args'], ['-y', 'some-mcp']);
      expect(json['env'], {'KEY': 'val'});
      expect(json['enabled'], false);
      expect(json['transport'], 'stdio');
      expect(json['description'], 'desc');
      expect(json['source'], 'clawhub');
      expect(json['createdAt'], isNotNull);
    });

    test('sse transport serializes as "sse"', () {
      const server = McpServer(
        id: 'sse',
        name: 'SSE',
        command: '',
        transport: McpTransport.sse,
        url: 'http://localhost/sse',
      );
      final json = server.toJson();
      expect(json['transport'], 'sse');
      expect(json['url'], 'http://localhost/sse');
    });

    test('null optional fields are omitted from JSON', () {
      const server = McpServer(id: 'x', name: 'X', command: 'cmd');
      final json = server.toJson();
      expect(json.containsKey('url'), false);
      expect(json.containsKey('description'), false);
      expect(json.containsKey('source'), false);
      expect(json.containsKey('createdAt'), false);
    });
  });

  group('McpServer.copyWith', () {
    test('updates only specified fields', () {
      const server = McpServer(
        id: 'orig',
        name: 'Original',
        command: 'cmd',
        enabled: true,
      );
      final updated = server.copyWith(name: 'Updated', enabled: false);
      expect(updated.id, 'orig');
      expect(updated.name, 'Updated');
      expect(updated.command, 'cmd');
      expect(updated.enabled, false);
    });

    test('preserves all unchanged fields', () {
      final server = McpServer.fromJson({
        'id': 's1',
        'name': 'S1',
        'command': 'npx',
        'args': ['--arg'],
        'env': {'K': 'V'},
        'enabled': true,
        'transport': 'stdio',
        'description': 'desc',
        'source': 'manual',
      });
      final copy = server.copyWith(enabled: false);
      expect(copy.args, ['--arg']);
      expect(copy.env, {'K': 'V'});
      expect(copy.description, 'desc');
      expect(copy.source, 'manual');
    });
  });

  group('McpServer.toOpenClawFormat', () {
    test('stdio format includes command and args', () {
      const server = McpServer(
        id: 'x',
        name: 'X',
        command: 'npx',
        args: ['-y', 'pkg'],
      );
      final fmt = server.toOpenClawFormat();
      expect(fmt['command'], 'npx');
      expect(fmt['args'], ['-y', 'pkg']);
      expect(fmt.containsKey('transport'), false);
    });

    test('sse format includes transport and url', () {
      const server = McpServer(
        id: 'x',
        name: 'X',
        command: '',
        transport: McpTransport.sse,
        url: 'http://localhost/sse',
      );
      final fmt = server.toOpenClawFormat();
      expect(fmt['transport'], 'sse');
      expect(fmt['url'], 'http://localhost/sse');
    });
  });

  group('McpPreset', () {
    test('constructor sets all fields', () {
      const preset = McpPreset(
        name: 'Filesystem',
        command: 'npx',
        args: ['-y', '@modelcontextprotocol/server-filesystem'],
        envKeys: ['ROOT_PATH'],
        description: '文件系统访问',
        category: '工具',
      );
      expect(preset.name, 'Filesystem');
      expect(preset.command, 'npx');
      expect(preset.args, ['-y', '@modelcontextprotocol/server-filesystem']);
      expect(preset.envKeys, ['ROOT_PATH']);
      expect(preset.description, '文件系统访问');
      expect(preset.category, '工具');
    });

    test('toServer creates McpServer with preset values', () {
      const preset = McpPreset(
        name: 'Test Preset',
        command: 'npx',
        args: ['-y', 'pkg'],
        description: 'desc',
      );
      final server = preset.toServer(id: 'new-id', env: {'KEY': 'val'});
      expect(server.id, 'new-id');
      expect(server.name, 'Test Preset');
      expect(server.command, 'npx');
      expect(server.args, ['-y', 'pkg']);
      expect(server.env, {'KEY': 'val'});
      expect(server.source, 'preset');
      expect(server.createdAt, isNotNull);
    });

    test('default category is 通用', () {
      const preset = McpPreset(
        name: 'X',
        command: 'cmd',
        args: [],
        description: 'desc',
      );
      expect(preset.category, '通用');
    });
  });
}
