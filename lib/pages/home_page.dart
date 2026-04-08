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
import 'channels_page.dart';
import 'logs_page.dart';
import 'memory_page.dart';
import 'claude_code_page.dart';
import 'gateway_page.dart';

/// Navigation index constants — use these instead of hardcoded ints.
class NavIndex {
  static const dashboard = 0, gateway = 1, channels = 2;
  static const models = 3, skills = 4, mcp = 5;
  static const logs = 6, token = 7, memory = 8;
  static const claudeCode = 9, webui = 10, diagnostic = 11;
  static const setup = 12, settings = 13;
}

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
    // Primary
    _NavItem(Icons.dashboard, '仪表盘'),           // 0
    _NavItem(Icons.router, 'Gateway'),              // 1
    _NavItem(Icons.hub, '渠道管理'),                // 2
    // Configuration
    _NavItem(Icons.smart_toy, '模型配置'),           // 3
    _NavItem(Icons.extension, '技能商店'),           // 4
    _NavItem(Icons.power, '插件管理'),              // 5
    // Monitoring
    _NavItem(Icons.terminal, '日志查看'),            // 6
    _NavItem(Icons.analytics, 'Token分析'),         // 7
    _NavItem(Icons.memory, '记忆搜索'),             // 8
    // Tools
    _NavItem(Icons.code, 'Claude Code'),            // 9
    _NavItem(Icons.web, 'WebUI'),                   // 10
    _NavItem(Icons.medical_services, '诊断中心'),    // 11
    // System
    _NavItem(Icons.download, '安装向导'),            // 12
    _NavItem(Icons.settings, '设置'),               // 13
  ];

  // Bottom nav: 5 primary items (indices into _navItems)
  static const _bottomNavIndices = [0, 1, 2, 13, -1]; // -1 = drawer trigger
  static const _bottomNavLabels = ['仪表盘', 'Gateway', '渠道', '设置', '更多'];
  static const _bottomNavIcons = [
    Icons.dashboard, Icons.router, Icons.hub, Icons.settings, Icons.menu,
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
    const drawerIndices = [3, 4, 5, 6, 7, 8, 9, 10, 11, 12];
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
      case NavIndex.dashboard: return DashboardPage(key: const ValueKey('dashboard'), onNavigate: _navigateTo);
      case NavIndex.gateway: return const GatewayPage(key: ValueKey('gateway'));
      case NavIndex.channels: return const ChannelsPage(key: ValueKey('channels'));
      case NavIndex.models: return const ModelsPage(key: ValueKey('models'));
      case NavIndex.skills: return const SkillsPage(key: ValueKey('skills'));
      case NavIndex.mcp: return const McpPage(key: ValueKey('mcp'));
      case NavIndex.logs: return const LogsPage(key: ValueKey('logs'));
      case NavIndex.token: return const TokenPage(key: ValueKey('token'));
      case NavIndex.memory: return const MemoryPage(key: ValueKey('memory'));
      case NavIndex.claudeCode: return const ClaudeCodePage(key: ValueKey('claude_code'));
      case NavIndex.webui: return const WebUIPage(key: ValueKey('webui'));
      case NavIndex.diagnostic: return DiagnosticPage(key: const ValueKey('diagnostic'), onNavigate: _navigateTo);
      case NavIndex.setup: return SetupPage(key: const ValueKey('setup'), onSetupComplete: () => _navigateTo(NavIndex.gateway));
      case NavIndex.settings: return const SettingsPage(key: ValueKey('settings'));
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
