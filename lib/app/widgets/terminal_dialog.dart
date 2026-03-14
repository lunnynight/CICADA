import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/cicada_colors.dart';

/// Tactical terminal overlay dialog for long-running operations.
/// Shows streaming output with blur backdrop, auto-scrolls to bottom.
class TerminalDialog extends StatefulWidget {
  final String title;
  final List<String> lines;
  final bool running;
  final VoidCallback? onClose;

  const TerminalDialog({
    super.key,
    required this.title,
    required this.lines,
    this.running = true,
    this.onClose,
  });

  /// Show as a modal dialog over the current page.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required ValueNotifier<List<String>> lines,
    required ValueNotifier<bool> running,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      builder: (_) => ValueListenableBuilder<bool>(
        valueListenable: running,
        builder: (_, isRunning, __) => ValueListenableBuilder<List<String>>(
          valueListenable: lines,
          builder: (_, currentLines, __) => TerminalDialog(
            title: title,
            lines: currentLines,
            running: isRunning,
            onClose: isRunning ? null : () => Navigator.of(context).pop(),
          ),
        ),
      ),
    );
  }

  @override
  State<TerminalDialog> createState() => _TerminalDialogState();
}

class _TerminalDialogState extends State<TerminalDialog> {
  final ScrollController _scroll = ScrollController();

  @override
  void didUpdateWidget(TerminalDialog old) {
    super.didUpdateWidget(old);
    if (widget.lines.length != old.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Blur backdrop
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withValues(alpha: 0.4)),
          ),
        ),
        // Terminal panel
        Center(
          child: Container(
            width: 640,
            height: 420,
            decoration: BoxDecoration(
              color: CicadaColors.background.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CicadaColors.border),
            ),
            child: Column(
              children: [
                _buildTitleBar(),
                const Divider(height: 1, color: CicadaColors.border),
                Expanded(child: _buildOutput()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(width: 3, height: 14, color: CicadaColors.accent),
          const SizedBox(width: 10),
          Text(
            widget.title.toUpperCase(),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: CicadaColors.textPrimary,
            ),
          ),
          const Spacer(),
          if (widget.running)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: CicadaColors.energy,
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: CicadaColors.muted,
              onPressed: widget.onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ],
      ),
    );
  }

  Widget _buildOutput() {
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.all(14),
      itemCount: widget.lines.length,
      itemBuilder: (_, index) {
        final line = widget.lines[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 2),
          child: Text(
            line,
            style: TextStyle(
              fontFamily: 'Consolas',
              fontSize: 12,
              color: _lineColor(line),
            ),
          ),
        );
      },
    );
  }

  Color _lineColor(String line) {
    final lower = line.toLowerCase();
    if (lower.startsWith('错误') || lower.startsWith('error') || lower.contains('failed')) {
      return CicadaColors.alert;
    }
    if (lower.contains('成功') || lower.contains('完成') || lower.contains('ok')) {
      return CicadaColors.ok;
    }
    if (line.startsWith('➜') || line.startsWith('===')) {
      return CicadaColors.energy;
    }
    return CicadaColors.muted;
  }
}