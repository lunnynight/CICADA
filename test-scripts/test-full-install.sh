#!/bin/bash
# Cicada 完整安装流程测试脚本

set -e

echo "🧪 Cicada 完整安装流程测试"
echo "=============================="
echo ""

# 1. 检查初始环境（应该没有 Node.js 和 OpenClaw）
echo "📋 步骤 1: 检查初始环境"
echo "------------------------"
echo -n "Node.js: "
if command -v node &> /dev/null; then
    echo "❌ 已安装 ($(node --version))"
    echo "⚠️  警告: 测试环境应该是裸机，请清理环境"
else
    echo "✅ 未安装（符合预期）"
fi

echo -n "npm: "
if command -v npm &> /dev/null; then
    echo "❌ 已安装 ($(npm --version))"
else
    echo "✅ 未安装（符合预期）"
fi

echo -n "OpenClaw: "
if command -v openclaw &> /dev/null; then
    echo "❌ 已安装 ($(openclaw --version))"
else
    echo "✅ 未安装（符合预期）"
fi
echo ""

# 2. 模拟 Cicada 安装 Node.js
echo "📋 步骤 2: 安装 Node.js"
echo "------------------------"
echo ">>> 使用 Cicada 的安装逻辑..."
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs
echo "✅ Node.js 安装完成: $(node --version)"
echo "✅ npm 安装完成: $(npm --version)"
echo ""

# 3. 模拟 Cicada 安装 OpenClaw
echo "📋 步骤 3: 安装 OpenClaw"
echo "------------------------"
echo ">>> 使用 npm 全局安装 OpenClaw..."
npm install -g openclaw
echo "✅ OpenClaw 安装完成: $(openclaw --version)"
echo ""

# 4. 配置 OpenClaw
echo "📋 步骤 4: 配置 OpenClaw"
echo "------------------------"
if [ -f ~/.openclaw/openclaw.json ]; then
    echo "✅ 配置文件已存在"
    cat ~/.openclaw/openclaw.json
else
    echo ">>> 创建默认配置..."
    mkdir -p ~/.openclaw
    cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "providers": {},
  "defaultProvider": null,
  "defaultModel": null
}
EOF
    echo "✅ 配置文件已创建"
fi
echo ""

# 5. 测试 OpenClaw 命令
echo "📋 步骤 5: 测试 OpenClaw 命令"
echo "------------------------"
openclaw --help | head -10
echo ""

# 6. 尝试启动服务（需要配置 API Key）
echo "📋 步骤 6: 服务状态检查"
echo "------------------------"
echo ">>> 检查服务状态..."
openclaw status || echo "服务未运行（需要配置 API Key 后启动）"
echo ""

echo "✅ 完整安装流程测试完成！"
echo ""
echo "💡 下一步："
echo "  1. 在 Cicada UI 中配置 AI 模型 API Key"
echo "  2. 点击'启动服务'按钮"
echo "  3. 访问 http://localhost:3000"
