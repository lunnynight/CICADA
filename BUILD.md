# 多平台构建说明

## 构建配置

GitHub Actions 会在推送 tag 时自动构建三个平台：

### 1. Windows (优先级最高)
- **运行环境**: windows-latest
- **产物**: `cicada-windows-x64.zip`
- **包含**: 所有 Windows 运行所需文件
- **目标用户**: Windows 10/11 用户

### 2. macOS (优先级第二)
- **运行环境**: macos-latest
- **产物**: `cicada-macos-universal.zip`
- **包含**: cicada.app (Universal Binary，支持 Intel 和 Apple Silicon)
- **目标用户**: macOS 用户

### 3. Linux (优先级第三)
- **运行环境**: ubuntu-latest
- **产物**: `cicada-linux-x64.tar.gz`
- **包含**: Linux 可执行文件和依赖库
- **目标用户**: Ubuntu/Debian 用户

## 如何发布新版本

```bash
# 1. 确保代码已提交
git add .
git commit -m "feat: 新功能"

# 2. 创建版本 tag
git tag v0.2.0

# 3. 推送 tag 触发构建
git push origin v0.2.0

# 4. GitHub Actions 会自动：
#    - 构建 Windows 版本
#    - 构建 macOS 版本
#    - 构建 Linux 版本
#    - 创建 Release
#    - 上传所有构建产物
```

## 本地测试构建

### Windows
需要 Windows 机器：
```bash
flutter build windows --release
```

### macOS
在 macOS 上：
```bash
flutter build macos --release
```

### Linux
在 Linux 或 Docker 中：
```bash
# 安装依赖
sudo apt-get install -y clang cmake ninja-build pkg-config libgtk-3-dev

# 构建
flutter build linux --release
```

## 当前状态

⚠️ **注意**：代码有编译错误，需要先修复才能成功构建：
- `lib/pages/setup_page.dart` - RadioGroup 相关错误
- `lib/pages/models_page.dart` - DropdownButtonFormField 错误
- `lib/pages/settings_page.dart` - RadioGroup 相关错误

修复这些错误后，推送 tag 即可自动构建所有平台。

## 下载地址

发布后，用户可以从 GitHub Releases 页面下载：
```
https://github.com/2233admin/cicada/releases
```

每个平台的文件：
- Windows: `cicada-windows-x64.zip`
- macOS: `cicada-macos-universal.zip`
- Linux: `cicada-linux-x64.tar.gz`
