import 'dart:async';
import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../app/widgets/status_badge.dart';
import '../services/installer_service.dart';
import 'dashboard_page.dart';
import 'setup_page.dart';
import 'models_page.dart';
import 'skills_page.dart';
import 'mcp_page.dart';
import 'webui_page.dart';
import 'settings_page.dart';
import 'diagnostic_page.dart';
import 'token_page.dart';
import 'chat_page.dart';
import 'sessions_page.dart';
import 'channels_page.dart';
import 'logs_page.dart';
import 'memory_page.dart';
import 'claude_code_page.dart';
import 'gateway_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _serviceRunning = false;
  Timer? _statusTimer;

  static const _navItems = [
    _NavItem(Icons.dashboard, '仪表盘'),         // 0
    _NavItem(Icons.download, '安装向导'),         // 1
    _NavItem(Icons.chat, 'Agent对话'),            // 2
    _NavItem(Icons.history, '会话管理'),           // 3
    _NavItem(Icons.hub, '渠道管理'),              // 4
    _NavItem(Icons.terminal, '日志查看'),          // 5
    _NavItem(Icons.memory, '记忆搜索'),           // 6
    _NavItem(Icons.smart_toy, '模型配置'),         // 7
    _NavItem(Icons.extension, '技能商店'),         // 8
    _NavItem(Icons.power, '插件管理'),            // 9
    _NavItem(Icons.web, 'WebUI'),                // 10
    _NavItem(Icons.analytics, 'Token分析'),       // 11
    _NavItem(Icons.medical_services, '诊断中心'),  // 12
    _NavItem(Icons.code, 'Claude Code'),          // 13
    _NavItem(Icons.router, 'Gateway'),             // 14
    _NavItem(Icons.settings, '设置'),             // 15
  ];

  // Bottom nav: 5 primary items (indices into _navItems)
  static const _bottomNavIndices = [0, 2, 8, 15, -1]; // -1 = drawer trigger
  static const _bottomNavLabels = ['仪表盘', 'Agent', '技能', '设置', '更多'];
  static const _bottomNavIcons = [
    Icons.dashboard, Icons.chat, Icons.extension, Icons.settings, Icons.menu,
  ];

  void _navigateTo(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  void initState() {
    super.initState();
    _checkStatus();
    _statusTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _checkStatus(),
    );
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    final running = await InstallerService.isGatewayRunning();
    if (mounted && running != _serviceRunning) {
      setState(() => _serviceRunning = running);
    }
  }

  bool _isWide(BuildContext context) =>
      MediaQuery.of(context).size.width > 800;

  @override
  Widget build(BuildContext context) {
    final wide = _isWide(context);
    return Scaffold(
      body: wide ? _buildDesktopLayout() : _buildMobileLayout(),
      bottomNavigationBar: wide ? null : _buildBottomNav(),
      drawer: wide ? null : _buildDrawer(),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        _buildSidebar(),
        const VerticalDivider(width: 1, color: CicadaColors.border),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildPage(_selectedIndex),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _buildPage(_selectedIndex),
    );
  }

  int get _bottomNavCurrentIndex {
    for (int i = 0; i < _bottomNavIndices.length - 1; i++) {
      if (_bottomNavIndices[i] == _selectedIndex) return i;
    }
    return 4;
  }

  Widget _buildBottomNav() {
    return Builder(builder: (ctx) => NavigationBar(
      selectedIndex: _bottomNavCurrentIndex,
      onDestinationSelected: (i) {
        if (i == 4) {
          Scaffold.of(ctx).openDrawer();
          return;
        }
        _navigateTo(_bottomNavIndices[i]);
      },
      backgroundColor: CicadaColors.surface,
      indicatorColor: CicadaColors.data.withAlpha(30),
      destinations: List.generate(5, (i) => NavigationDestination(
        icon: Icon(_bottomNavIcons[i], color: CicadaColors.textTertiary),
        selectedIcon: Icon(_bottomNavIcons[i], color: CicadaColors.accent),
        label: _bottomNavLabels[i],
      )),
    ));
  }

  Widget _buildDrawer() {
    const drawerIndices = [1, 3, 4, 5, 6, 7, 9, 10, 11, 12, 13, 14];
    return Drawer(
      backgroundColor: CicadaColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 3, height: 24, color: CicadaColors.accent),
                const SizedBox(width: 10),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CICADA', style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800,
                      letterSpacing: 3, color: CicadaColors.textPrimary,
                    )),
                    Text('OpenClaw Launcher', style: TextStyle(
                      fontSize: 10, letterSpacing: 1.5,
                      color: CicadaColors.textTertiary,
                    )),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(color: CicadaColors.border),
            Expanded(
              child: ListView(
                children: drawerIndices.map((idx) {
                  final item = _navItems[idx];
                  final selected = _selectedIndex == idx;
                  return ListTile(
                    leading: Icon(item.icon, size: 20,
                      color: selected ? CicadaColors.accent : CicadaColors.textTertiary),
                    title: Text(item.label, style: TextStyle(
                      color: selected ? CicadaColors.textPrimary : CicadaColors.textSecondary,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                    )),
                    selected: selected,
                    selectedTileColor: CicadaColors.data.withAlpha(20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      _navigateTo(idx);
                      Navigator.pop(context);
                    },
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: StatusBadge(
                type: _serviceRunning ? StatusType.online : StatusType.offline,
                label: _serviceRunning ? 'SERVICE ONLINE' : 'SERVICE OFFLINE',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0: return DashboardPage(key: const ValueKey('dashboard'), onNavigate: _navigateTo);
      case 1: return SetupPage(key: const ValueKey('setup'), onSetupComplete: () => _navigateTo(2));
      case 2: return const ChatPage(key: ValueKey('chat'));
      case 3: return const SessionsPage(key: ValueKey('sessions'));
      case 4: return const ChannelsPage(key: ValueKey('channels'));
      case 5: return const LogsPage(key: ValueKey('logs'));
      case 6: return const MemoryPage(key: ValueKey('memory'));
      case 7: return const ModelsPage(key: ValueKey('models'));
      case 8: return const SkillsPage(key: ValueKey('skills'));
      case 9: return const McpPage(key: ValueKey('mcp'));
      case 10: return const WebUIPage(key: ValueKey('webui'));
      case 11: return const TokenPage(key: ValueKey('token'));
      case 12: return DiagnosticPage(key: const ValueKey('diagnostic'), onNavigate: _navigateTo);
      case 13: return const ClaudeCodePage(key: ValueKey('claude_code'));
      case 14: return const GatewayPage(key: ValueKey('gateway'));
      case 15: return const SettingsPage(key: ValueKey('settings'));
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: CicadaColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 3, height: 24, color: CicadaColors.accent),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CICADA', style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w800,
                    letterSpacing: 3, color: CicadaColors.textPrimary,
                  )),
                  Text('OpenClaw Launcher', style: TextStyle(
                    fontSize: 10, letterSpacing: 1.5,
                    color: CicadaColors.textTertiary,
                  )),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.builder(
              itemCount: _navItems.length,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemBuilder: (context, index) {
                final item = _navItems[index];
                final selected = _selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: selected
                        ? CicadaColors.data.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => _navigateTo(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            if (selected)
                              Container(width: 2, height: 16,
                                margin: const EdgeInsets.only(right: 10),
                                color: CicadaColors.accent),
                            Icon(item.icon, size: 18,
                              color: selected ? CicadaColors.accent : CicadaColors.textTertiary),
                            const SizedBox(width: 12),
                            Text(item.label, style: TextStyle(
                              fontSize: 13,
                              color: selected ? CicadaColors.textPrimary : CicadaColors.textSecondary,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: StatusBadge(
              type: _serviceRunning ? StatusType.online : StatusType.offline,
              label: _serviceRunning ? 'SERVICE ONLINE' : 'SERVICE OFFLINE',
            ),
          ),
        ],
      ),
    );
  }
}
