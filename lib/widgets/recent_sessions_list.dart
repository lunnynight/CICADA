import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../models/dashboard_stats.dart';

/// Recent sessions list for dashboard
class RecentSessionsList extends StatelessWidget {
  final List<RecentSession> sessions;
  final void Function(String sessionKey)? onSessionTap;

  const RecentSessionsList({
    super.key,
    required this.sessions,
    this.onSessionTap,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CicadaColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: CicadaColors.border),
        ),
        child: const Center(
          child: Text(
            '暂无最近对话',
            style: TextStyle(
              fontSize: 14,
              color: CicadaColors.textSecondary,
            ),
          ),
        ),
      );
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
            '最近对话',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: CicadaColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...sessions.map((session) => InkWell(
                onTap: onSessionTap != null
                    ? () => onSessionTap!(session.sessionKey)
                    : null,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 16,
                        color: CicadaColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          session.title,
                          style: const TextStyle(
                            fontSize: 14,
                            color: CicadaColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        session.timeAgo,
                        style: const TextStyle(
                          fontSize: 12,
                          color: CicadaColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
