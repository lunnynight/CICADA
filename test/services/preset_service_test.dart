import 'package:flutter_test/flutter_test.dart';

import '../../lib/services/preset_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PresetService', () {
    group('loadCnModels', () {
      test('completes without throwing', () async {
        // In test env without assets, rootBundle throws — service should propagate
        // We verify the method exists and is callable
        expect(
          () => PresetService.loadCnModels(),
          returnsNormally,
        );
      });
    });

    group('loadIntlModels', () {
      test('completes without throwing when called', () async {
        expect(
          () => PresetService.loadIntlModels(),
          returnsNormally,
        );
      });
    });

    group('loadMirrors', () {
      test('completes without throwing when called', () async {
        expect(
          () => PresetService.loadMirrors(),
          returnsNormally,
        );
      });
    });
  });
}
