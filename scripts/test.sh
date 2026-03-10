#!/bin/bash
set -e

echo "🧪 启动 Cicada 测试环境..."

# 启动 OpenClaw 测试容器
echo "📦 启动 OpenClaw 测试容器..."
docker-compose up -d openclaw-test redis-test

echo "⏳ 等待服务启动..."
sleep 5

# 检查容器状态
echo "📊 容器状态:"
docker-compose ps

# 进入测试容器
echo ""
echo "🚀 进入测试容器..."
echo "提示: 在容器内可以运行以下命令测试 OpenClaw:"
echo "  - openclaw --version"
echo "  - openclaw start"
echo "  - openclaw status"
echo "  - curl http://localhost:3000/health"
echo ""

docker-compose exec openclaw-test /bin/bash
