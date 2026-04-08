import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/update_service.dart';

void main() {
  group('UpdateInfo', () {
    test('hasUpdate=true when newer version available', () {
      const info = UpdateInfo(
        hasUpdate: true,
        latestVersion: '0.2.0',
        releaseNotes: 'Bug fixes',
        downloadUrl: 'https://example.com/cicada.exe',
      );
      expect(info.hasUpdate, isTrue);
      expect(info.latestVersion, '0.2.0');
      expect(info.releaseNotes, 'Bug fixes');
      expect(info.downloadUrl, isNotEmpty);
    });

    test('hasUpdate=false when on latest version', () {
      const info = UpdateInfo(
        hasUpdate: false,
        latestVersion: '0.1.0',
        releaseNotes: '',
        downloadUrl: '',
      );
      expect(info.hasUpdate, isFalse);
    });
  });

  group('BackupInfo', () {
    test('BackupInfo.invalid() has isValid=false', () {
      final backup = BackupInfo.invalid();
      expect(backup.isValid, isFalse);
      expect(backup.version, isEmpty);
      expect(backup.backupPath, isEmpty);
    });

    test('BackupInfo with valid fields has isValid=true', () {
      final backup = BackupInfo(
        version: '0.1.0',
        backupPath: '/tmp/backup_0.1.0_123456',
        backupTime: DateTime(2026, 1, 1),
        isValid: true,
      );
      expect(backup.isValid, isTrue);
      expect(backup.version, '0.1.0');
    });
  });
}
