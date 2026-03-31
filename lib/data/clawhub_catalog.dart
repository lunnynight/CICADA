/// ClawHub Skill Catalog - 100 curated skills from clawhub.ai
/// URL format: https://clawhub.ai/skills/[slug]
class ClawHubSkill {
  final String slug;
  final String name;
  final String description;
  final String category;
  final String emoji;
  final double score;

  const ClawHubSkill({
    required this.slug,
    required this.name,
    required this.description,
    required this.category,
    this.emoji = '📦',
    this.score = 0,
  });

  String get url => 'https://clawhub.ai/skills/$slug';
}

class ClawHubCatalog {
  ClawHubCatalog._();

  static const siteUrl = 'https://clawhub.ai';

  static const categories = [
    '全部',
    '开发工具',
    'Git & 版本控制',
    '前端',
    '测试',
    '安全',
    '部署 & DevOps',
    '数据库 & 数据',
    'AI & LLM',
    '通讯 & 社交',
    '效率 & 任务',
    '笔记 & 文档',
    '浏览器 & 自动化',
    '媒体 & 创意',
    '搜索 & 翻译',
    '金融 & 加密',
    '系统 & 监控',
    '智能家居',
  ];

  static const skills = <ClawHubSkill>[
    // ── 开发工具 ──
    ClawHubSkill(slug: 'code', name: 'Code', description: '通用编码辅助技能', category: '开发工具', emoji: '💻', score: 3.617),
    ClawHubSkill(slug: 'code-generator', name: 'Code Generator', description: '自动代码生成', category: '开发工具', emoji: '⚡', score: 3.400),
    ClawHubSkill(slug: 'quack-code-review', name: 'Code Review', description: '自动化代码审查与质量检查', category: '开发工具', emoji: '🔍', score: 3.378),
    ClawHubSkill(slug: 'explain-code', name: 'Explain Code', description: '代码解释与文档化', category: '开发工具', emoji: '📖', score: 3.509),
    ClawHubSkill(slug: 'persistent-code-terminal', name: 'Persistent Code Terminal', description: '持久化代码终端环境', category: '开发工具', emoji: '🖥️', score: 3.394),
    ClawHubSkill(slug: 'javascript', name: 'JavaScript', description: 'JavaScript 开发最佳实践', category: '开发工具', emoji: '🟨', score: 3.532),
    ClawHubSkill(slug: 'python-dataviz', name: 'Python DataViz', description: 'Python 数据可视化', category: '开发工具', emoji: '🐍', score: 3.479),
    ClawHubSkill(slug: 'lsp-python', name: 'LSP Python', description: 'Python LSP 智能补全', category: '开发工具', emoji: '🐍', score: 3.412),
    ClawHubSkill(slug: 'api-tester', name: 'API Tester', description: 'API 接口测试工具', category: '开发工具', emoji: '🧪', score: 3.491),
    ClawHubSkill(slug: 'api-generator', name: 'API Generator', description: 'API 代码自动生成', category: '开发工具', emoji: '🔧', score: 3.373),

    // ── Git & 版本控制 ──
    ClawHubSkill(slug: 'git-essentials', name: 'Git Essentials', description: 'Git 核心操作指南', category: 'Git & 版本控制', emoji: '📦', score: 3.766),
    ClawHubSkill(slug: 'git-workflows', name: 'Git Workflows', description: 'Git 工作流最佳实践', category: 'Git & 版本控制', emoji: '🔀', score: 3.708),
    ClawHubSkill(slug: 'git', name: 'Git', description: 'Git 版本控制操作', category: 'Git & 版本控制', emoji: '📋', score: 3.661),
    ClawHubSkill(slug: 'git-helper', name: 'Git Helper', description: '智能 commit message 生成', category: 'Git & 版本控制', emoji: '💬', score: 3.615),
    ClawHubSkill(slug: 'git-secrets-scanner', name: 'Git Secrets Scanner', description: 'Git 仓库密钥扫描', category: 'Git & 版本控制', emoji: '🔐', score: 3.485),
    ClawHubSkill(slug: 'git-changelog-gen', name: 'Git Changelog Generator', description: '自动生成变更日志', category: 'Git & 版本控制', emoji: '📝', score: 3.451),

    // ── 前端 ──
    ClawHubSkill(slug: 'react-expert', name: 'React Expert', description: 'React 开发专家指导', category: '前端', emoji: '⚛️', score: 3.601),
    ClawHubSkill(slug: 'react', name: 'React', description: 'React 开发最佳实践', category: '前端', emoji: '⚛️', score: 3.549),
    ClawHubSkill(slug: 'react-best-practices', name: 'React Best Practices', description: 'React 最佳实践合集', category: '前端', emoji: '✨', score: 3.467),
    ClawHubSkill(slug: 'react-performance', name: 'React Performance', description: 'React 性能优化', category: '前端', emoji: '🚀', score: 3.411),
    ClawHubSkill(slug: 'frontend-design-3', name: 'Frontend Design', description: '前端设计规范与组件', category: '前端', emoji: '🎨', score: 3.653),
    ClawHubSkill(slug: 'design-system-creation', name: 'Design System', description: '设计系统创建与管理', category: '前端', emoji: '🎯', score: 3.439),

    // ── 测试 ──
    ClawHubSkill(slug: 'test-runner', name: 'Test Runner', description: '自动化测试运行器', category: '测试', emoji: '🏃', score: 3.655),
    ClawHubSkill(slug: 'test-master', name: 'Test Master', description: '测试大师 — 全面测试管理', category: '测试', emoji: '🎓', score: 3.597),
    ClawHubSkill(slug: 'test-patterns', name: 'Test Patterns', description: '测试模式与策略', category: '测试', emoji: '📐', score: 3.560),
    ClawHubSkill(slug: 'test-case-generator', name: 'Test Case Generator', description: '自动生成测试用例', category: '测试', emoji: '🧬', score: 3.395),
    ClawHubSkill(slug: 'python-code-test', name: 'Python Code Tester', description: 'Python 代码测试工具', category: '测试', emoji: '🐍', score: 3.312),

    // ── 安全 ──
    ClawHubSkill(slug: 'security-auditor', name: 'Security Auditor', description: '安全审计与漏洞扫描', category: '安全', emoji: '🛡️', score: 3.597),
    ClawHubSkill(slug: 'security-audit-toolkit', name: 'Security Audit Toolkit', description: '安全审计工具集', category: '安全', emoji: '🔒', score: 3.541),
    ClawHubSkill(slug: 'security-scanner', name: 'Security Scanner', description: '安全漏洞扫描器', category: '安全', emoji: '🔎', score: 3.513),
    ClawHubSkill(slug: 'cyber-security-engineer', name: 'Cyber Security Engineer', description: '网络安全工程师', category: '安全', emoji: '🕵️', score: 3.386),

    // ── 部署 & DevOps ──
    ClawHubSkill(slug: 'docker-essentials', name: 'Docker Essentials', description: 'Docker 核心操作指南', category: '部署 & DevOps', emoji: '🐳', score: 3.714),
    ClawHubSkill(slug: 'docker-compose', name: 'Docker Compose', description: 'Docker Compose 编排', category: '部署 & DevOps', emoji: '🐳', score: 3.539),
    ClawHubSkill(slug: 'deploy-agent', name: 'Deploy Agent', description: '自动化部署代理', category: '部署 & DevOps', emoji: '🚀', score: 3.569),
    ClawHubSkill(slug: 'vercel-deploy', name: 'Vercel Deploy', description: 'Vercel 一键部署', category: '部署 & DevOps', emoji: '▲', score: 3.540),
    ClawHubSkill(slug: 'railway-deploy', name: 'Railway Deploy', description: 'Railway 平台部署', category: '部署 & DevOps', emoji: '🚂', score: 3.466),
    ClawHubSkill(slug: 'deploy', name: 'Deploy', description: '通用部署技能', category: '部署 & DevOps', emoji: '📤', score: 3.510),

    // ── 数据库 & 数据 ──
    ClawHubSkill(slug: 'database-designer', name: 'Database Designer', description: '数据库设计与建模', category: '数据库 & 数据', emoji: '🗄️', score: 3.326),
    ClawHubSkill(slug: 'csv', name: 'CSV', description: 'CSV 文件处理与分析', category: '数据库 & 数据', emoji: '📊', score: 3.600),
    ClawHubSkill(slug: 'csv-pipeline', name: 'CSV Data Pipeline', description: 'CSV 数据管道处理', category: '数据库 & 数据', emoji: '🔄', score: 3.547),
    ClawHubSkill(slug: 'json-formatter', name: 'JSON Formatter', description: 'JSON 格式化与验证', category: '数据库 & 数据', emoji: '📋', score: 3.407),
    ClawHubSkill(slug: 'data-model-designer', name: 'Data Model Designer', description: '数据模型设计', category: '数据库 & 数据', emoji: '📐', score: 3.482),
    ClawHubSkill(slug: 'data-analyst-pro', name: 'Data Analyst', description: '数据分析专家', category: '数据库 & 数据', emoji: '📈', score: 3.424),

    // ── AI & LLM ──
    ClawHubSkill(slug: 'prompt-engineering-expert', name: 'Prompt Engineering Expert', description: '提示词工程专家', category: 'AI & LLM', emoji: '🧠', score: 3.640),
    ClawHubSkill(slug: 'prompt-enhancer', name: 'Prompt Enhancer', description: '提示词优化增强', category: 'AI & LLM', emoji: '✨', score: 3.494),
    ClawHubSkill(slug: 'antigravity-image-gen', name: 'Image Generator', description: 'AI 图片生成', category: 'AI & LLM', emoji: '🖼️', score: 3.590),
    ClawHubSkill(slug: 'agent-team-orchestration', name: 'Agent Team Orchestration', description: '多 Agent 团队编排', category: 'AI & LLM', emoji: '🤖', score: 3.607),
    ClawHubSkill(slug: 'agent-directory', name: 'Agent Directory', description: 'Agent 目录管理', category: 'AI & LLM', emoji: '📂', score: 3.576),
    ClawHubSkill(slug: 'ai-agent-helper', name: 'AI Agent Helper', description: 'AI Agent 辅助工具', category: 'AI & LLM', emoji: '🤝', score: 3.528),
    ClawHubSkill(slug: 'coding-agent', name: 'Coding Agent', description: '委派编码任务给后台 Agent', category: 'AI & LLM', emoji: '👨‍💻', score: 3.5),

    // ── 通讯 & 社交 ──
    ClawHubSkill(slug: 'discord', name: 'Discord', description: 'Discord 消息收发与管理', category: '通讯 & 社交', emoji: '🎮', score: 3.619),
    ClawHubSkill(slug: 'slack', name: 'Slack', description: 'Slack 消息控制', category: '通讯 & 社交', emoji: '💬', score: 3.320),
    ClawHubSkill(slug: 'email-daily-summary', name: 'Email Daily Summary', description: '每日邮件摘要自动生成', category: '通讯 & 社交', emoji: '📧', score: 3.588),
    ClawHubSkill(slug: 'react-email-skills', name: 'React Email', description: 'React 邮件模板开发', category: '通讯 & 社交', emoji: '✉️', score: 3.483),
    ClawHubSkill(slug: 'discord-voice', name: 'Discord Voice', description: 'Discord 语音频道控制', category: '通讯 & 社交', emoji: '🎙️', score: 3.516),

    // ── 效率 & 任务 ──
    ClawHubSkill(slug: 'notion', name: 'Notion', description: 'Notion 页面与数据库管理', category: '效率 & 任务', emoji: '📝', score: 3.780),
    ClawHubSkill(slug: 'calendar', name: 'Calendar', description: '日历事件管理', category: '效率 & 任务', emoji: '📅', score: 3.719),
    ClawHubSkill(slug: 'n8n-workflow-automation', name: 'n8n Workflow', description: 'n8n 工作流自动化', category: '效率 & 任务', emoji: '⚙️', score: 3.696),
    ClawHubSkill(slug: 'task', name: 'Task', description: '任务管理与追踪', category: '效率 & 任务', emoji: '✅', score: 3.634),
    ClawHubSkill(slug: 'automation-workflows', name: 'Automation Workflows', description: '自动化工作流编排', category: '效率 & 任务', emoji: '🔄', score: 3.757),
    ClawHubSkill(slug: 'workflow', name: 'Workflow', description: '工作流设计与执行', category: '效率 & 任务', emoji: '📊', score: 3.580),
    ClawHubSkill(slug: 'weather', name: 'Weather', description: '天气查询与预报', category: '效率 & 任务', emoji: '🌤️', score: 3.868),

    // ── 笔记 & 文档 ──
    ClawHubSkill(slug: 'markdown-formatter', name: 'Markdown Formatter', description: 'Markdown 格式化工具', category: '笔记 & 文档', emoji: '📝', score: 3.630),
    ClawHubSkill(slug: 'markdown', name: 'Markdown', description: 'Markdown 编辑与转换', category: '笔记 & 文档', emoji: '📄', score: 3.557),
    ClawHubSkill(slug: 'nano-pdf', name: 'Nano PDF', description: '自然语言编辑 PDF', category: '笔记 & 文档', emoji: '📑', score: 3.744),
    ClawHubSkill(slug: 'pdf', name: 'PDF', description: 'PDF 处理与生成', category: '笔记 & 文档', emoji: '📕', score: 3.694),
    ClawHubSkill(slug: 'pdf-extract', name: 'PDF Extract', description: 'PDF 内容提取', category: '笔记 & 文档', emoji: '📤', score: 3.600),
    ClawHubSkill(slug: 'feishu-doc-manager', name: '飞书文档管理器', description: '飞书文档创建与管理', category: '笔记 & 文档', emoji: '📄', score: 3.569),
    ClawHubSkill(slug: 'obsidian-notesmd-cli', name: 'Obsidian CLI', description: 'Obsidian 知识库命令行操作', category: '笔记 & 文档', emoji: '💎', score: 3.384),
    ClawHubSkill(slug: 'diagram-generator', name: 'Diagram Generator', description: '图表自动生成', category: '笔记 & 文档', emoji: '📊', score: 3.647),
    ClawHubSkill(slug: 'diagram', name: 'Diagram', description: '图表绘制工具', category: '笔记 & 文档', emoji: '📈', score: 3.576),

    // ── 浏览器 & 自动化 ──
    ClawHubSkill(slug: 'agent-browser-clawdbot', name: 'Agent Browser', description: '浏览器自动化操作', category: '浏览器 & 自动化', emoji: '🌐', score: 3.748),
    ClawHubSkill(slug: 'browser-automation', name: 'Browser Automation', description: '浏览器自动化框架', category: '浏览器 & 自动化', emoji: '🤖', score: 3.736),
    ClawHubSkill(slug: 'agent-browser-stagehand', name: 'Stagehand Browser', description: 'Stagehand 浏览器自动化', category: '浏览器 & 自动化', emoji: '🎭', score: 3.616),
    ClawHubSkill(slug: 'stagehand-browser-cli', name: 'Stagehand CLI', description: 'Stagehand 浏览器 CLI', category: '浏览器 & 自动化', emoji: '⌨️', score: 3.610),
    ClawHubSkill(slug: 'ai-web-automation', name: 'AI Web Automation', description: 'AI 驱动的网页自动化', category: '浏览器 & 自动化', emoji: '🕸️', score: 3.607),
    ClawHubSkill(slug: 'web-pilot', name: 'Web Pilot', description: '网页导航与数据提取', category: '浏览器 & 自动化', emoji: '🧭', score: 3.504),

    // ── 媒体 & 创意 ──
    ClawHubSkill(slug: 'best-image-generation', name: 'Best Image Generation', description: '最佳 AI 图片生成', category: '媒体 & 创意', emoji: '🖼️', score: 3.494),
    ClawHubSkill(slug: 'video-frames', name: 'Video Frames', description: '视频帧提取与剪辑', category: '媒体 & 创意', emoji: '🎬', score: 3.654),
    ClawHubSkill(slug: 'demo-video', name: 'Demo Video Creator', description: '演示视频自动创建', category: '媒体 & 创意', emoji: '🎥', score: 3.523),
    ClawHubSkill(slug: 'spotify-player', name: 'Spotify Player', description: 'Spotify 终端播放与搜索', category: '媒体 & 创意', emoji: '🎧', score: 3.711),
    ClawHubSkill(slug: 'graphic-design', name: 'Graphic Design', description: '平面设计辅助', category: '媒体 & 创意', emoji: '🎨', score: 3.510),
    ClawHubSkill(slug: 'audio-cog', name: 'Audio Cog', description: '音频处理与分析', category: '媒体 & 创意', emoji: '🎵', score: 3.544),
    ClawHubSkill(slug: 'elevenlabs-music', name: 'ElevenLabs Music', description: 'ElevenLabs AI 音乐生成', category: '媒体 & 创意', emoji: '🎼', score: 3.438),

    // ── 搜索 & 翻译 ──
    ClawHubSkill(slug: 'baidu-search', name: 'Baidu Search', description: '百度网页搜索', category: '搜索 & 翻译', emoji: '🔍', score: 3.725),
    ClawHubSkill(slug: 'liang-tavily-search', name: 'Tavily Search', description: 'Tavily AI 搜索引擎', category: '搜索 & 翻译', emoji: '🔎', score: 3.589),
    ClawHubSkill(slug: 'translate', name: 'Translate', description: '多语言翻译', category: '搜索 & 翻译', emoji: '🌐', score: 3.656),
    ClawHubSkill(slug: 'arxiv-translate', name: 'ArXiv Translate', description: 'ArXiv 论文翻译', category: '搜索 & 翻译', emoji: '📚', score: 3.370),
    ClawHubSkill(slug: 'web-content-fetcher', name: 'Web Content Fetcher', description: '网页内容抓取', category: '搜索 & 翻译', emoji: '📥', score: 3.426),

    // ── 金融 & 加密 ──
    ClawHubSkill(slug: 'tushare-finance', name: 'Tushare Finance', description: 'Tushare 金融数据接口', category: '金融 & 加密', emoji: '📈', score: 3.607),
    ClawHubSkill(slug: 'crypto-market-data', name: 'Crypto Market Data', description: '加密货币市场数据（无需 API Key）', category: '金融 & 加密', emoji: '₿', score: 3.583),
    ClawHubSkill(slug: 'crypto-trading-bot', name: 'Crypto Trading Bot', description: '加密货币交易机器人', category: '金融 & 加密', emoji: '🤖', score: 3.551),
    ClawHubSkill(slug: 'finance-report-analyzer', name: 'Finance Report Analyzer', description: '财务报告分析', category: '金融 & 加密', emoji: '📊', score: 3.477),
    ClawHubSkill(slug: 'finance-accounting', name: 'Finance Accounting', description: '财务会计辅助', category: '金融 & 加密', emoji: '💰', score: 3.471),

    // ── 系统 & 监控 ──
    ClawHubSkill(slug: 'system-resource-monitor', name: 'System Resource Monitor', description: '系统资源监控', category: '系统 & 监控', emoji: '📊', score: 3.552),
    ClawHubSkill(slug: 'security-monitor', name: 'Security Monitor', description: '安全监控与告警', category: '系统 & 监控', emoji: '🔔', score: 3.555),
    ClawHubSkill(slug: 'auto-monitor', name: 'Auto Monitor', description: '自动化系统监控', category: '系统 & 监控', emoji: '👁️', score: 3.501),
    ClawHubSkill(slug: 'ping-monitor', name: 'Ping Monitor', description: '网络连通性监控', category: '系统 & 监控', emoji: '📡', score: 3.497),
    ClawHubSkill(slug: 'file-organizer-zh', name: 'File Organizer', description: '智能文件分类整理', category: '系统 & 监控', emoji: '📁', score: 3.412),

    // ── 智能家居 ──
    ClawHubSkill(slug: 'openhue', name: 'OpenHue', description: 'Philips Hue 灯光控制', category: '智能家居', emoji: '💡', score: 3.5),
    ClawHubSkill(slug: 'sonoscli', name: 'Sonos CLI', description: 'Sonos 音箱控制', category: '智能家居', emoji: '🔊', score: 3.5),
    ClawHubSkill(slug: 'macos-calendar', name: 'macOS Calendar', description: 'macOS 日历管理', category: '智能家居', emoji: '📅', score: 3.573),
    ClawHubSkill(slug: 'apple-health-skill', name: 'Apple Health', description: 'Apple 健康数据管理', category: '智能家居', emoji: '❤️', score: 3.374),
  ];
}
