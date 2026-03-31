import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../core/platform/platform_info.dart';
import '../services/installer_service.dart';
import '../services/termux_bridge.dart';
import '../widgets/terminal_output.dart';

/// Step status for three-state visualization
enum StepStatus {
  notStarted, // 未开始 - 灰色
  inProgress, // 进行中 - 蓝色/橙色
  completed, // 已完成 - 绿色
}

class SetupPage extends StatefulWidget {
  final VoidCallback? onSetupComplete;

  const SetupPage({super.key, this.onSetupComplete});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  int _currentStep = 0;
  bool _nodeInstalled = false;
  bool _openclawInstalled = false;
  bool _detecting = true;
  bool _installing = false;
  bool _bundledAvailable = false;
  String _selectedMirror = 'https://registry.npmmirror.com';
  final List<String> _logLines = [];
  String _nodeVersion = '';
  String _clawVersion = '';
  String _bundledNodeVersion = '';
  String _bundledOpenClawVersion = '';
  // Android/Termux state
  bool _termuxInstalled = false;
  bool _termuxConfiguring = false;
  final List<String> _termuxConfigLog = [];

  @override
  void initState() {
    super.initState();
    _detect();
  }

  Future<void> _detect() async {
    setState(() => _detecting = true);

    // Android: check Termux first
    if (PlatformInfo.needsTermux) {
      final termuxOk = await TermuxBridge.isTermuxInstalled();
      if (!mounted) return;
      setState(() => _termuxInstalled = termuxOk);
      if (termuxOk) {
        // Check Node (with version >= 22) and OpenClaw inside Termux
        final nodeCheck = await InstallerService.isNodeVersionSufficient();
        final clawResult = await InstallerService.checkOpenClaw();
        if (!mounted) return;
        setState(() {
          _nodeInstalled = nodeCheck.sufficient;
          _openclawInstalled = clawResult.exitCode == 0;
          _nodeVersion = nodeCheck.raw;
          _clawVersion = _openclawInstalled ? (clawResult.stdout as String).trim() : '';
          _bundledAvailable = false; // No bundled on Android
          _detecting = false;
        });
      } else {
        setState(() {
          _nodeInstalled = false;
          _openclawInstalled = false;
          _bundledAvailable = false;
          _detecting = false;
        });
      }
      return;
    }

    // Desktop flow — require Node >= 22
    final nodeCheck = await InstallerService.isNodeVersionSufficient();
    final clawResult = await InstallerService.checkOpenClaw();
    final bundledAvailable = await InstallerService.isBundledAvailable();
    final bundledVersions = await InstallerService.getBundledVersions();
    if (!mounted) return;
    setState(() {
      _nodeInstalled = nodeCheck.sufficient;
      _openclawInstalled = clawResult.exitCode == 0;
      _nodeVersion = nodeCheck.raw;
      _clawVersion =
          _openclawInstalled ? (clawResult.stdout as String).trim() : '';
      _bundledAvailable = bundledAvailable;
      if (bundledVersions != null) {
        _bundledNodeVersion = bundledVersions['node'] ?? '';
        _bundledOpenClawVersion = bundledVersions['openclaw'] ?? '';
      }
      _detecting = false;
    });
  }

