#!/bin/bash
set -e

echo "🔨 开始编译 Cicada..."

# 创建输出目录
mkdir -p build-output

# 使用 Docker 编译
echo "📦 构建 Docker 镜像..."
docker-compose build flutter-build

echo "🚀 开始编译..."
docker-compose run --rm flutter-build

echo "✅ 编译完成！"
echo "📁 输出目录: ./build-output/cicada-linux"
