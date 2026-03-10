# Cicada (知了猴)

> OpenClaw 一键启动器 Community 版 — 下载双击，5分钟用上 AI

## 功能

- **一键安装** — 环境检测 → Node.js 安装（国内镜像） → OpenClaw 安装，全程可视化
- **模型预置** — 豆包/DeepSeek/Kimi/GLM/千问/Ollama 等，填 Key 即用
- **技能商店** — 浏览、搜索、一键安装 ClawHub 技能
- **仪表盘** — 服务状态实时轮询、一键启停、打开 Web UI
- **连接测试** — 配置 API Key 后一键验证可用性
- **自动更新** — 检查 GitHub Releases 获取最新版本

## 下载

从 [Releases](https://github.com/2233admin/cicada/releases) 下载：
- Windows: `cicada-windows.zip`
- macOS / Linux: 即将支持

## 开发

```bash
flutter pub get
flutter run -d windows
```

## 构建

```bash
flutter build windows --release
```

## 技术栈
Flutter 3.29 + Dart 3.7 + Material 3

## 双版本

| 版本 | 面向 | 技术栈 |
|------|------|--------|
| **Cicada Community**（本项目） | 普通用户、开发者 | Flutter Desktop |
| **Cicada Enterprise** | 央企/内网/离线 | Tauri + React + Rust |

## 协议
GPL 3.0
