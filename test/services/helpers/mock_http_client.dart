import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'mock_http_client.mocks.dart';

// Generate: dart run build_runner build --delete-conflicting-outputs
@GenerateMocks([http.Client])
export 'mock_http_client.mocks.dart';

/// Convenience: stub a GET to return given status + body.
void stubGet(
  MockClient mock,
  String url, {
  int status = 200,
  String body = '{}',
}) {
  when(mock.get(Uri.parse(url), headers: anyNamed('headers')))
      .thenAnswer((_) async => http.Response(body, status));
  // Also stub without headers arg
  when(mock.get(Uri.parse(url)))
      .thenAnswer((_) async => http.Response(body, status));
}
