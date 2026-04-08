import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme/cicada_colors.dart';
import '../app/widgets/hud_panel.dart';
import '../providers/gateway_provider.dart';
import '../services/gateway_service.dart';

/// Sessions tab for GatewayPage — shows active session list with auto-refresh.
class GatewaySessionsTab extends ConsumerStatefulWidget {
  const GatewaySessionsTab({super.key});

  @override
  ConsumerState<GatewaySessionsTab> createState() =>
      _GatewaySessionsTabState();
}

class _GatewaySessionsTabState extends ConsumerState<GatewaySessionsTab> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => ref.invalidate(gatewaySessionsProvider),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(gatewaySessionsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.refresh, color: CicadaColors.muted),
              onPressed: () => ref.invalidate(gatewaySessionsProvider),
              tooltip: '刷新',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: sessionsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('加载失败: $e',
                  style: const TextStyle(color: CicadaColors.alert)),
            ),
            data: (sessions) => sessions.isEmpty
                ? _buildEmptyState()
                : _buildSessionsList(sessions),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, size: 64, color: CicadaColors.textTertiary),
          const SizedBox(height: 16),
          const Text(
            'No Active Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CicadaColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a conversation to create a session',
            style: TextStyle(color: CicadaColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(List<Session> sessions) {
    return ListView.builder(
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: HudPanel(
            title:
                'SESSION // ${session.id.substring(0, 8).toUpperCase()}',
            titleIcon: Icons.chat_bubble,
            accent: CicadaColors.data,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _infoRow('Recipient',
                          session.recipient ?? 'Unknown'),
                      const SizedBox(height: 8),
                      _infoRow(
                          'Channel', session.channel ?? 'Direct'),
                      const SizedBox(height: 8),
                      _infoRow('Messages',
                          session.messageCount.toString()),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Last Activity',
                      style: TextStyle(
                        fontSize: 11,
                        color: CicadaColors.textTertiary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(session.lastActivity),
                      style: const TextStyle(
                        fontSize: 13,
                        color: CicadaColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 12, color: CicadaColors.textTertiary),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: CicadaColors.textPrimary,
          ),
        ),
      ],
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}
