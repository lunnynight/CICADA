// API Key and sensitive data masking utilities.
//
// Used across UI, logs, and diagnostics to prevent
// accidental exposure of credentials.

/// Mask an API key for display: show first 4 + last 4, middle replaced with `...`
///
/// Keys with length ≤ 8 return `***`.
/// Empty/null-safe: empty string returns empty string.
String maskApiKey(String key) {
  if (key.isEmpty) return '';
  if (key.length <= 8) return '***';
  return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
}

/// Mask authentication info in a URL.
///
/// `https://user:password@host.com` → `https://user:***@host.com`
/// URLs without auth info are returned unchanged.
String maskUrl(String url) {
  if (url.isEmpty) return '';
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  if (uri.userInfo.isEmpty) return url;

  final parts = uri.userInfo.split(':');
  final maskedUserInfo = parts.length > 1 ? '${parts[0]}:***' : parts[0];

  return url.replaceFirst(uri.userInfo, maskedUserInfo);
}

/// Mask an Authorization header value.
///
/// `Bearer sk-1234567890abcdef` → `Bearer sk-1...cdef`
String maskAuthHeader(String header) {
  if (header.isEmpty) return '';
  final parts = header.split(' ');
  if (parts.length == 2) {
    return '${parts[0]} ${maskApiKey(parts[1])}';
  }
  return maskApiKey(header);
}
