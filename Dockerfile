# CICADA 测试环境
# 基于 Ubuntu + Node.js + OpenClaw

FROM ubuntu:22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=22.x
ENV OPENCLAW_VERSION=latest

# 安装基础工具
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    ca-certificates \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION} | bash - \
    && apt-get install -y nodejs \
    && npm install -g npm@latest

# 安装 OpenClaw
RUN npm install -g openclaw

# 创建工作目录
WORKDIR /app

# 创建配置目录
RUN mkdir -p /root/.openclaw

# 复制测试脚本
COPY test-scripts/ /app/test-scripts/

# 暴露端口
EXPOSE 3000 3001

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD node --version && openclaw --version || exit 1

# 默认命令
CMD ["/bin/bash"]
