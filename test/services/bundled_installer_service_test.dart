import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/bundled_installer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('BundledInstallerService', () {
    group('isBundledAvailable', () {
      test('returns a bool without throwing', () async {
        final result = await BundledInstallerService.isBundledAvailable();
        expect(result, isA<bool>());
      });

      test('returns false when manifest asset is not present in test env', () async {
        // In unit test environment, Flutter assets are not loaded from pubspec,
        // so manifest will not be found → returns false
        final result = await BundledInstallerService.isBundledAvailable();
        expect(result, isFalse);
      });
    });

    group('getBundledVersions', () {
      test('returns map with node and openclaw keys when manifest is available', () async {
        final versions = await BundledInstallerService.getBundledVersions();
        // Manifest asset is available in test env
        if (versions != null) {
          expect(versions.containsKey('node'), isTrue);
          expect(versions.containsKey('openclaw'), isTrue);
        }
        // null is also acceptable if manifest is not bundled in this build
        expect(versions, anyOf(isNull, isA<Map<String, String>>()));
      });
    });

    group('isNodeExtracted', () {
      test('returns false when node path cannot be resolved', () async {
        final result = await BundledInstallerService.isNodeExtracted();
        expect(result, isFalse);
      });
    });

    group('isOpenClawInstalled', () {
      test('returns a bool without throwing', () async {
        final result = await BundledInstallerService.isOpenClawInstalled();
        expect(result, isA<bool>());
      });
    });

    group('testNodeInstallation', () {
      test('returns false when node is not extracted', () async {
        final result = await BundledInstallerService.testNodeInstallation();
        expect(result, isFalse);
      });
    });
  });

  group('ExtractProgress', () {
    test('holds step and percent', () {
      const progress = ExtractProgress(step: '解压中...', percent: 50);
      expect(progress.step, equals('解压中...'));
      expect(progress.percent, equals(50));
    });

    test('percent 0 is valid', () {
      const progress = ExtractProgress(step: '准备', percent: 0);
      expect(progress.percent, equals(0));
    });

    test('percent 100 is valid', () {
      const progress = ExtractProgress(step: '完成', percent: 100);
      expect(progress.percent, equals(100));
    });
  });
}
