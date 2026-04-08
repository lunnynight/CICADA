import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/models/provider.dart';

void main() {
  group('ModelInfo', () {
    test('fromJson parses all fields', () {
      final json = {'id': 'claude-3-5-sonnet', 'name': 'Claude 3.5 Sonnet', 'context': 200000};
      final model = ModelInfo.fromJson(json);
      expect(model.id, 'claude-3-5-sonnet');
      expect(model.name, 'Claude 3.5 Sonnet');
      expect(model.context, 200000);
    });

    test('toJson round-trip', () {
      final json = {'id': 'gpt-4o', 'name': 'GPT-4o', 'context': 128000};
      final model = ModelInfo.fromJson(json);
      final out = model.toJson();
      expect(out['id'], 'gpt-4o');
      expect(out['name'], 'GPT-4o');
      expect(out['context'], 128000);
    });
  });

  group('ProviderConfig', () {
    Map<String, dynamic> _sampleJson() => {
      'id': 'anthropic',
      'name': 'Anthropic',
      'provider': 'anthropic',
      'description': 'Claude models',
      'apiBase': 'https://api.anthropic.com',
      'models': [
        {'id': 'claude-3-5-sonnet', 'name': 'Claude 3.5 Sonnet', 'context': 200000},
      ],
      'keyUrl': 'https://console.anthropic.com',
      'freeQuota': '无免费额度',
      'docs': 'https://docs.anthropic.com',
    };

    test('fromJson parses all fields', () {
      final config = ProviderConfig.fromJson(_sampleJson());
      expect(config.id, 'anthropic');
      expect(config.name, 'Anthropic');
      expect(config.provider, 'anthropic');
      expect(config.description, 'Claude models');
      expect(config.apiBase, 'https://api.anthropic.com');
      expect(config.models.length, 1);
      expect(config.models.first.id, 'claude-3-5-sonnet');
      expect(config.keyUrl, 'https://console.anthropic.com');
      expect(config.freeQuota, '无免费额度');
      expect(config.docs, 'https://docs.anthropic.com');
    });

    test('fromJson with empty models list', () {
      final json = _sampleJson();
      json['models'] = <dynamic>[];
      final config = ProviderConfig.fromJson(json);
      expect(config.models, isEmpty);
    });

    test('fromJson with multiple models', () {
      final json = _sampleJson();
      json['models'] = [
        {'id': 'model-a', 'name': 'Model A', 'context': 8000},
        {'id': 'model-b', 'name': 'Model B', 'context': 16000},
      ];
      final config = ProviderConfig.fromJson(json);
      expect(config.models.length, 2);
      expect(config.models[1].id, 'model-b');
    });

    test('fromJson uses empty string defaults for optional fields', () {
      final json = _sampleJson();
      json.remove('keyUrl');
      json.remove('freeQuota');
      json.remove('docs');
      final config = ProviderConfig.fromJson(json);
      expect(config.keyUrl, '');
      expect(config.freeQuota, '');
      expect(config.docs, '');
    });
  });
}
