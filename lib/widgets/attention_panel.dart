import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../models/dashboard_stats.dart';

/// Attention panel for dashboard alerts
class AttentionPanel extends StatelessWidget {
  final List<AttentionItem> items;

  const AttentionPanel({
    super.key,
    required this.items,
  });

  Color _getLevelColor(AttentionLevel level) {
    switch (level) {
      case AttentionLevel.info:
        return CicadaColors.energy;
      case AttentionLevel.warning:
        return CicadaColors.warning;
      case AttentionLevel.error:
        return CicadaColors.error;
    }
  }

  IconData _getLevelIcon(AttentionLevel level) {
    switch (level) {
      case AttentionLevel.info:
        return Icons.check_circle_outline;
      case AttentionLevel.warning:
        return Icons.warning_amber_outlined;
      case AttentionLevel.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

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
          const Text(
            '需要注意',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CicadaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _getLevelIcon(item.level),
                      size: 20,
                      color: _getLevelColor(item.level),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.message,
                        style: TextStyle(
                          fontSize: 14,
                          color: _getLevelColor(item.level),
                        ),
                      ),
                    ),
                    if (item.actionLabel != null && item.onAction != null) ...[
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: item.onAction,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          item.actionLabel!,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
