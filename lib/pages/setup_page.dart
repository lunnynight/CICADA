import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/installer_service.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

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
  final ScrollController _logScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _detect();
  }

  @override
  void dispose() {
    _logScroll.dispose();
    super.dispose();
  }

  Future<void> _detect() async {
    setState(() => _detecting = true);
    final nodeResult = await InstallerService.checkNode();
    final clawResult = await InstallerService.checkOpenClaw();
    if (!mounted) return;
    setState(() {
      _nodeInstalled = nodeResult.exitCode == 0;
      _openclawInstalled = clawResult.exitCode == 0;
      _detecting = false;
    });
  }

  Future<void> _runInstall(Future<Process> Function() starter) async {
    setState(() {
      _installing = true;
      _logLines.clear();
    });
    try {
      final process = await starter();
      process.stdout.transform(const SystemEncoding().decoder).listen((data) {
        if (!mounted) return;
        setState(() => _logLines.add(data));
        _scrollToBottom();
      });
      process.stderr.transform(const SystemEncoding().decoder).listen((data) {
        if (!mounted) return;
        setState(() => _logLines.add(data));
        _scrollToBottom();
      });
      final exitCode = await process.exitCode;
      if (!mounted) return;
      setState(() {
        _logLines.add(exitCode == 0 ? '\n--- 安装完成 ---' : '\n--- 安装失败 (exit: $exitCode) ---');
        _installing = false;
      });
      if (exitCode == 0) await _detect();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _logLines.add('错误: $e');
        _installing = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_logScroll.hasClients) {
        _logScroll.animateTo(
          _logScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '安装向导',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Stepper(
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 4) setState(() => _currentStep++);
            },
            onStepCancel: () {
              if (_currentStep > 0) setState(() => _currentStep--);
            },
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    if (details.currentStep < 4)
                      FilledButton(
                        onPressed: details.onStepContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                        ),
                        child: const Text('下一步'),
                      ),
                    if (details.currentStep > 0) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('上一步'),
                      ),
                    ],
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('环境检测'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: _buildDetectStep(),
              ),
              Step(
                title: const Text('网络模式'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: _buildNetworkStep(),
              ),
              Step(
                title: const Text('安装 Node.js'),
                isActive: _currentStep >= 2,
                state: _nodeInstalled ? StepState.complete : StepState.indexed,
                content: _buildInstallNodeStep(),
              ),
              Step(
                title: const Text('安装 OpenClaw'),
                isActive: _currentStep >= 3,
                state: _openclawInstalled ? StepState.complete : StepState.indexed,
                content: _buildInstallClawStep(),
              ),
              Step(
                title: const Text('完成'),
                isActive: _currentStep >= 4,
                content: _buildCompleteStep(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetectStep() {
    if (_detecting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 12),
            Text('正在检测环境...'),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _checkRow('Node.js', _nodeInstalled),
        const SizedBox(height: 8),
        _checkRow('OpenClaw', _openclawInstalled),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _detect,
          icon: const Icon(Icons.refresh, size: 16),
          label: const Text('重新检测'),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFF30363D)),
          ),
        ),
      ],
    );
  }

  Widget _checkRow(String name, bool ok) {
    return Row(
      children: [
        Icon(ok ? Icons.check_circle : Icons.cancel, color: ok ? Colors.green : Colors.red, size: 20),
        const SizedBox(width: 8),
        Text('$name: ${ok ? "已安装" : "未安装"}'),
      ],
    );
  }

  Widget _buildNetworkStep() {
    return Column(
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
          const SizedBox(height: 12),
          const Text('NPM 镜像源:', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          RadioGroup<String>(
            groupValue: _selectedMirror,
            onChanged: (v) => setState(() => _selectedMirror = v ?? _selectedMirror),
            child: Column(
              children: {
                '淘宝镜像': 'https://registry.npmmirror.com',
                '腾讯镜像': 'https://mirrors.cloud.tencent.com/npm/',
                '华为镜像': 'https://repo.huaweicloud.com/repository/npm/',
              }.entries.map(
                (e) => RadioListTile<String>(
                  title: Text(e.key),
                  subtitle: Text(e.value, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                  value: e.value,
                  dense: true,
                ),
              ).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildInstallNodeStep() {
    if (_nodeInstalled) {
      return const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Node.js 已安装，跳过此步骤'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: _installing
              ? null
              : () => _runInstall(() => InstallerService.installNodejs()),
          icon: _installing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.download),
          label: Text(_installing ? '安装中...' : '安装 Node.js'),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
        ),
        if (_logLines.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTerminal(),
        ],
      ],
    );
  }

  Widget _buildInstallClawStep() {
    if (_openclawInstalled) {
      return const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('OpenClaw 已安装，跳过此步骤'),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FilledButton.icon(
          onPressed: _installing
              ? null
              : () => _runInstall(
                  () => InstallerService.installOpenClaw(mirrorUrl: _online ? _selectedMirror : null),
                ),
          icon: _installing
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.download),
          label: Text(_installing ? '安装中...' : '安装 OpenClaw'),
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7C3AED)),
        ),
        if (_logLines.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildTerminal(),
        ],
      ],
    );
  }

  Widget _buildTerminal() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: ListView.builder(
        controller: _logScroll,
        padding: const EdgeInsets.all(12),
        itemCount: _logLines.length,
        itemBuilder: (context, index) {
          return Text(
            _logLines[index],
            style: const TextStyle(
              fontFamily: 'Consolas',
              fontSize: 12,
              color: Color(0xFF8B949E),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompleteStep() {
    final allDone = _nodeInstalled && _openclawInstalled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          allDone ? Icons.celebration : Icons.warning_amber,
          size: 48,
          color: allDone ? Colors.amber : Colors.orange,
        ),
        const SizedBox(height: 16),
        Text(
          allDone ? '环境准备就绪！' : '部分组件尚未安装，请返回完成安装。',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        if (allDone) ...[
          const SizedBox(height: 8),
          const Text('接下来请前往「模型配置」页面，配置至少一个 AI 模型提供商。'),
        ],
      ],
    );
  }
}
