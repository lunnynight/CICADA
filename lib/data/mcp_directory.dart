// Curated MCP server directory for offline browsing and discovery.
// Periodically updated from GitHub ecosystem data.

class McpEntry {
  final String name;
  final String npm;
  final String description;
  final String category;
  final int stars;
  final String? repo;

  const McpEntry({
    required this.name,
    required this.npm,
    required this.description,
    required this.category,
    this.stars = 0,
    this.repo,
  });
}

const mcpDirectory = [
  // ── Anthropic 官方 ──
  McpEntry(
    name: 'Filesystem',
    npm: '@anthropic-ai/mcp-filesystem',
    description: '文件系统读写访问',
    category: '系统',
    stars: 5000,
    repo: 'anthropics/mcp-servers',
  ),
  McpEntry(
    name: 'GitHub',
    npm: '@anthropic-ai/mcp-github',
    description: 'GitHub 仓库操作（PR、Issue、搜索）',
    category: '开发',
    stars: 4500,
    repo: 'anthropics/mcp-servers',
  ),
  McpEntry(
    name: 'Brave Search',
    npm: '@anthropic-ai/mcp-brave-search',
    description: '网页搜索和本地搜索',
    category: '搜索',
    stars: 3000,
    repo: 'anthropics/mcp-servers',
  ),
  McpEntry(
    name: 'Puppeteer',
    npm: '@anthropic-ai/mcp-puppeteer',
    description: '浏览器自动化和网页抓取',
    category: '浏览器',
    stars: 2800,
    repo: 'anthropics/mcp-servers',
  ),
  McpEntry(
    name: 'Memory',
    npm: '@anthropic-ai/mcp-memory',
    description: '持久化知识图谱记忆',
    category: 'AI',
    stars: 2500,
    repo: 'anthropics/mcp-servers',
  ),
  McpEntry(
    name: 'SQLite',
    npm: '@anthropic-ai/mcp-sqlite',
    description: 'SQLite 数据库查询和管理',
    category: '数据库',
    stars: 2000,
    repo: 'anthropics/mcp-servers',
  ),
  McpEntry(
    name: 'Fetch',
    npm: '@anthropic-ai/mcp-fetch',
    description: 'HTTP 请求和 API 调用',
    category: '网络',
    stars: 1800,
    repo: 'anthropics/mcp-servers',
  ),
  McpEntry(
    name: 'Sequential Thinking',
    npm: '@anthropic-ai/mcp-sequential-thinking',
    description: '结构化思维链推理',
    category: 'AI',
    stars: 1200,
    repo: 'anthropics/mcp-servers',
  ),

  // ── 社区热门 ──
  McpEntry(
    name: 'Exa Search',
    npm: 'exa-mcp-server',
    description: '语义搜索引擎，精准查找内容',
    category: '搜索',
    stars: 1500,
    repo: 'exa-labs/exa-mcp-server',
  ),
  McpEntry(
    name: 'Tavily Search',
    npm: 'tavily-mcp-server',
    description: 'AI 优化的搜索引擎',
    category: '搜索',
    stars: 1000,
  ),
  McpEntry(
    name: 'PostgreSQL',
    npm: '@anthropic-ai/mcp-postgres',
    description: 'PostgreSQL 数据库操作',
    category: '数据库',
    stars: 1500,
    repo: 'anthropics/mcp-servers',
  ),
  McpEntry(
    name: 'Slack',
    npm: '@anthropic-ai/mcp-slack',
    description: 'Slack 消息和频道管理',
    category: '通讯',
    stars: 1200,
    repo: 'anthropics/mcp-servers',
  ),
  McpEntry(
    name: 'Google Drive',
    npm: '@anthropic-ai/mcp-gdrive',
    description: 'Google Drive 文件操作',
    category: '存储',
    stars: 1100,
    repo: 'anthropics/mcp-servers',
  ),
  McpEntry(
    name: 'Google Maps',
    npm: '@anthropic-ai/mcp-google-maps',
    description: '地图搜索和路线规划',
    category: '工具',
    stars: 900,
    repo: 'anthropics/mcp-servers',
  ),
  McpEntry(
    name: 'Sentry',
    npm: '@anthropic-ai/mcp-sentry',
    description: '错误监控和问题追踪',
    category: '开发',
    stars: 800,
    repo: 'anthropics/mcp-servers',
  ),
  McpEntry(
    name: 'Git',
    npm: '@anthropic-ai/mcp-git',
    description: 'Git 仓库操作（本地）',
    category: '开发',
    stars: 2200,
    repo: 'anthropics/mcp-servers',
  ),
  McpEntry(
    name: 'Everart',
    npm: '@anthropic-ai/mcp-everart',
    description: 'AI 图像生成',
    category: '媒体',
    stars: 600,
    repo: 'anthropics/mcp-servers',
  ),
];

/// All directory categories
const mcpDirectoryCategories = [
  '全部', '系统', '开发', '搜索', '浏览器', 'AI',
  '数据库', '网络', '通讯', '存储', '工具', '媒体',
];
