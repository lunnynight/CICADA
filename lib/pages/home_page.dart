import 'package:flutter/material.dart';
import '../app/theme/cicada_colors.dart';
import '../app/widgets/status_badge.dart';
import 'dashboard_page.dart';
import 'setup_page.dart';
import 'models_page.dart';
import 'skills_page.dart';
import 'settings_page.dart';
import 'diagnostic_page.dart';
import 'token_page.dart';

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

  static const _navItems = [
    _NavItem(Icons.dashboard, '仪表盘'),
    _NavItem(Icons.download, '安装向导'),
    _NavItem(Icons.smart_toy, '模型配置'),
    _NavItem(Icons.extension, '技能商店'),
    _NavItem(Icons.analytics, 'Token分析'),
    _NavItem(Icons.medical_services, '诊断中心'),
    _NavItem(Icons.settings, '设置'),
  ];

  void _navigateTo(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
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
      ),
    );
  }

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return DashboardPage(
          key: const ValueKey('dashboard'),
          onServiceStatusChanged: (running) {
            setState(() => _serviceRunning = running);
          },
        );
      case 1:
        return SetupPage(
          key: const ValueKey('setup'),
          onSetupComplete: () => _navigateTo(2),
        );
      case 2:
        return const ModelsPage(key: ValueKey('models'));
      case 3:
        return const SkillsPage(key: ValueKey('skills'));
      case 4:
        return const TokenPage(key: ValueKey('token'));
      case 5:
        return const DiagnosticPage(key: ValueKey('diagnostic'));
      case 6:
        return const SettingsPage(key: ValueKey('settings'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: CicadaColors.surface,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo area with accent line
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(width: 3, height: 24, color: CicadaColors.accent),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CICADA',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3,
                      color: CicadaColors.textPrimary,
                    ),
                  ),
                  Text(
                    'OpenClaw Launcher',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: CicadaColors.textTertiary,
                    ),
                  ),
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            if (selected)
                              Container(
                                width: 2,
                                height: 16,
                                margin: const EdgeInsets.only(right: 10),
                                color: CicadaColors.accent,
                              ),
                            Icon(
                              item.icon,
                              size: 18,
                              color: selected
                                  ? CicadaColors.accent
                                  : CicadaColors.textTertiary,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 13,
                                color: selected
                                    ? CicadaColors.textPrimary
                                    : CicadaColors.textSecondary,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          // Service status at bottom
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
