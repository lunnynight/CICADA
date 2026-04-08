import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/providers/gateway_provider.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });
  group('gatewayStatusProvider', () {
    test('returns a bool', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final status = await container.read(gatewayStatusProvider.future);
      expect(status, isA<bool>());
    });
  });

  group('gatewaySessionsProvider', () {
    test('returns a list', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final sessions = await container.read(gatewaySessionsProvider.future);
      expect(sessions, isA<List>());
    });
  });

  group('gatewayModelsProvider', () {
    test('returns a map', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final models = await container.read(gatewayModelsProvider.future);
      expect(models, isA<Map>());
    });
  });

  group('currentProviderIdProvider', () {
    test('returns null or string', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final id = await container.read(currentProviderIdProvider.future);
      // id is String? — either null or a non-empty string
      if (id != null) {
        expect(id, isNotEmpty);
      }
    });
  });

  group('configuredProviderMapProvider', () {
    test('returns a map', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final map = await container.read(configuredProviderMapProvider.future);
      expect(map, isA<Map<String, dynamic>>());
    });
  });
}