  Future<void> _runInstall(
    Future<Process> Function() starter,
    String name,
  ) async {
    setState(() {
      _installing = true;
      _logLines.clear();
      _logLines.add('>>> 开始安装 $name ...');
    });
    try {
      final exitCode = await InstallerService.runInstallWithCallback(starter, (
        line,
      ) {
        if (!mounted) return;
        setState(() => _logLines.add(line));
      });
      if (!mounted) return;
      if (exitCode == 0) {
        setState(() {
          _logLines.add('\n✓ $name 安装成功');
          _installing = false;
        });
        await _detect();
        // Auto-advance to next step after short delay
        if (mounted && _currentStep < 4) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) setState(() => _currentStep++);
        }
      } else {
        setState(() {
          _logLines.add('\n✗ 安装失败 (exit: $exitCode)');
          _logLines.add('提示：可尝试以管理员身份运行，或手动安装后点击"重新检测"');
          _installing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logLines.add('错误: $e');
        _installing = false;
      });
    }
  }

  /// Run bundled installation with progress streaming
  Future<void> _runBundledInstall({
    required bool isNode,
    required String name,
  }) async {
    setState(() {
      _installing = true;
      _logLines.clear();
      _logLines.add('>>> 开始离线安装 $name ...');
    });

    try {
      final stream =
          isNode
              ? InstallerService.tryBundledInstallNodeJs()
              : InstallerService.tryBundledInstallOpenClaw(
                mirrorUrl: _selectedMirror,
              );

      await for (final progress in stream) {
        if (!mounted) return;
        setState(() {
          final prefix =
              progress.percent >= 100
                  ? '✓'
                  : progress.percent > 0
                  ? '●'
                  : '○';
          _logLines.add('$prefix ${progress.step} (${progress.percent}%)');
        });
      }

      if (!mounted) return;
      setState(() {
        _logLines.add('\n✓ $name 安装成功');
        _installing = false;
      });
      await _detect();

      // Auto-advance to next step after short delay
      if (mounted && _currentStep < 4) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) setState(() => _currentStep++);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logLines.add('\n✗ 安装失败: $e');
        _logLines.add('提示：可尝试以管理员身份运行，或手动安装后点击"重新检测"');
        _installing = false;
      });
    }
  }

  /// Get the adjusted step index accounting for bundled installation
  int get _nodeStepIndex => _bundledAvailable ? 1 : 2;
  int get _openclawStepIndex => _bundledAvailable ? 2 : 3;
  int get _completeStepIndex => _bundledAvailable ? 3 : 4;
  int get _totalSteps => _bundledAvailable ? 4 : 5;

  // ==================== Android/Termux Auto-Configuration ====================

  Future<void> _runTermuxAutoConfig() async {
    setState(() {
      _termuxConfiguring = true;
      _termuxConfigLog.clear();
    });
    try {
      await for (final msg in TermuxBridge.autoConfigureTermux()) {
        if (!mounted) return;
        setState(() => _termuxConfigLog.add(msg));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _termuxConfigLog.add('错误: $e'));
    } finally {
      if (mounted) {
        setState(() => _termuxConfiguring = false);
        // Re-detect after auto-config
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) await _detect();
      }
    }
  }

  // ==================== Android/Termux Installation ====================

  Future<void> _runTermuxInstallNode() async {
    setState(() {
      _installing = true;
      _logLines.clear();
      _logLines.add('>>> 通过 Termux pkg 安装 Node.js ...');
    });
    try {
      final result = await TermuxBridge.installNode();
      if (!mounted) return;
      setState(() {
        _logLines.add(result.stdout.isNotEmpty ? result.stdout : '命令已发送到 Termux');
        if (result.stderr.isNotEmpty) _logLines.add(result.stderr);
        _logLines.add(result.isSuccess ? '\n✓ 安装命令已执行' : '\n✗ 安装失败');
        _logLines.add('请等待 Termux 完成安装后点击"重新检测"');
        _installing = false;
      });
      // Wait a bit then re-detect
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) await _detect();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logLines.add('错误: $e');
        _installing = false;
      });
    }
  }

  Future<void> _runTermuxInstallOpenClaw() async {
    setState(() {
      _installing = true;
      _logLines.clear();
      _logLines.add('>>> 通过 Termux npm 安装 OpenClaw ...');
    });
    try {
      final result = await TermuxBridge.installOpenClaw(
        mirrorUrl: _selectedMirror,
      );
      if (!mounted) return;
      setState(() {
        _logLines.add(result.stdout.isNotEmpty ? result.stdout : '命令已发送到 Termux');
        if (result.stderr.isNotEmpty) _logLines.add(result.stderr);
        _logLines.add(result.isSuccess ? '\n✓ 安装命令已执行' : '\n✗ 安装失败');
        _logLines.add('请等待 Termux 完成安装后点击"重新检测"');
        _installing = false;
      });
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) await _detect();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logLines.add('错误: $e');
        _installing = false;
      });
    }
  }

  /// Get status for each step
  StepStatus _getStepStatus(int step) {
    // Environment detection (always step 0)
    if (step == 0) {
      if (_detecting) return StepStatus.inProgress;
      return StepStatus.completed;
    }

    // Network mode (only when bundled not available)
    if (!_bundledAvailable && step == 1) {
      if (_currentStep < 1) return StepStatus.notStarted;
      if (_currentStep == 1) return StepStatus.inProgress;
      return StepStatus.completed;
    }

    // Node.js step
    final nodeStep = _nodeStepIndex;
    if (step == nodeStep) {
      if (_currentStep < nodeStep) return StepStatus.notStarted;
      if (_nodeInstalled) return StepStatus.completed;
      if (_currentStep == nodeStep) return StepStatus.inProgress;
      return StepStatus.notStarted;
    }

    // OpenClaw step
    final clawStep = _openclawStepIndex;
    if (step == clawStep) {
      if (_currentStep < clawStep) return StepStatus.notStarted;
      if (_openclawInstalled) return StepStatus.completed;
      if (_currentStep == clawStep) return StepStatus.inProgress;
      return StepStatus.notStarted;
    }

    // Complete step
    final completeStep = _completeStepIndex;
    if (step == completeStep) {
      if (_currentStep < completeStep) return StepStatus.notStarted;
      final allDone = _nodeInstalled && _openclawInstalled;
      return allDone ? StepStatus.completed : StepStatus.inProgress;
    }

    return StepStatus.notStarted;
  }

  /// Calculate overall progress percentage
  double get _overallProgress {
    final stepValue = 1.0 / _totalSteps;
    var progress = 0.0;
    // Step 0 (detection) is always "completed" after detection
    progress += stepValue;
    // Network step (only if not bundled)
    if (!_bundledAvailable) {
      if (_currentStep >= 1) progress += stepValue;
    }
    // Node.js step
    if (_currentStep >= _nodeStepIndex || _nodeInstalled) progress += stepValue;
    // OpenClaw step
    if (_currentStep >= _openclawStepIndex || _openclawInstalled) {
      progress += stepValue;
    }
    // Complete step
    if (_nodeInstalled && _openclawInstalled) progress += stepValue;
    return progress.clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with progress
          _buildHeader(),
          const SizedBox(height: 8),
          const Text(
            '跟随向导完成 OpenClaw 安装，整个过程约 5 分钟',
            style: TextStyle(color: CicadaColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Overall progress bar
          _buildOverallProgress(),
          const SizedBox(height: 32),

          // Steps visualization
          _buildStepsList(),
          const SizedBox(height: 32),

          // Current step content
          _buildCurrentStepContent(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Text(
          'SETUP WIZARD',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
          ),
        ),
        const Spacer(),
        if (_nodeInstalled && _openclawInstalled)
          Chip(
            label: const Text('环境就绪'),
            avatar: const Icon(
              Icons.check_circle,
              size: 16,
              color: CicadaColors.ok,
            ),
            backgroundColor: CicadaColors.ok.withAlpha(40),
            side: BorderSide.none,
          ),
      ],
    );
  }

  Widget _buildOverallProgress() {
    final progress = _overallProgress;
    final percent = (progress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CicadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '总进度',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: CicadaColors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: progress >= 1.0 ? CicadaColors.ok : CicadaColors.data,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: CicadaColors.border.withAlpha(50),
              valueColor: AlwaysStoppedAnimation(
                progress >= 1.0 ? CicadaColors.ok : CicadaColors.data,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepsList() {
    final steps = [
      _StepInfo('环境检测', '检测 Node.js 和 OpenClaw 安装状态', Icons.computer),
      if (!_bundledAvailable)
        _StepInfo('镜像选择', '选择 npm 镜像源', Icons.network_wifi),
      _StepInfo(
        'Node.js',
        _bundledAvailable ? '解压 Node.js 运行时' : '安装 Node.js 运行时',
        Icons.javascript,
      ),
      _StepInfo(
        'OpenClaw',
        _bundledAvailable ? '安装 OpenClaw CLI (离线)' : '安装 OpenClaw CLI 工具',
        Icons.terminal,
      ),
      _StepInfo('完成', '配置模型并开始使用', Icons.celebration),
    ];

    return Column(
      children:
          steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            final status = _getStepStatus(index);
            final isCurrent = _currentStep == index;

            return InkWell(
              onTap: () {
                // Allow clicking on completed steps or current step
                if (status != StepStatus.notStarted || index == 0) {
                  setState(() => _currentStep = index);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color:
                      isCurrent
                          ? CicadaColors.data.withAlpha(20)
                          : CicadaColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        isCurrent
                            ? CicadaColors.data
                            : status == StepStatus.completed
                            ? CicadaColors.ok.withAlpha(100)
                            : CicadaColors.border,
                    width: isCurrent ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Status indicator
                    _buildStepStatusIndicator(status, isCurrent),
                    const SizedBox(width: 16),
                    // Step info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color:
                                  isCurrent
                                      ? CicadaColors.data
                                      : status == StepStatus.completed
                                      ? CicadaColors.ok
                                      : CicadaColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            step.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  status == StepStatus.notStarted
                                      ? CicadaColors.textTertiary
                                      : CicadaColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Current indicator
                    if (isCurrent)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: CicadaColors.data.withAlpha(30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '当前',
                          style: TextStyle(
                            fontSize: 11,
                            color: CicadaColors.data,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildStepStatusIndicator(StepStatus status, bool isCurrent) {
    switch (status) {
      case StepStatus.completed:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: CicadaColors.ok.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check, color: CicadaColors.ok, size: 18),
        );
      case StepStatus.inProgress:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color:
                isCurrent
                    ? CicadaColors.data.withAlpha(30)
                    : Colors.orange.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child:
              isCurrent
                  ? const Icon(
                    Icons.arrow_forward,
                    color: CicadaColors.data,
                    size: 18,
                  )
                  : const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.orange,
                    ),
                  ),
        );
      case StepStatus.notStarted:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: CicadaColors.textTertiary.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.circle_outlined,
            color: CicadaColors.textTertiary.withAlpha(100),
            size: 18,
          ),
        );
    }
  }

  Widget _buildCurrentStepContent() {
    // When bundled is available, steps are: 0=detect, 1=node, 2=openclaw, 3=complete
    // When bundled is NOT available, steps are: 0=detect, 1=network, 2=node, 3=openclaw, 4=complete
    if (_currentStep == 0) return _buildDetectStep();
    if (_currentStep == _nodeStepIndex) return _buildInstallNodeStep();
    if (_currentStep == _openclawStepIndex) return _buildInstallClawStep();
    if (_currentStep == _completeStepIndex) return _buildCompleteStep();
    if (!_bundledAvailable && _currentStep == 1) return _buildNetworkStep();
    return const SizedBox.shrink();
  }

  Widget _buildDetectStep() {
    return _buildStepCard(
      title: '环境检测',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_detecting)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('正在检测环境...'),
                ],
              ),
            )
          else ...[
            // Android: show Termux status first
            if (PlatformInfo.needsTermux) ...[
              _buildCheckItem('Termux', _termuxInstalled, ''),
              const SizedBox(height: 12),
              if (!_termuxInstalled) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CicadaColors.alert.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CicadaColors.alert.withAlpha(100)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Android 需要 Termux 作为 Node.js 运行时',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: () => TermuxBridge.openUrl(
                          'https://f-droid.org/packages/com.termux/',
                        ),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('从 F-Droid 下载 Termux'),
                        style: FilledButton.styleFrom(backgroundColor: CicadaColors.data),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              // Termux installed: offer auto-configuration via accessibility
              if (_termuxInstalled) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: CicadaColors.data.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CicadaColors.data.withAlpha(100)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Termux 自动配置',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '通过无障碍服务自动配置 allow-external-apps，'
                        '免去手动操作',
                        style: TextStyle(
                          fontSize: 12,
                          color: CicadaColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: _termuxConfiguring ? null : _runTermuxAutoConfig,
                        icon: _termuxConfiguring
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.accessibility_new, size: 16),
                        label: Text(_termuxConfiguring ? '配置中...' : '一键配置 Termux'),
                        style: FilledButton.styleFrom(backgroundColor: CicadaColors.data),
                      ),
                      if (_termuxConfigLog.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: CicadaColors.surface,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(maxHeight: 120),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _termuxConfigLog.length,
                            itemBuilder: (context, index) => Text(
                              _termuxConfigLog[index],
                              style: const TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
            _buildCheckItem('Node.js', _nodeInstalled, _nodeVersion),
            const SizedBox(height: 12),
            _buildCheckItem('OpenClaw', _openclawInstalled, _clawVersion),
            const SizedBox(height: 20),
            // Show bundled info if available
            if (_bundledAvailable) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CicadaColors.data.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CicadaColors.data.withAlpha(100)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.offline_bolt,
                      color: CicadaColors.data,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '离线资源包可用',
                            style: TextStyle(
                              color: CicadaColors.data,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Node.js $_bundledNodeVersion + OpenClaw $_bundledOpenClawVersion',
                            style: TextStyle(
                              fontSize: 12,
                              color: CicadaColors.data.withAlpha(180),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_nodeInstalled && _openclawInstalled)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CicadaColors.ok.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CicadaColors.ok.withAlpha(100)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: CicadaColors.ok, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '所有依赖已就绪，可直接跳到最后一步',
                        style: TextStyle(color: CicadaColors.ok),
                      ),
                    ),
                  ],
                ),
              )
            else
              OutlinedButton.icon(
                onPressed: _detect,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('重新检测'),
              ),
          ],
          const SizedBox(height: 16),
          _buildStepNavigation(canContinue: !_detecting),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String name, bool installed, String version) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            installed
                ? CicadaColors.ok.withAlpha(10)
                : CicadaColors.alert.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              installed
                  ? CicadaColors.ok.withAlpha(50)
                  : CicadaColors.alert.withAlpha(50),
        ),
      ),
      child: Row(
        children: [
          Icon(
            installed ? Icons.check_circle : Icons.error_outline,
            color: installed ? CicadaColors.ok : CicadaColors.alert,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  installed ? '已安装' : '未安装',
                  style: TextStyle(
                    fontSize: 12,
                    color: installed ? CicadaColors.ok : CicadaColors.alert,
                  ),
                ),
              ],
            ),
          ),
          if (version.isNotEmpty)
            Text(
              version,
              style: TextStyle(fontSize: 12, color: CicadaColors.textSecondary),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkStep() {
    return _buildStepCard(
      title: '镜像选择',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('包管理镜像源:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: CicadaColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CicadaColors.border),
            ),
            child: RadioGroup<String>(
              groupValue: _selectedMirror,
              onChanged:
                  (v) => setState(() => _selectedMirror = v ?? _selectedMirror),
              child: Column(
                children:
                    {
                          '淘宝镜像（推荐）': 'https://registry.npmmirror.com',
                          '腾讯镜像': 'https://mirrors.cloud.tencent.com/npm/',
                          '华为镜像':
                              'https://repo.huaweicloud.com/repository/npm/',
                          '中科大镜像': 'https://npmreg.proxy.ustclug.org/',
                          '官方源（海外用户）': 'https://registry.npmjs.org',
                        }.entries
                        .map(
                          (e) => RadioListTile<String>(
                            title: Text(e.key),
                            subtitle: Text(
                              e.value,
                              style: TextStyle(
                                fontSize: 11,
                                color: CicadaColors.textTertiary,
                              ),
                            ),
                            value: e.value,
                            dense: true,
                          ),
                        )
                        .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildStepNavigation(),
        ],
      ),
    );
  }

  Widget _buildInstallNodeStep() {
    final isBundled = _bundledAvailable;
    final isAndroid = PlatformInfo.needsTermux;
    return _buildStepCard(
      title: isAndroid ? '安装 Node.js (Termux)' : (isBundled ? '解压 Node.js' : '安装 Node.js'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_nodeInstalled)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CicadaColors.ok.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CicadaColors.ok),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: CicadaColors.ok),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Node.js 已安装 ($_nodeVersion)，跳过此步骤',
                      style: const TextStyle(color: CicadaColors.ok),
                    ),
                  ),
                ],
              ),
            )
          else ...[
            if (isAndroid) ...[
              const Text('将通过 Termux 的 pkg 安装 Node.js'),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _installing ? null : () => _runTermuxInstallNode(),
                    icon: _installing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download),
                    label: Text(_installing ? '安装中...' : '安装 Node.js'),
                    style: FilledButton.styleFrom(backgroundColor: CicadaColors.data),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _installing ? null : _detect,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('重新检测'),
                  ),
                ],
              ),
            ] else if (isBundled) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CicadaColors.data.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CicadaColors.data.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.offline_bolt,
                      color: CicadaColors.data,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '将从本地资源包解压 Node.js $_bundledNodeVersion',
                        style: TextStyle(color: CicadaColors.data),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              const Text('将通过 winget/npm 自动安装 Node.js LTS 版本'),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed:
                      _installing
                          ? null
                          : () =>
                              isBundled
                                  ? _runBundledInstall(
                                    isNode: true,
                                    name: 'Node.js',
                                  )
                                  : _runInstall(
                                    () => InstallerService.installNodejs(),
                                    'Node.js',
                                  ),
                  icon:
                      _installing
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Icon(isBundled ? Icons.folder_zip : Icons.download),
                  label: Text(
                    _installing
                        ? (isBundled ? '解压中...' : '安装中...')
                        : (isBundled ? '解压 Node.js' : '安装 Node.js'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: CicadaColors.data,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _installing ? null : _detect,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('已手动安装？重新检测'),
                ),
              ],
            ),
          ],
          if (_logLines.isNotEmpty) ...[
            const SizedBox(height: 16),
            TerminalOutput(lines: _logLines),
          ],
          const SizedBox(height: 16),
          _buildStepNavigation(
            canContinue: _nodeInstalled,
            continueText: _nodeInstalled ? '下一步' : '跳过',
          ),
        ],
      ),
    );
  }

  Widget _buildInstallClawStep() {
    final isBundled = _bundledAvailable;
    final isAndroid = PlatformInfo.needsTermux;
    return _buildStepCard(
      title: isAndroid ? '安装 OpenClaw (Termux)' : (isBundled ? '安装 OpenClaw (离线)' : '安装 OpenClaw'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_openclawInstalled)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CicadaColors.ok.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: CicadaColors.ok),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: CicadaColors.ok),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'OpenClaw 已安装 ($_clawVersion)，跳过此步骤',
                      style: const TextStyle(color: CicadaColors.ok),
                    ),
                  ),
                ],
              ),
            )
          else if (!_nodeInstalled)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.orange),
                  SizedBox(width: 12),
                  Text('请先安装 Node.js'),
                ],
              ),
            )
          else ...[
            if (isAndroid) ...[
              const Text('将通过 Termux 的 npm 全局安装 OpenClaw'),
              const SizedBox(height: 16),
              Row(
                children: [
                  FilledButton.icon(
                    onPressed: _installing ? null : () => _runTermuxInstallOpenClaw(),
                    icon: _installing
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.download),
                    label: Text(_installing ? '安装中...' : '安装 OpenClaw'),
                    style: FilledButton.styleFrom(backgroundColor: CicadaColors.data),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _installing ? null : _detect,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('重新检测'),
                  ),
                ],
              ),
            ] else if (isBundled)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CicadaColors.data.withAlpha(10),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CicadaColors.data.withAlpha(50)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.offline_bolt,
                      color: CicadaColors.data,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '将从本地资源包安装 OpenClaw $_bundledOpenClawVersion',
                        style: TextStyle(color: CicadaColors.data),
                      ),
                    ),
                  ],
                ),
              )
            else
              Text(
                '将通过 npm 安装 OpenClaw（使用 ${_selectedMirror.split("/").lastWhere((s) => s.isNotEmpty, orElse: () => _selectedMirror)} 镜像）',
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed:
                      _installing
                          ? null
                          : () =>
                              isBundled
                                  ? _runBundledInstall(
                                    isNode: false,
                                    name: 'OpenClaw',
                                  )
                                  : _runInstall(
                                    () => InstallerService.installOpenClaw(
                                      mirrorUrl: _selectedMirror,
                                    ),
                                    'OpenClaw',
                                  ),
                  icon:
                      _installing
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                          : Icon(isBundled ? Icons.folder_zip : Icons.download),
                  label: Text(
                    _installing
                        ? '安装中...'
                        : (isBundled ? '离线安装 OpenClaw' : '安装 OpenClaw'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: CicadaColors.data,
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _installing ? null : _detect,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('重新检测'),
                ),
              ],
            ),
          ],
          if (_logLines.isNotEmpty) ...[
            const SizedBox(height: 16),
            TerminalOutput(lines: _logLines),
          ],
          const SizedBox(height: 16),
          _buildStepNavigation(
            canContinue: _openclawInstalled,
            continueText: _openclawInstalled ? '下一步' : '跳过',
          ),
        ],
      ),
    );
  }

  Widget _buildCompleteStep() {
    final allDone = _nodeInstalled && _openclawInstalled;
    return _buildStepCard(
      title: '完成',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  allDone
                      ? CicadaColors.ok.withAlpha(20)
                      : Colors.orange.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: allDone ? CicadaColors.ok : Colors.orange,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  allDone ? Icons.celebration : Icons.warning_amber,
                  size: 48,
                  color: allDone ? CicadaColors.ok : Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  allDone ? '环境准备就绪！' : '部分组件尚未安装',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                if (allDone) ...[
                  const Text('接下来请前往「模型配置」页面，配置至少一个 AI 模型提供商。'),
                  const SizedBox(height: 8),
                  const Text(
                    '推荐：智谱 GLM-4 Flash（完全免费）',
                    style: TextStyle(
                      color: CicadaColors.ok,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ] else
                  const Text('请返回完成 Node.js 和 OpenClaw 的安装。'),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (allDone && widget.onSetupComplete != null)
            Center(
              child: FilledButton.icon(
                onPressed: widget.onSetupComplete,
                icon: const Icon(Icons.arrow_forward),
                label: const Text('前往模型配置'),
                style: FilledButton.styleFrom(
                  backgroundColor: CicadaColors.ok,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CicadaColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CicadaColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildStepNavigation({
    bool canContinue = true,
    String continueText = '下一步',
  }) {
    return Row(
      children: [
        if (_currentStep > 0)
          OutlinedButton.icon(
            onPressed: () => setState(() => _currentStep--),
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('上一步'),
          ),
        const Spacer(),
        if (_currentStep < _completeStepIndex)
          FilledButton.icon(
            onPressed:
                canContinue ? () => setState(() => _currentStep++) : null,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text(continueText),
            style: FilledButton.styleFrom(backgroundColor: CicadaColors.data),
          ),
      ],
    );
  }
}

class _StepInfo {
  final String title;
  final String subtitle;
  final IconData icon;

  _StepInfo(this.title, this.subtitle, this.icon);
}
