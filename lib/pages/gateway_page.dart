import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme/cicada_colors.dart';
import '../app/widgets/hud_panel.dart';
import '../providers/gateway_provider.dart';
import '../services/gateway_service.dart';
import '../services/installer_service.dart';
import '../services/config_service.dart';
import 'gateway_sessions_tab.dart';

class GatewayPage extends ConsumerStatefulWidget {
  const GatewayPage({super.key});

  @override
  ConsumerState<GatewayPage> createState() => _GatewayPageState();
}

class _GatewayPageState extends ConsumerState<GatewayPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  // Gateway status
  bool _isRunning = false;
  bool _isChecking = true;
  bool _isStarting = false;
  bool _isRestarting = false;

  // Chat
  final List<ChatMessage> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _messageScrollController = ScrollController();
  bool _isSending = false;
  StreamSubscription? _messageSub;
  StreamSubscription? _statusSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageSub?.cancel();
    _statusSub?.cancel();
    _messageScrollController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _checkGatewayStatus();
    if (_isRunning) {
      _connectWebSocket();
    }
  }

  Future<void> _checkGatewayStatus() async {
    setState(() => _isChecking = true);
    try {
      final running = await GatewayService.isRunning();
      if (!mounted) return;
      setState(() => _isRunning = running);
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _connectWebSocket() {
    _messageSub?.cancel();
    _statusSub?.cancel();

    GatewayService.connect().then((_) {
      _messageSub = GatewayService.messageStream.listen(_onMessage);
      _statusSub = GatewayService.statusStream.listen(_onStatus);
    }).catchError((e) {
      debugPrint('WebSocket connect failed: $e');
    });
  }

  void _onMessage(GatewayMessage message) {
    if (message.type == 'response' || message.type == 'message') {
      setState(() {
        _messages.add(
          ChatMessage(
            content: message.content?.toString() ?? '',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    }
  }

  void _onStatus(GatewayStatus status) {
    // Handle status updates
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_messageScrollController.hasClients) {
        _messageScrollController.animateTo(
          _messageScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _startGateway() async {
    setState(() => _isStarting = true);

    try {
      final result = await InstallerService.startService();
      if (!mounted) return;

      if (result.exitCode == 0) {
        await Future.delayed(const Duration(seconds: 2));
        await _checkGatewayStatus();
        if (_isRunning) {
          _connectWebSocket();
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('启动失败: $e')),
      );
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _stopGateway() async {
    setState(() => _isStarting = true);
    try {
      await InstallerService.stopService();
      GatewayService.disconnect();
      await Future.delayed(const Duration(seconds: 1));
      await _checkGatewayStatus();
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  Future<void> _restartGateway() async {
    await _stopGateway();
    await _startGateway();
  }

  Future<void> _switchProvider(String? providerId) async {
    if (providerId == null) return;

    setState(() => _isRestarting = true);
    try {
      await ConfigService.switchProvider(providerId);
      ref.invalidate(currentProviderIdProvider);
      ref.invalidate(configuredProviderMapProvider);

      if (_isRunning) {
        await _restartGateway();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('切换模型失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRestarting = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(
        ChatMessage(content: text, isUser: true, timestamp: DateTime.now()),
      );
      _isSending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      GatewayService.sendMessage('gateway', text);
    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              content: '发送失败: $e',
              isUser: false,
              timestamp: DateTime.now(),
              isError: true,
            ),
          );
        });
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _buildMainContent(),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
      child: Row(
        children: [
          const Text(
            'GATEWAY',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: CicadaColors.textPrimary,
            ),
          ),
          const SizedBox(width: 16),
          _buildStatusIndicator(),
          const Spacer(),
          if (!_isRunning && !_isChecking)
            ElevatedButton.icon(
              onPressed: _isStarting ? null : _startGateway,
              icon: _isStarting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: const Text('启动 Gateway'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CicadaColors.ok,
                foregroundColor: Colors.white,
              ),
            ),
          if (_isRunning) ...[
            ElevatedButton.icon(
              onPressed: _isStarting ? null : _restartGateway,
              icon: _isRestarting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh),
              label: const Text('重启'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CicadaColors.data,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isStarting ? null : _stopGateway,
              icon: const Icon(Icons.stop),
              label: const Text('停止'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CicadaColors.alert,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    if (_isChecking) {
      return const Row(
        children: [
          SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 8),
          Text('检测中...', style: TextStyle(fontSize: 12)),
        ],
      );
    }

    final color = _isRunning ? CicadaColors.ok : CicadaColors.alert;
    final text = _isRunning ? '运行中' : '未运行';

    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [
              BoxShadow(
                color: color.withAlpha(100),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(fontSize: 12, color: color),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Tab bar
        TabBar(
          controller: _tabController,
          indicatorColor: CicadaColors.accent,
          labelColor: CicadaColors.textPrimary,
          unselectedLabelColor: CicadaColors.textTertiary,
          tabs: const [
            Tab(text: 'CONTROL'),
            Tab(text: 'SESSIONS'),
          ],
        ),
        const SizedBox(height: 16),
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildControlTab(),
              const GatewaySessionsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildControlTab() {
    return Column(
      children: [
        // Model selector
        _buildModelSelector(),
        const SizedBox(height: 16),
        // Chat area
        Expanded(
          child: HudPanel(
            title: 'CONVERSATION',
            titleIcon: Icons.chat,
            accent: CicadaColors.data,
            child: _buildChatContent(),
          ),
        ),
        const SizedBox(height: 16),
        // Input area
        _buildInputArea(),
      ],
    );
  }

  Widget _buildModelSelector() {
    final providersAsync = ref.watch(configuredProviderMapProvider);
    final currentIdAsync = ref.watch(currentProviderIdProvider);

    return providersAsync.when(
      loading: () => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CicadaColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('加载模型配置...'),
          ],
        ),
      ),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CicadaColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: CicadaColors.alert),
            const SizedBox(width: 12),
            Text('加载失败: $e'),
          ],
        ),
      ),
      data: (providerMap) {
        if (providerMap.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CicadaColors.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.warning, color: CicadaColors.alert),
                SizedBox(width: 12),
                Text('未配置任何模型，请前往 模型配置 页面添加'),
              ],
            ),
          );
        }

        final currentId = currentIdAsync.valueOrNull;
        final providerIds = providerMap.keys.toList();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: CicadaColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: CicadaColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.smart_toy, size: 20),
              const SizedBox(width: 12),
              const Text('当前模型:'),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<String>(
                  value: currentId,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: providerIds.map((id) {
                    return DropdownMenuItem(
                      value: id,
                      child: Text(id),
                    );
                  }).toList(),
                  onChanged: _isRestarting ? null : _switchProvider,
                ),
              ),
              if (_isRestarting) ...[
                const SizedBox(width: 12),
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                const Text('重启中...'),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildChatContent() {
    if (!_isRunning) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.power_settings_new,
              size: 64,
              color: CicadaColors.textTertiary,
            ),
            const SizedBox(height: 24),
            const Text(
              'Gateway 未启动',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击上方「启动 Gateway」按钮开始使用',
              style: TextStyle(color: CicadaColors.textTertiary),
            ),
          ],
        ),
      );
    }

    if (_messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 48,
              color: CicadaColors.textTertiary,
            ),
            const SizedBox(height: 16),
            const Text(
              '开始与 OpenClaw 对话',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Gateway 已连接，在下方输入框发送消息',
              style: TextStyle(color: CicadaColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _messageScrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.5,
          ),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: message.isUser
                ? CicadaColors.data.withAlpha(40)
                : message.isError
                    ? CicadaColors.alert.withAlpha(40)
                    : CicadaColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: message.isUser
                  ? CicadaColors.data
                  : message.isError
                      ? CicadaColors.alert
                      : CicadaColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.content,
                style: TextStyle(
                  color: message.isError
                      ? CicadaColors.alert
                      : CicadaColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatTime(message.timestamp),
                style: TextStyle(
                  fontSize: 10,
                  color: CicadaColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 32),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              enabled: _isRunning,
              style: const TextStyle(color: CicadaColors.textPrimary),
              decoration: InputDecoration(
                hintText: _isRunning ? '输入消息...' : 'Gateway 未启动，无法发送',
                hintStyle: TextStyle(color: CicadaColors.textTertiary),
                filled: true,
                fillColor: CicadaColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CicadaColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CicadaColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: CicadaColors.data),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: (!_isRunning || _isSending) ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send),
              label: const Text('发送'),
              style: ElevatedButton.styleFrom(
                backgroundColor: CicadaColors.data,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
  });
}
