# Cicada 完整测试指南

## 测试环境说明

已创建一个**裸机测试环境**（bare-test容器），模拟用户的全新系统：
- ✅ 基于 Ubuntu 22.04
- ✅ 仅安装基础工具（curl, wget, ca-certificates）
- ✅ **没有** Node.js
- ✅ **没有** npm
- ✅ **没有** OpenClaw

这样可以完整测试 Cicada 的自动安装功能。

## 快速开始

### 1. 启动测试环境

```bash
cd ~/workspace/cicada
docker-compose up -d bare-test redis-test
```

### 2. 验证环境

```bash
docker-compose exec bare-test bash -c "node --version 2>/dev/null || echo '未安装 ✅'"
docker-compose exec bare-test bash -c "openclaw --version 2>/dev/null || echo '未安装 ✅'"
```

### 3. 进入测试容器

```bash
docker-compose exec bare-test bash
```

### 4. 运行完整安装测试

在容器内执行：

```bash
bash /app/test-scripts/test-full-install.sh
```

这个脚本会模拟 Cicada 的完整安装流程：
1. 检查初始环境（应该是空的）
2. 安装 Node.js 22.x
3. 安装 OpenClaw CLI
4. 创建配置文件
5. 测试 OpenClaw 命令

## 测试 Cicada 应用

### 方案 1: 使用编译好的 Linux 版本（推荐）

等待 Flutter 编译完成后：

```bash
# 1. 将编译产物复制到容器
docker cp ./build-output/cicada-linux cicada-bare-test:/app/

# 2. 在容器内运行 Cicada
docker-compose exec bare-test bash
cd /app/cicada-linux
./cicada
```

### 方案 2: 手动测试安装逻辑

在容器内手动执行 Cicada 的安装逻辑：

```bash
# 1. 检测环境
node --version || echo "需要安装 Node.js"

# 2. 安装 Node.js（模拟 Cicada 的 InstallerService）
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# 3. 验证安装
node --version
npm --version

# 4. 安装 OpenClaw
npm install -g openclaw

# 5. 验证 OpenClaw
openclaw --version

# 6. 配置 OpenClaw（需要 API Key）
mkdir -p ~/.openclaw
cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "providers": {
    "deepseek": {
      "apiKey": "your-api-key-here",
      "apiBase": "https://api.deepseek.com/v1",
      "defaultModel": "deepseek-chat"
    }
  },
  "defaultProvider": "deepseek",
  "defaultModel": "deepseek-chat"
}
EOF

# 7. 启动服务
openclaw start

# 8. 检查状态
openclaw status

# 9. 访问 Web UI
# 在宿主机浏览器打开: http://localhost:3000
```

## 测试场景

### 场景 1: 全新安装
- 环境：裸机（无 Node.js, 无 OpenClaw）
- 预期：Cicada 自动检测并安装所有依赖

### 场景 2: 部分安装
```bash
# 只安装 Node.js，不安装 OpenClaw
docker-compose exec bare-test bash -c "curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && apt-get install -y nodejs"
```
- 预期：Cicada 检测到 Node.js，只安装 OpenClaw

### 场景 3: 已完全安装
```bash
# 安装所有依赖
docker-compose exec bare-test bash /app/test-scripts/test-full-install.sh
```
- 预期：Cicada 检测到已安装，直接进入配置和启动流程

## 清理环境

### 重置测试环境（重新开始测试）

```bash
# 停止并删除容器
docker-compose down -v

# 删除镜像
docker rmi cicada-bare-test

# 重新启动
docker-compose up -d bare-test redis-test
```

### 仅重启容器（保留数据）

```bash
docker-compose restart bare-test
```

## 验证清单

测试 Cicada 时，请验证以下功能：

- [ ] 环境检测
  - [ ] 正确检测 Node.js 是否安装
  - [ ] 正确检测 OpenClaw 是否安装
  - [ ] 显示版本信息

- [ ] 自动安装
  - [ ] 能够安装 Node.js
  - [ ] 能够安装 OpenClaw
  - [ ] 安装过程有进度提示
  - [ ] 安装失败有错误提示

- [ ] 配置管理
  - [ ] 能够添加 AI 模型配置
  - [ ] 能够测试连接
  - [ ] 能够删除配置
  - [ ] 配置持久化到 ~/.openclaw/openclaw.json

- [ ] 服务控制
  - [ ] 能够启动服务
  - [ ] 能够停止服务
  - [ ] 实时显示服务状态
  - [ ] 能够打开 Web UI

- [ ] 错误处理
  - [ ] 网络错误有友好提示
  - [ ] 权限错误有友好提示
  - [ ] 配置错误有友好提示

## 当前架构状态

### ✅ 已完成
- Riverpod 状态管理
- Repository 模式
- 统一错误处理
- Dashboard 页面迁移（dashboard_page_riverpod.dart）

### 🔄 进行中
- Flutter 编译（Docker 后台运行）

### 📋 待测试
- 使用新架构的 Dashboard 页面
- 服务状态自动刷新
- 错误处理和用户提示

## 注意事项

1. **API Key 安全**：测试时使用测试 API Key，不要提交到 Git
2. **端口冲突**：确保宿主机的 3000 和 3001 端口未被占用
3. **网络访问**：容器需要访问外网下载 Node.js 和 OpenClaw
4. **权限问题**：容器内使用 root 用户，实际部署时需要考虑权限

## 故障排查

### 容器无法启动
```bash
docker-compose logs bare-test
```

### 无法访问外网
```bash
docker-compose exec bare-test curl -I https://www.google.com
```

### OpenClaw 安装失败
```bash
docker-compose exec bare-test npm config get registry
# 如果需要使用国内镜像
docker-compose exec bare-test npm config set registry https://registry.npmmirror.com
```
