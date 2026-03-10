import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'setup_page.dart';
import 'models_page.dart';
import 'skills_page.dart';
import 'settings_page.dart';

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
          const VerticalDivider(width: 1, color: Color(0xFF30363D)),
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
        return const SettingsPage(key: ValueKey('settings'));
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 220,
      color: const Color(0xFF161B22),
      child: Column(
        children: [
          const SizedBox(height: 24),
          const Text(
            '\u{1F997} 知了猴',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'OpenClaw 启动器',
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Material(
                    color: selected
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _navigateTo(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              size: 20,
                              color: selected
                                  ? const Color(0xFF7C3AED)
                                  : Colors.grey[400],
                            ),
                            const SizedBox(width: 12),
                            Text(
                              item.label,
                              style: TextStyle(
                                color: selected
                                    ? Colors.white
                                    : Colors.grey[400],
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
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _serviceRunning ? Colors.green : Colors.red,
                    boxShadow: _serviceRunning
                        ? [BoxShadow(color: Colors.green.withValues(alpha: 0.5), blurRadius: 6)]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _serviceRunning ? '服务运行中' : '服务已停止',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
