import '../models/mcp_server.dart';

/// Built-in MCP server preset templates for one-click setup.
const mcpPresets = [
  // ── Anthropic 官方 ──
  McpPreset(
    name: 'Filesystem',
    command: 'npx',
    args: ['-y', '@anthropic-ai/mcp-filesystem'],
    description: '文件系统读写访问',
    category: '系统',
  ),
  McpPreset(
    name: 'GitHub',
    command: 'npx',
    args: ['-y', '@anthropic-ai/mcp-github'],
    envKeys: ['GITHUB_TOKEN'],
    description: 'GitHub 仓库操作',
    category: '开发',
  ),
  McpPreset(
    name: 'Brave Search',
    command: 'npx',
    args: ['-y', '@anthropic-ai/mcp-brave-search'],
    envKeys: ['BRAVE_API_KEY'],
    description: '网页搜索',
    category: '搜索',
  ),
  McpPreset(
    name: 'Puppeteer',
    command: 'npx',
    args: ['-y', '@anthropic-ai/mcp-puppeteer'],
    description: '浏览器自动化',
    category: '浏览器',
  ),
  McpPreset(
    name: 'Memory',
    command: 'npx',
    args: ['-y', '@anthropic-ai/mcp-memory'],
    description: '持久化记忆存储',
    category: 'AI',
  ),
  McpPreset(
    name: 'Sequential Thinking',
    command: 'npx',
    args: ['-y', '@anthropic-ai/mcp-sequential-thinking'],
    description: '结构化思维链',
    category: 'AI',
  ),

  // ── 数据库 ──
  McpPreset(
    name: 'SQLite',
    command: 'npx',
    args: ['-y', '@anthropic-ai/mcp-sqlite'],
    description: 'SQLite 数据库操作',
    category: '数据库',
  ),

  // ── 网络 ──
  McpPreset(
    name: 'Fetch',
    command: 'npx',
    args: ['-y', '@anthropic-ai/mcp-fetch'],
    description: 'HTTP 请求工具',
    category: '网络',
  ),

  // ── 社区热门 ──
  McpPreset(
    name: 'Exa Search',
    command: 'npx',
    args: ['-y', 'exa-mcp-server'],
    envKeys: ['EXA_API_KEY'],
    description: '语义搜索引擎',
    category: '搜索',
  ),
  McpPreset(
    name: 'Tavily Search',
    command: 'npx',
    args: ['-y', 'tavily-mcp-server'],
    envKeys: ['TAVILY_API_KEY'],
    description: 'AI 搜索引擎',
    category: '搜索',
  ),
];

/// All preset categories
const mcpPresetCategories = ['全部', '系统', '开发', '搜索', '浏览器', 'AI', '数据库', '网络'];
