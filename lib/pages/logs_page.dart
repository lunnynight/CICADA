import 'dart:async';
import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../app/widgets/hud_panel.dart';
import '../services/gateway_service.dart';

class LogsPage extends StatefulWidget {
  const LogsPage({super.key});

  @override
  State<LogsPage> createState() => _LogsPageState();
}

class _LogsPageState extends State<LogsPage> {
  final List<LogEntry> _logs = [];
  final ScrollController _scrollController = ScrollController();
  bool _autoScroll = true;
  bool _isStreaming = false;
  StreamSubscription? _logSub;

  @override
  void initState() {
    super.initState();
    _loadInitialLogs();
    _startStreaming();
  }

  @override
  void dispose() {
    _logSub?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialLogs() async {
    final logs = await GatewayService.getLogs(lines: 100);
    if (!mounted) return;
    setState(() {
      _logs.addAll(logs);
    });
  }

  void _startStreaming() {
    setState(() => _isStreaming = true);
    _logSub = GatewayService.streamLogs().listen(
      (entry) {
        setState(() => _logs.add(entry));
        if (_autoScroll && _scrollController.hasClients) {
          _scrollToBottom();
        }
      },
      onError: (_) {
        setState(() => _isStreaming = false);
      },
      onDone: () {
        setState(() => _isStreaming = false);
      },
    );
  }

  void _stopStreaming() {
    _logSub?.cancel();
    setState(() => _isStreaming = false);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: HudPanel(
              title: 'GATEWAY LOGS',
              titleIcon: Icons.terminal,
              accent: CicadaColors.muted,
              child: _buildLogContent(),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Row(
        children: [
          const Text(
            'LOGS',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: CicadaColors.textPrimary,
            ),
          ),
          const SizedBox(width: 12),
          _StatusIndicator(
            isActive: _isStreaming,
            activeText: 'LIVE',
            inactiveText: 'PAUSED',
          ),
          const Spacer(),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () => setState(() => _autoScroll = !_autoScroll),
          icon: Icon(
            _autoScroll ? Icons.check_box : Icons.check_box_outline_blank,
            size: 16,
            color: CicadaColors.textSecondary,
          ),
          label: Text(
            'Auto-scroll',
            style: TextStyle(color: CicadaColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _isStreaming ? _stopStreaming : _startStreaming,
          icon: Icon(
            _isStreaming ? Icons.pause : Icons.play_arrow,
            color: CicadaColors.data,
          ),
          tooltip: _isStreaming ? 'Pause' : 'Resume',
        ),
        IconButton(
          onPressed: () => setState(() => _logs.clear()),
          icon: const Icon(Icons.clear, color: CicadaColors.muted),
          tooltip: 'Clear',
        ),
      ],
    );
  }

  Widget _buildLogContent() {
    if (_logs.isEmpty) {
      return Center(
        child: Text(
          'No logs available',
          style: TextStyle(color: CicadaColors.textTertiary),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: _logs.length,
      itemBuilder: (context, index) => _buildLogLine(_logs[index]),
    );
  }

  Widget _buildLogLine(LogEntry log) {
    final levelColor = _getLevelColor(log.level);

    final timeStr =
        '${log.timestamp.hour.toString().padLeft(2, '0')}:${log.timestamp.minute.toString().padLeft(2, '0')}:${log.timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: CicadaColors.border.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              timeStr,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                color: CicadaColors.textTertiary,
              ),
            ),
          ),
          Container(
            width: 50,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: levelColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: Text(
              log.level.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: levelColor,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              log.message,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: CicadaColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor(String level) {
    return switch (level.toLowerCase()) {
      'error' || 'fatal' => CicadaColors.alert,
      'warn' || 'warning' => Colors.orange,
      'debug' => CicadaColors.data,
      'trace' => CicadaColors.textTertiary,
      _ => CicadaColors.ok,
    };
  }
}

class _StatusIndicator extends StatelessWidget {
  final bool isActive;
  final String activeText;
  final String inactiveText;

  const _StatusIndicator({
    required this.isActive,
    required this.activeText,
    required this.inactiveText,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? CicadaColors.ok : CicadaColors.alert;
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          isActive ? activeText : inactiveText,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
