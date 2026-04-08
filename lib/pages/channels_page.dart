import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme/cicada_colors.dart';
import '../app/widgets/hud_panel.dart';
import '../providers/page_data_provider.dart';
import '../services/gateway_service.dart';

class ChannelsPage extends ConsumerStatefulWidget {
  const ChannelsPage({super.key});

  @override
  ConsumerState<ChannelsPage> createState() => _ChannelsPageState();
}

class _ChannelsPageState extends ConsumerState<ChannelsPage> {
  bool _loggingIn = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => ref.invalidate(channelsProvider),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loginToChannel(String channel) async {
    setState(() => _loggingIn = true);
    try {
      final success = await GatewayService.channelLogin(channel, verbose: true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Connected to $channel'
                  : 'Failed to connect to $channel',
            ),
            backgroundColor: success ? CicadaColors.ok : CicadaColors.alert,
          ),
        );
        if (success) {
          ref.invalidate(channelsProvider);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _loggingIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final channelsAsync = ref.watch(channelsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PageHeader(
          title: 'CHANNELS',
          onRefresh: () => ref.invalidate(channelsProvider),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: channelsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('加载失败: $e')),
              data: (channels) => _buildChannelsList(channels),
            ),
          ),
        ),
      ],
    );
  }

  static const List<_ChannelConfig> _availableChannels = [
    _ChannelConfig('telegram', 'Telegram', Icons.telegram, 'Messaging'),
    _ChannelConfig('discord', 'Discord', Icons.discord, 'Messaging'),
    _ChannelConfig('whatsapp', 'WhatsApp', Icons.message, 'Messaging'),
    _ChannelConfig('slack', 'Slack', Icons.workspaces, 'Messaging'),
  ];

  Widget _buildChannelsList(List<Channel> channels) {
    return ListView.builder(
      itemCount: _availableChannels.length,
      itemBuilder:
          (context, index) => _buildChannelCard(_availableChannels[index], channels),
    );
  }

  Widget _buildChannelCard(_ChannelConfig config, List<Channel> channels) {
    final channel = channels.firstWhere(
      (c) => c.name.toLowerCase() == config.id,
      orElse:
          () => Channel(
            name: config.name,
            type: config.type,
            connected: false,
            status: 'Not configured',
          ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: HudPanel(
        title: config.name.toUpperCase(),
        titleIcon: config.icon,
        accent: channel.connected ? CicadaColors.ok : CicadaColors.muted,
        child: Row(
          children: [
            _buildStatusDot(channel.connected),
            const SizedBox(width: 16),
            Expanded(child: _buildChannelInfo(channel)),
            _buildChannelAction(channel, config.id),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDot(bool connected) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: connected ? CicadaColors.ok : CicadaColors.muted,
      ),
    );
  }

  Widget _buildChannelInfo(Channel channel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          channel.connected ? 'Connected' : 'Disconnected',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color:
                channel.connected
                    ? CicadaColors.ok
                    : CicadaColors.textSecondary,
          ),
        ),
        if (channel.status != null) ...[
          const SizedBox(height: 4),
          Text(
            channel.status!,
            style: TextStyle(fontSize: 12, color: CicadaColors.textTertiary),
          ),
        ],
      ],
    );
  }

  Widget _buildChannelAction(Channel channel, String channelId) {
    if (channel.connected) {
      return OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.settings, size: 16),
        label: const Text('Configure'),
        style: OutlinedButton.styleFrom(foregroundColor: CicadaColors.data),
      );
    }

    return ElevatedButton.icon(
      onPressed: _loggingIn ? null : () => _loginToChannel(channelId),
      icon:
          _loggingIn
              ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
              : const Icon(Icons.login, size: 16),
      label: const Text('Connect'),
      style: ElevatedButton.styleFrom(
        backgroundColor: CicadaColors.data,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class _ChannelConfig {
  final String id;
  final String name;
  final IconData icon;
  final String type;

  const _ChannelConfig(this.id, this.name, this.icon, this.type);
}

class _PageHeader extends StatelessWidget {
  final String title;
  final VoidCallback onRefresh;

  const _PageHeader({required this.title, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: CicadaColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh, color: CicadaColors.muted),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}
