import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/gateway_service.dart';

void main() {
  group('GatewayMessage.fromJson', () {
    test('parses type and content', () {
      final msg = GatewayMessage.fromJson({
        'type': 'log',
        'content': 'hello',
      });
      expect(msg.type, 'log');
      expect(msg.content, 'hello');
    });

    test('defaults type to unknown when missing', () {
      final msg = GatewayMessage.fromJson({'content': 'x'});
      expect(msg.type, 'unknown');
    });

    test('raw contains original json', () {
      final json = {'type': 'test', 'content': 'data', 'extra': 42};
      final msg = GatewayMessage.fromJson(json);
      expect(msg.raw, json);
    });
  });

  group('HealthStatus.fromJson', () {
    test('parses status and services', () {
      final health = HealthStatus.fromJson({
        'status': 'healthy',
        'services': {'gateway': 'ok'},
        'timestamp': '2026-01-01T00:00:00.000Z',
      });
      expect(health.status, 'healthy');
      expect(health.services['gateway'], 'ok');
    });

    test('isHealthy true for healthy', () {
      final h = HealthStatus.fromJson({
        'status': 'healthy',
        'services': <String, dynamic>{},
        'timestamp': '',
      });
      expect(h.isHealthy, isTrue);
    });

    test('isHealthy true for ok', () {
      final h = HealthStatus.fromJson({
        'status': 'ok',
        'services': <String, dynamic>{},
        'timestamp': '',
      });
      expect(h.isHealthy, isTrue);
    });

    test('isHealthy false for error', () {
      final h = HealthStatus.fromJson({
        'status': 'error',
        'services': <String, dynamic>{},
        'timestamp': '',
      });
      expect(h.isHealthy, isFalse);
    });

    test('parses timestamp as DateTime', () {
      final h = HealthStatus.fromJson({
        'status': 'ok',
        'services': <String, dynamic>{},
        'timestamp': '2026-06-15T12:30:00.000Z',
      });
      expect(h.timestamp.year, 2026);
      expect(h.timestamp.month, 6);
    });
  });

  group('Session.fromJson', () {
    test('parses id and messageCount', () {
      final session = Session.fromJson({
        'id': 'sess-123',
        'message_count': 42,
        'last_activity': '2026-01-01T00:00:00.000Z',
      });
      expect(session.id, 'sess-123');
      expect(session.messageCount, 42);
    });

    test('parses optional recipient and channel', () {
      final session = Session.fromJson({
        'id': 's1',
        'recipient': 'user@example.com',
        'channel': 'feishu',
        'message_count': 0,
        'last_activity': '',
      });
      expect(session.recipient, 'user@example.com');
      expect(session.channel, 'feishu');
    });

    test('defaults messageCount to 0 when missing', () {
      final session = Session.fromJson({
        'id': 's2',
        'last_activity': '',
      });
      expect(session.messageCount, 0);
    });
  });

  group('Channel.fromJson', () {
    test('parses name, type, connected', () {
      final ch = Channel.fromJson({
        'name': 'feishu',
        'type': 'webhook',
        'connected': true,
      });
      expect(ch.name, 'feishu');
      expect(ch.type, 'webhook');
      expect(ch.connected, isTrue);
    });

    test('connected defaults to false when missing', () {
      final ch = Channel.fromJson({'name': 'x', 'type': 'y'});
      expect(ch.connected, isFalse);
    });

    test('parses optional status', () {
      final ch = Channel.fromJson({
        'name': 'slack',
        'type': 'bot',
        'connected': true,
        'status': 'active',
      });
      expect(ch.status, 'active');
    });
  });

  group('LogEntry.fromJson', () {
    test('parses level and message', () {
      final entry = LogEntry.fromJson({
        'level': 'error',
        'message': 'Something failed',
        'timestamp': '2026-01-01T00:00:00.000Z',
      });
      expect(entry.level, 'error');
      expect(entry.message, 'Something failed');
    });

    test('defaults level to info when missing', () {
      final entry = LogEntry.fromJson({'message': 'hi', 'timestamp': ''});
      expect(entry.level, 'info');
    });

    test('parses optional source', () {
      final entry = LogEntry.fromJson({
        'level': 'debug',
        'message': 'test',
        'timestamp': '',
        'source': 'gateway',
      });
      expect(entry.source, 'gateway');
    });
  });

  group('AgentResult.fromJson', () {
    test('parses response and delivered', () {
      final result = AgentResult.fromJson({
        'response': 'Done',
        'delivered': true,
        'metadata': {'key': 'value'},
      });
      expect(result.response, 'Done');
      expect(result.delivered, isTrue);
      expect(result.metadata['key'], 'value');
    });

    test('delivered defaults to false when missing', () {
      final result = AgentResult.fromJson({'response': 'x'});
      expect(result.delivered, isFalse);
    });

    test('metadata defaults to empty map when missing', () {
      final result = AgentResult.fromJson({'response': 'y'});
      expect(result.metadata, isEmpty);
    });
  });
}
