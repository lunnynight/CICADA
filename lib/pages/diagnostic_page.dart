import 'package:flutter/material.dart';
import 'package:super_clipboard/super_clipboard.dart';
import '../app/theme/cicada_colors.dart';
import '../app/widgets/terminal_dialog.dart';
import '../models/diagnostic.dart';
import '../services/diagnostic_service.dart';

class DiagnosticPage extends StatefulWidget {
  const DiagnosticPage({super.key});

  @override
  State<DiagnosticPage> createState() => _DiagnosticPageState();
}

class _DiagnosticPageState extends State<DiagnosticPage> {
  DiagnosticReport? _report;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    setState(() => _running = true);
    final report = await DiagnosticService.runDiagnostics();
    if (!mounted) return;
    setState(() {
      _report = report;
      _running = false;
    });
  }

  Future<void> _copyReport() async {
    if (_report == null) return;
    try {
      final reportText = DiagnosticService.exportReport(_report!);

      // Use super_clipboard to copy to clipboard
      final clipboard = SystemClipboard.instance;
      if (clipboard != null) {
        final item = DataWriterItem();
        item.add(Formats.plainText(reportText));
        await clipboard.write([item]);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('报告已复制到剪贴板')),
        );
      } else {
        // Fallback: just show the report text
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('剪贴板不可用')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('复制失败: $e')),
      );
    }
  }

  Widget _buildLevelIcon(String level) {
    switch (level) {
      case 'ok':
        return const Icon(Icons.check_circle, color: CicadaColors.ok, size: 48);
      case 'warn':
        return const Icon(Icons.warning_amber, color: Colors.orange, size: 48);
      case 'error':
        return const Icon(Icons.error, color: CicadaColors.alert, size: 48);
      case 'info':
      default:
        return const Icon(Icons.info, color: CicadaColors.energy, size: 48);
    }
  }

  Color _levelToColor(String level) {
    switch (level) {
      case 'ok':
        return CicadaColors.ok;
      case 'warn':
        return Colors.orange;
      case 'error':
        return CicadaColors.alert;
      case 'info':
      default:
        return CicadaColors.energy;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'DIAGNOSTIC CENTER',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: CicadaColors.textPrimary,
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: _running ? null : _runDiagnostics,
                icon: _running
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('重新检测'),
                style: FilledButton.styleFrom(
                  backgroundColor: CicadaColors.data,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '三层诊断: 本地检测 → 预置修复 → 报告导出',
            style: TextStyle(
              color: CicadaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Overall status card
          if (_report != null) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: CicadaColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _levelToColor(_report!.level),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  _buildLevelIcon(_report!.level),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _report!.title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: _levelToColor(_report!.level),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _report!.summary,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CicadaColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          final reportText =
                              DiagnosticService.exportReport(_report!);
                          final lines = ValueNotifier<List<String>>(
                            reportText.split('\n'),
                          );
                          final running = ValueNotifier<bool>(false);

                          TerminalDialog.show(
                            context,
                            title: '诊断报告',
                            lines: lines,
                            running: running,
                          );
                        },
                        icon: const Icon(Icons.text_snippet, size: 16),
                        label: const Text('查看报告'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: CicadaColors.border),
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _copyReport,
                        icon: const Icon(Icons.copy, size: 16),
                        label: const Text('复制报告'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: CicadaColors.border),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Findings list
            const Text(
              '详细发现',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: CicadaColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _report!.findings.length,
              itemBuilder: (_, index) {
                final finding = _report!.findings[index];
                return _buildFindingCard(finding);
              },
            ),
          ],

          // Loading state
          if (_running) ...[
            const Center(
              child: SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text('正在执行三层诊断...'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFindingCard(DiagnosticFinding finding) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _levelToColor(finding.level).withAlpha(128),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 16,
                color: _levelToColor(finding.level),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  finding.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _levelToColor(finding.level),
                  ),
                ),
              ),
              Text(
                finding.id,
                style: const TextStyle(
                  fontSize: 11,
                  color: CicadaColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            finding.summary,
            style: const TextStyle(
              fontSize: 13,
              color: CicadaColors.textSecondary,
            ),
          ),
          if (finding.detail != null) ...[
            const SizedBox(height: 4),
            Text(
              finding.detail!,
              style: const TextStyle(
                fontSize: 12,
                color: CicadaColors.textTertiary,
              ),
            ),
          ],
          if (finding.actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  '建议操作:',
                  style: TextStyle(
                    fontSize: 12,
                    color: CicadaColors.textTertiary,
                  ),
                ),
                const SizedBox(width: 8),
                Wrap(
                  spacing: 6,
                  children: finding.actions.map((action) {
                    return OutlinedButton(
                      onPressed: () => _handleAction(action),
                      style: OutlinedButton.styleFrom(
                        backgroundColor:
                            CicadaColors.data.withValues(alpha: 0.05),
                        side: BorderSide(
                          color: _levelToColor(finding.level),
                        ),
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        action.label,
                        style: TextStyle(
                          fontSize: 11,
                          color: _levelToColor(finding.level),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _handleAction(DiagnosticAction action) {
    switch (action.id) {
      case 'goto_setup':
        // TODO: Navigate to setup page
        break;
      case 'goto_models':
        // TODO: Navigate to models page
        break;
      case 'goto_dashboard':
        // TODO: Navigate to dashboard page
        break;
      case 'retry':
        _runDiagnostics();
        break;
    }
  }
}
