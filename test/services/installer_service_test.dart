import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/installer_service.dart';

void main() {
  group('InstallerService.parseNodeMajorVersion', () {
    test('parses v22.3.0 to 22', () {
      expect(InstallerService.parseNodeMajorVersion('v22.3.0'), 22);
    });

    test('parses v18.0.0 to 18', () {
      expect(InstallerService.parseNodeMajorVersion('v18.0.0'), 18);
    });

    test('parses without leading v', () {
      expect(InstallerService.parseNodeMajorVersion('22.3.0'), 22);
    });

    test('parses version with only major', () {
      expect(InstallerService.parseNodeMajorVersion('v22'), 22);
    });

    test('returns null for empty string', () {
      expect(InstallerService.parseNodeMajorVersion(''), isNull);
    });

    test('returns null for non-version string', () {
      expect(InstallerService.parseNodeMajorVersion('not-a-version'), isNull);
    });

    test('handles whitespace around version', () {
      expect(InstallerService.parseNodeMajorVersion('  v22.3.0  '), 22);
    });
  });
}
