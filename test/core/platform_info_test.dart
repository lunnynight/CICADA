import 'dart:io' show Platform;
import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/core/platform/platform_info.dart';

void main() {
  group('PlatformInfo', () {
    test('isDesktop returns bool', () {
      expect(PlatformInfo.isDesktop, isA<bool>());
    });

    test('isMobile returns bool', () {
      expect(PlatformInfo.isMobile, isA<bool>());
    });

    test('canRunProcesses returns bool', () {
      expect(PlatformInfo.canRunProcesses, isA<bool>());
    });

    test('needsTermux returns bool', () {
      expect(PlatformInfo.needsTermux, isA<bool>());
    });

    test('isDesktop and isMobile are mutually exclusive', () {
      // A platform cannot be both desktop and mobile simultaneously
      expect(PlatformInfo.isDesktop && PlatformInfo.isMobile, false);
    });

    test('canRunProcesses equals isDesktop', () {
      expect(PlatformInfo.canRunProcesses, PlatformInfo.isDesktop);
    });

    test('needsTermux equals Platform.isAndroid', () {
      expect(PlatformInfo.needsTermux, Platform.isAndroid);
    });

    // Windows-specific assertions (test environment is Windows)
    test('isDesktop is true on Windows', () {
      if (Platform.isWindows) {
        expect(PlatformInfo.isDesktop, true);
      }
    }, skip: !Platform.isWindows);

    test('isMobile is false on Windows', () {
      if (Platform.isWindows) {
        expect(PlatformInfo.isMobile, false);
      }
    }, skip: !Platform.isWindows);

    test('needsTermux is false on Windows', () {
      if (Platform.isWindows) {
        expect(PlatformInfo.needsTermux, false);
      }
    }, skip: !Platform.isWindows);
  });
}
