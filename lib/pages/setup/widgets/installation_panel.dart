import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/cicada_colors.dart';
import '../../../services/installer_service.dart';
import '../../../widgets/terminal_output.dart';
import '../logic/setup_state.dart';

/// Target for installation panel
enum InstallTarget { node, openclaw, claudeCode }

/// Installation panel widget
class InstallationPanel extends ConsumerWidget {
  final String title;
  final String description;
  final InstallTarget target;
  final bool useBundled;

  const InstallationPanel({
    super.key,
    required this.title,
    required this.description,
    required this.target,
    this.useBundled = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(setupStateProvider);
    final notifier = ref.read(setupStateProvider.notifier);

    final isInstalled = switch (target) {
      InstallTarget.node => state.nodeInstalled,
      InstallTarget.openclaw => state.openclawInstalled,
      InstallTarget.claudeCode => state.claudeCodeInstalled,
    };
    final version = switch (target) {
      InstallTarget.node => state.nodeVersion,
      InstallTarget.openclaw => state.clawVersion,
      InstallTarget.claudeCode => state.claudeCodeVersion,
    };
    final isNode = target == InstallTarget.node;

    return Card(
      color: CicadaColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(color: CicadaColors.textSecondary),
            ),
            const SizedBox(height: 24),
            if (isInstalled) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: CicadaColors.ok.withAlpha(40),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CicadaColors.ok),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: CicadaColors.ok,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$title 已安装',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: CicadaColors.ok,
                            ),
                          ),
                          if (version.isNotEmpty)
                            Text(
                              version,
                              style: const TextStyle(
                                fontSize: 12,
                                color: CicadaColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  ElevatedButton(
                    onPressed: () => notifier.setCurrentStep(
                      state.currentStep + 1,
                    ),
                    child: const Text('下一步'),
                  ),
                ],
              ),
            ] else ...[
              if (state.logLines.isNotEmpty) ...[
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TerminalOutput(lines: state.logLines),
                ),
                const SizedBox(height: 16),
              ],
              if (!state.installing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => notifier.setCurrentStep(
                        state.currentStep - 1,
                      ),
                      child: const Text('上一步'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        if (target == InstallTarget.claudeCode) {
                          // Claude Code: always online install via npm
                          notifier.runInstall(
                            () => InstallerService.installClaudeCode(
                              mirrorUrl: state.selectedMirror,
                            ),
                            title,
                          );
                        } else if (useBundled) {
                          notifier.runBundledInstall(
                            isNode: isNode,
                            name: title,
                          );
                        } else {
                          notifier.runOnlineInstall(
                            isNode: isNode,
                            name: title,
                          );
                        }
                      },
                      child: Text(target == InstallTarget.claudeCode
                          ? '安装'
                          : useBundled
                              ? '离线安装'
                              : '在线安装'),
                    ),
                  ],
                )
              else
                const Center(
                  child: CircularProgressIndicator(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
