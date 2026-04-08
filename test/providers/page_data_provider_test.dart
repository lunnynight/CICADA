import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/models/diagnostic.dart';
import '../../lib/models/skill.dart';
import '../../lib/services/gateway_service.dart' show Channel;
import '../../lib/providers/page_data_provider.dart';

void main() {
  group('channelsProvider', () {
    test('returns a list of channels', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final channels = await container.read(channelsProvider.future);
      expect(channels, isA<List<Channel>>());
    });
  });

  group('skillsProvider', () {
    test('returns a list of skills', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final skills = await container.read(skillsProvider.future);
      expect(skills, isA<List<Skill>>());
    });
  });

  group('skillCategoriesProvider', () {
    test('returns a list of category strings', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final categories = await container.read(skillCategoriesProvider.future);
      expect(categories, isA<List<String>>());
    });
  });

  group('diagnosticReportProvider', () {
    test('returns a DiagnosticReport', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final report = await container.read(diagnosticReportProvider.future);
      expect(report, isA<DiagnosticReport>());
      expect(report.level, isNotEmpty);
      expect(report.findings, isA<List<DiagnosticFinding>>());
    });
  });
}
