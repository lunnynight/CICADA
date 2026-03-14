import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../services/installer_service.dart';
import '../widgets/terminal_output.dart';

/// Step status for three-state visualization
enum StepStatus {
  notStarted, // 未开始 - 灰色
  inProgress, // 进行中 - 蓝色/橙色
  completed,  // 已完成 - 绿色
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
  bool _online = true;
  String _selectedMirror = 'https://registry.npmmirror.com';
  final List<String> _logLines = [];
  String _nodeVersion = '';
  String _clawVersion = '';

  @override
  void initState() {
    super.initState();
    _detect();
  }

  Future<void> _detect() async {
    setState(() => _detecting = true);
    final nodeResult = await InstallerService.checkNode();
    final clawResult = await InstallerService.checkOpenClaw();
    if (!mounted) return;
    setState(() {
      _nodeInstalled = nodeResult.exitCode == 0;
      _openclawInstalled = clawResult.exitCode == 0;
      _nodeVersion = _nodeInstalled ? (nodeResult.stdout as String).trim() : '';
      _clawVersion = _openclawInstalled ? (clawResult.stdout as String).trim() : '';
      _detecting = false;
    });
  }

  Future<void> _runInstall(Future<Process> Function() starter, String name) async {
    setState(() {
      _installing = true;
      _logLines.clear();
      _logLines.add('>>> 开始安装 $name ...');
    });
    try {
      final exitCode = await InstallerService.runInstallWithCallback(
        starter,
        (line) {
          if (!mounted) return;
          setState(() => _logLines.add(line));
        },
      );
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

  /// Get status for each step
  StepStatus _getStepStatus(int step) {
    switch (step) {
      case 0: // Environment detection
        if (_detecting) return StepStatus.inProgress;
        return StepStatus.completed;
      case 1: // Network mode
        if (_currentStep < 1) return StepStatus.notStarted;
        if (_currentStep == 1) return StepStatus.inProgress;
        return StepStatus.completed;
      case 2: // Node.js
        if (_currentStep < 2) return StepStatus.notStarted;
        if (_nodeInstalled) return StepStatus.completed;
        if (_currentStep == 2) return StepStatus.inProgress;
        return StepStatus.notStarted;
      case 3: // OpenClaw
        if (_currentStep < 3) return StepStatus.notStarted;
        if (_openclawInstalled) return StepStatus.completed;
        if (_currentStep == 3) return StepStatus.inProgress;
        return StepStatus.notStarted;
      case 4: // Complete
        if (_currentStep < 4) return StepStatus.notStarted;
        final allDone = _nodeInstalled && _openclawInstalled;
        return allDone ? StepStatus.completed : StepStatus.inProgress;
      default:
        return StepStatus.notStarted;
    }
  }

  /// Calculate overall progress percentage
  double get _overallProgress {
    var progress = 0.0;
    // Step 0 is always "completed" after detection
    progress += 0.2;
    // Step 1 (network)
    if (_currentStep >= 1) progress += 0.2;
    // Step 2 (nodejs)
    if (_currentStep >= 2 || _nodeInstalled) progress += 0.2;
    // Step 3 (openclaw)
    if (_currentStep >= 3 || _openclawInstalled) progress += 0.2;
    // Step 4 (complete)
    if (_nodeInstalled && _openclawInstalled) progress += 0.2;
    return progress;
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
            avatar: const Icon(Icons.check_circle, size: 16, color: CicadaColors.ok),
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
      _StepInfo('网络模式', '选择在线或离线安装', Icons.network_wifi),
      _StepInfo('Node.js', '安装 Node.js 运行时', Icons.javascript),
      _StepInfo('OpenClaw', '安装 OpenClaw CLI 工具', Icons.terminal),
      _StepInfo('完成', '配置模型并开始使用', Icons.celebration),
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
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
              color: isCurrent ? CicadaColors.data.withAlpha(20) : CicadaColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent
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
                          color: isCurrent
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
                          color: status == StepStatus.notStarted
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
          child: const Icon(
            Icons.check,
            color: CicadaColors.ok,
            size: 18,
          ),
        );
      case StepStatus.inProgress:
        return Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCurrent
                ? CicadaColors.data.withAlpha(30)
                : Colors.orange.withAlpha(30),
            shape: BoxShape.circle,
          ),
          child: isCurrent
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
    switch (_currentStep) {
      case 0:
        return _buildDetectStep();
      case 1:
        return _buildNetworkStep();
      case 2:
        return _buildInstallNodeStep();
      case 3:
        return _buildInstallClawStep();
      case 4:
        return _buildCompleteStep();
      default:
        return const SizedBox.shrink();
    }
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
            _buildCheckItem('Node.js', _nodeInstalled, _nodeVersion),
            const SizedBox(height: 12),
            _buildCheckItem('OpenClaw', _openclawInstalled, _clawVersion),
            const SizedBox(height: 20),
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
        color: installed
            ? CicadaColors.ok.withAlpha(10)
            : CicadaColors.alert.withAlpha(10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: installed
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
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  installed ? '已安装' : '未安装',
                  style: TextStyle(
                    fontSize: 12,
                    color: installed
                        ? CicadaColors.ok
                        : CicadaColors.alert,
                  ),
                ),
              ],
            ),
          ),
          if (version.isNotEmpty)
            Text(
              version,
              style: TextStyle(
                fontSize: 12,
                color: CicadaColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNetworkStep() {
    return _buildStepCard(
      title: '网络模式',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RadioGroup<bool>(
            groupValue: _online,
            onChanged: (v) => setState(() => _online = v ?? true),
            child: Column(
              children: [
                RadioListTile<bool>(
                  title: const Text('在线模式（推荐）'),
                  subtitle: const Text('从互联网下载安装'),
                  value: true,
                ),
                RadioListTile<bool>(
                  title: const Text('离线模式'),
                  subtitle: const Text('使用本地安装包'),
                  value: false,
                ),
              ],
            ),
          ),
          if (_online) ...[
            const SizedBox(height: 16),
            const Text(
              '包管理镜像源:',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
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
                onChanged: (v) => setState(() => _selectedMirror = v ?? _selectedMirror),
                child: Column(
                  children: {
                    '淘宝镜像（推荐）': 'https://registry.npmmirror.com',
                    '腾讯镜像': 'https://mirrors.cloud.tencent.com/npm/',
                    '华为镜像': 'https://repo.huaweicloud.com/repository/npm/',
                    '中科大镜像': 'https://npmreg.proxy.ustclug.org/',
                    '官方源（海外用户）': 'https://registry.npmjs.org',
                  }.entries.map(
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
                  ).toList(),
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildStepNavigation(),
        ],
      ),
    );
  }

  Widget _buildInstallNodeStep() {
    return _buildStepCard(
      title: '安装 Node.js',
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
            const Text('将通过 winget/npm 自动安装 Node.js LTS 版本'),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _installing
                      ? null
                      : () => _runInstall(
                            () => InstallerService.installNodejs(),
                            'Node.js',
                          ),
                  icon: _installing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(_installing ? '安装中...' : '安装 Node.js'),
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
    return _buildStepCard(
      title: '安装 OpenClaw',
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
            Text(
              '将通过 npm 安装 OpenClaw${_online ? "（使用 ${_selectedMirror.split("/").lastWhere((s) => s.isNotEmpty, orElse: () => _selectedMirror)} 镜像）" : ""}',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: _installing
                      ? null
                      : () => _runInstall(
                            () => InstallerService.installOpenClaw(
                              mirrorUrl: _online ? _selectedMirror : null,
                            ),
                            'OpenClaw',
                          ),
                  icon: _installing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.download),
                  label: Text(_installing ? '安装中...' : '安装 OpenClaw'),
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
              color: allDone
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
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
        if (_currentStep < 4)
          FilledButton.icon(
            onPressed: canContinue ? () => setState(() => _currentStep++) : null,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: Text(continueText),
            style: FilledButton.styleFrom(
              backgroundColor: CicadaColors.data,
            ),
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
