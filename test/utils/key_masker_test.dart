import 'package:flutter_test/flutter_test.dart';
import 'package:cicada/utils/key_masker.dart';

void main() {
  group('maskApiKey', () {
    test('empty string returns empty', () {
      expect(maskApiKey(''), '');
    });

    test('short key (≤8) returns ***', () {
      expect(maskApiKey('abc'), '***');
      expect(maskApiKey('12345678'), '***');
    });

    test('normal key shows first 4 + last 4', () {
      expect(maskApiKey('sk-1234567890abcdef'), 'sk-1...cdef');
    });

    test('9-char key shows first 4 + last 4', () {
      expect(maskApiKey('123456789'), '1234...6789');
    });

    test('long key masks correctly', () {
      final key = 'sk-ant-api03-very-long-key-that-should-be-masked-properly-end1';
      final masked = maskApiKey(key);
      expect(masked, startsWith('sk-a'));
      expect(masked, endsWith('end1'));
      expect(masked, contains('...'));
      expect(masked.length, lessThan(key.length));
    });
  });

  group('maskUrl', () {
    test('empty string returns empty', () {
      expect(maskUrl(''), '');
    });

    test('URL without auth returns unchanged', () {
      expect(maskUrl('https://api.example.com'), 'https://api.example.com');
    });

    test('URL with user:pass masks password', () {
      expect(
        maskUrl('https://user:secret@proxy.example.com:8080'),
        'https://user:***@proxy.example.com:8080',
      );
    });

    test('URL with user only (no password) keeps user', () {
      expect(
        maskUrl('https://user@proxy.example.com'),
        'https://user@proxy.example.com',
      );
    });

    test('invalid URL returns as-is', () {
      expect(maskUrl('not a url'), 'not a url');
    });
  });

  group('maskAuthHeader', () {
    test('empty returns empty', () {
      expect(maskAuthHeader(''), '');
    });

    test('Bearer token masks key part', () {
      expect(
        maskAuthHeader('Bearer sk-1234567890abcdef'),
        'Bearer sk-1...cdef',
      );
    });

    test('short Bearer token', () {
      expect(maskAuthHeader('Bearer abc'), 'Bearer ***');
    });

    test('non-Bearer header masks whole value', () {
      expect(maskAuthHeader('sk-1234567890abcdef'), 'sk-1...cdef');
    });
  });
}
