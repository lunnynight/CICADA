# Cicada 测试 - 快速开始

## 当前状态

✅ **裸机测试环境已就绪**
- 容器名称: `cicada-bare-test`
- 状态: 运行中（健康）
- 环境: Ubuntu 22.04（无 Node.js, 无 OpenClaw）

## 立即开始测试

### 方式 1: 运行自动化测试脚本

```bash
cd ~/workspace/cicada
docker-compose exec bare-test bash /app/test-scripts/test-full-install.sh
```

这会自动执行：
1. ✅ 检查初始环境（应该是空的）
2. 📦 安装 Node.js 22.x
3. 📦 安装 OpenClaw CLI
4. ⚙️ 创建配置文件
5. ✅ 验证安装结果

### 方式 2: 手动逐步测试

```bash
# 1. 进入容器
docker-compose exec bare-test bash

# 2. 检查初始状态
node --version    # 应该报错：未安装
npm --version     # 应该报错：未安装
openclaw --version # 应该报错：未安装

# 3. 安装 Node.js（模拟 Cicada 的 InstallerService.installNode()）
curl -fsSL https://deb.nodesource.com/setup_22.x | bash -
apt-get install -y nodejs

# 4. 验证 Node.js
node --version    # 应该显示 v22.x.x
npm --version     # 应该显示版本号

# 5. 安装 OpenClaw（模拟 Cicada 的 InstallerService.installOpenClaw()）
npm install -g openclaw

# 6. 验证 OpenClaw
openclaw --version # 应该显示版本号

# 7. 配置 OpenClaw（模拟 Cicada 的配置功能）
mkdir -p ~/.openclaw
cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "providers": {
    "deepseek": {
      "apiKey": "sk-test-key",
      "apiBase": "https://api.deepseek.com/v1",
      "defaultModel": "deepseek-chat"
    }
  },
  "defaultProvider": "deepseek",
  "defaultModel": "deepseek-chat"
}
EOF

# 8. 查看配置
cat ~/.openclaw/openclaw.json

# 9. 测试 OpenClaw 命令
openclaw --help
openclaw status

# 10. 启动服务（需要有效的 API Key）
openclaw start
```

## 测试验证点

测试时请验证：

- [ ] **环境检测**
  - InstallerService.checkNode() 能正确检测 Node.js
  - InstallerService.checkOpenClaw() 能正确检测 OpenClaw

- [ ] **自动安装**
  - InstallerService.installNode() 能成功安装 Node.js
  - InstallerService.installOpenClaw() 能成功安装 OpenClaw

- [ ] **配置管理**
  - ConfigService.writeConfig() 能正确写入配置
  - ConfigService.readConfig() 能正确读取配置

- [ ] **服务控制**
  - InstallerService.startService() 能启动服务
  - InstallerService.stopService() 能停止服务
  - InstallerService.isServiceRunning() 能检测状态

## 清理并重新测试

```bash
# 停止并删除容器
docker-compose down -v

# 重新启动（全新环境）
docker-compose up -d bare-test redis-test

# 验证环境已重置
docker-compose exec bare-test bash -c "node --version 2>/dev/null || echo '未安装 ✅'"
```

## 注意事项

⚠️ **Flutter 编译失败**：旧代码有语法错误，需要修复后才能编译 Cicada 应用。但这不影响测试安装逻辑。

📝 **下一步**：
1. 先在容器内手动测试安装流程
2. 验证所有安装步骤都能正常工作
3. 然后修复代码编译错误
4. 最后编译并测试完整的 Cicada 应用

## 快速命令

```bash
# 查看容器状态
docker-compose ps

# 查看容器日志
docker-compose logs bare-test

# 进入容器
docker-compose exec bare-test bash

# 重启容器
docker-compose restart bare-test

# 停止所有
docker-compose down
```
