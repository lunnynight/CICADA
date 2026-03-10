import 'package:flutter/material.dart';

class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '技能商店',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('发现和安装 OpenClaw 技能扩展', style: TextStyle(color: Colors.grey[500])),
          const SizedBox(height: 24),
          TextField(
            decoration: InputDecoration(
              hintText: '搜索技能...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Icon(Icons.extension, size: 64, color: Colors.grey[700]),
                const SizedBox(height: 16),
                Text(
                  '敬请期待',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey[500]),
                ),
                const SizedBox(height: 8),
                Text(
                  '技能商店即将上线',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: const [
              _PlaceholderSkillCard(name: '代码审查', desc: '自动化代码质量检查', icon: Icons.rate_review),
              _PlaceholderSkillCard(name: '文档生成', desc: '从代码生成 API 文档', icon: Icons.description),
              _PlaceholderSkillCard(name: '测试助手', desc: '自动生成单元测试', icon: Icons.bug_report),
              _PlaceholderSkillCard(name: '国际化', desc: '多语言翻译支持', icon: Icons.translate),
              _PlaceholderSkillCard(name: 'Git 助手', desc: '智能 commit message', icon: Icons.code),
              _PlaceholderSkillCard(name: '重构建议', desc: '代码优化建议', icon: Icons.auto_fix_high),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlaceholderSkillCard extends StatelessWidget {
  final String name;
  final String desc;
  final IconData icon;

  const _PlaceholderSkillCard({
    required this.name,
    required this.desc,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF7C3AED), size: 28),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF30363D)),
                ),
                child: const Text('即将推出'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
