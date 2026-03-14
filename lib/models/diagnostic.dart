/// Structured diagnostic report model, inspired by feedclaw-desktop.
class DiagnosticReport {
  final String level; // ok, info, warn, error
  final String title;
  final String summary;
  final List<DiagnosticFinding> findings;

  const DiagnosticReport({
    required this.level,
    required this.title,
    required this.summary,
    required this.findings,
  });
}

class DiagnosticFinding {
  final String id;
  final String level; // ok, info, warn, error
  final String title;
  final String summary;
  final String? detail;
  final List<DiagnosticAction> actions;

  const DiagnosticFinding({
    required this.id,
    required this.level,
    required this.title,
    required this.summary,
    this.detail,
    this.actions = const [],
  });
}

class DiagnosticAction {
  final String id;
  final String label;

  const DiagnosticAction({required this.id, required this.label});
}

/// Token usage record parsed from logs.
class TokenRecord {
  final DateTime timestamp;
  final String model;
  final int inputTokens;
  final int outputTokens;
  final int cacheTokens;

  const TokenRecord({
    required this.timestamp,
    required this.model,
    required this.inputTokens,
    required this.outputTokens,
    this.cacheTokens = 0,
  });

  int get totalTokens => inputTokens + outputTokens + cacheTokens;
}
