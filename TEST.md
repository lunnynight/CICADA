# Cicada 测试指南

## 编译

### 使用 Docker 编译
```bash
./scripts/build.sh
```

编译产物位于 `./build-output/cicada-linux/`

## 测试

### 启动测试环境
```bash
./scripts/test.sh
```

这会启动：
- OpenClaw 测试容器（带 Node.js 和 OpenClaw CLI）
- Redis 容器（用于 claw-mesh 集成测试）

### 手动测试步骤

1. 进入容器：
```bash
docker-compose exec openclaw-test /bin/bash
```

2. 验证环境：
```bash
node --version
npm --version
openclaw --version
```

3. 配置 OpenClaw：
```bash
# 创建配置文件
cat > ~/.openclaw/openclaw.json << 'EOF'
{
  "providers": {
    "deepseek": {
      "apiKey": "your-api-key",
      "apiBase": "https://api.deepseek.com/v1",
      "defaultModel": "deepseek-chat"
    }
  },
  "defaultProvider": "deepseek",
  "defaultModel": "deepseek-chat"
}
EOF
```

4. 启动服务：
```bash
openclaw start
```

5. 检查状态：
```bash
openclaw status
curl http://localhost:3000/health
```

6. 访问 Web UI：
在宿主机浏览器打开 http://localhost:3000

## 清理

停止并删除容器：
```bash
docker-compose down -v
```

## 架构重构进度

### Phase 1: 架构重构 ✅
- [x] 引入 Riverpod 状态管理
- [x] 创建 Result 类型统一错误处理
- [x] 引入 Repository 模式
- [x] 添加 freezed 数据模型
- [ ] 迁移现有页面到新架构
- [ ] 添加单元测试

### Phase 2: 功能增强（待开始）
- [ ] 多实例管理
- [ ] 配置管理增强
- [ ] 监控面板
- [ ] 日志系统

### Phase 3: 网络功能（待开始）
- [ ] 远程实例管理
- [ ] Tailscale 集成
- [ ] 集群管理
