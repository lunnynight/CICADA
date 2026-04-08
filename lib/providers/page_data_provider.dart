import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/diagnostic.dart';
import '../models/skill.dart';
import '../services/gateway_service.dart';
import '../services/skill_discovery_service.dart';
import '../services/diagnostic_service.dart';

/// Channels list (cached across page switches)
final channelsProvider = FutureProvider<List<Channel>>((ref) async {
  ref.keepAlive();
  return GatewayService.getChannels();
});

/// All skills merged from all sources (cached)
final skillsProvider = FutureProvider<List<Skill>>((ref) async {
  ref.keepAlive();
  return SkillDiscoveryService.discoverAll();
});

/// Skill categories
final skillCategoriesProvider = FutureProvider<List<String>>((ref) async {
  ref.keepAlive();
  return SkillDiscoveryService.getCategories();
});

/// Diagnostic report (cached — only re-runs on manual invalidate)
final diagnosticReportProvider =
    FutureProvider<DiagnosticReport>((ref) async {
  ref.keepAlive();
  return DiagnosticService.runDiagnostics();
});
