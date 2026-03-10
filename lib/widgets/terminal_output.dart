import 'package:flutter/material.dart';

class TerminalOutput extends StatefulWidget {
  final List<String> lines;
  final double height;

  const TerminalOutput({
    super.key,
    required this.lines,
    this.height = 200,
  });

  @override
  State<TerminalOutput> createState() => _TerminalOutputState();
}

class _TerminalOutputState extends State<TerminalOutput> {
  final ScrollController _controller = ScrollController();

  @override
  void didUpdateWidget(TerminalOutput old) {
    super.didUpdateWidget(old);
    if (widget.lines.length != old.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_controller.hasClients) {
          _controller.animateTo(
            _controller.position.maxScrollExtent,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF30363D)),
      ),
      child: ListView.builder(
        controller: _controller,
        padding: const EdgeInsets.all(12),
        itemCount: widget.lines.length,
        itemBuilder: (context, index) {
          final line = widget.lines[index];
          final isError = line.startsWith('错误') || line.startsWith('Error');
          final isDone = line.contains('安装完成') || line.contains('成功');
          return Text(
            line,
            style: TextStyle(
              fontFamily: 'Consolas',
              fontSize: 12,
              color: isError
                  ? const Color(0xFFFF7B72)
                  : isDone
                      ? const Color(0xFF7EE787)
                      : const Color(0xFF8B949E),
            ),
          );
        },
      ),
    );
  }
}
