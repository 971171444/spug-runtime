# Spug Enhanced Runtime

> **基于 [Spug](https://github.com/openspug/spug) 二次开发的增强版容器运行时环境**

[![License](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](https://opensource.org/licenses/AGPL-3.0)
[![Based on Spug](https://img.shields.io/badge/based%20on-Spug-green.svg)](https://github.com/openspug/spug)

## 📋 项目说明

本项目基于 [Spug](https://github.com/openspug/spug) 开源运维平台进行二次开发，主要针对容器运行时环境进行了功能增强和优化。

**原项目信息**：
- 原项目地址：https://github.com/openspug/spug
- 原项目官网：https://www.spug.cc
- 原项目文档：https://ops.spug.cc/docs/about-spug/
- 原项目许可证：AGPL-3.0

**本项目遵循原项目的开源协议，仅对容器运行时环境进行增强，不涉及核心业务逻辑修改。**

## ✨ 增强功能

### 1. 外部 Redis 支持
- ✅ 支持连接外部 Redis 服务器
- ✅ 支持 Redis 密码认证
- ✅ 支持自定义 Redis 数据库编号
- ✅ 自动处理 Redis 密码中的特殊字符（URL 编码）

### 2. 灵活的运行时环境切换
- ✅ **JDK 版本切换**：支持多版本 JDK（8, 17, 21, 22 等）
- ✅ **Maven 版本切换**：支持多版本 Maven（3.6.3, 3.9.11 等）
- ✅ **Node.js 版本切换**：支持多版本 Node.js（14, 16, 18, 20, 22 等）
- ✅ 通过挂载目录方式提供版本包，按需解压使用
- ✅ 提供便捷的命令行工具：`usejdk`、`usemvn`、`usenode`

### 3. 镜像优化
- ✅ 移除内置的 JDK/Maven/Node.js 安装包，大幅减小镜像体积
- ✅ 使用 Ubuntu 22.04 LTS 作为基础镜像（更稳定、更现代）
- ✅ 优化构建层数，减少镜像大小

### 4. 其他优化
- ✅ 修复 Redis 密码认证问题
- ✅ 修复 Nginx 用户权限问题
- ✅ 优化 Python 依赖版本兼容性
- ✅ 改进容器启动脚本

## 🚀 快速开始

### 前置要求

- Docker 和 Docker Compose
- 外部 MySQL 数据库（可选，也可使用 Docker Compose 中的数据库）
- 外部 Redis 服务器（可选，也可使用 Docker Compose 中的 Redis）

### 1. 准备版本包目录

在宿主机上创建以下目录结构，并放入对应的版本包：

```bash
/path/to/versions/
├── jdk/          # JDK 版本包目录
│   ├── OpenJDK8U-jdk_x64_linux_hotspot_8u472b08.tar.gz
│   ├── OpenJDK17U-jdk_x64_linux_hotspot_17.0.17_10.tar.gz
│   └── OpenJDK21U-jdk_x64_linux_hotspot_21.0.9_10.tar.gz
├── maven/        # Maven 版本包目录
│   ├── apache-maven-3.6.3-bin.tar.gz
│   └── apache-maven-3.9.11-bin.tar.gz
└── node/         # Node.js 版本包目录
    ├── node-v14.21.3-linux-x64.tar.gz
    ├── node-v16.19.0-linux-x64.tar.gz
    ├── node-v18.20.4-linux-x64.tar.gz
    └── node-v20.10.0-linux-x64.tar.gz
```

### 2. 构建镜像

```bash
git clone https://github.com/971171444/spug-enhanced-runtime.git
cd spug-enhanced-runtime
docker build -t spug-enhanced:latest .
```

### 3. 配置 Docker Compose

创建 `docker-compose.yml`：

```yaml
version: "3.3"
services:
  spug:
    image: spug-enhanced:latest
    container_name: spug
    privileged: true
    restart: always
    volumes:
      # 挂载版本包目录（只读）
      - /path/to/versions/jdk:/opt/ext/jdk:ro
      - /path/to/versions/maven:/opt/ext/maven:ro
      - /path/to/versions/node:/opt/ext/node:ro
      # 数据目录（可选）
      # - ./spug:/data/spug:rw
    ports:
      - "18083:80"
    environment:
      # MySQL 配置
      - MYSQL_DATABASE=spug
      - MYSQL_USER=spug
      - MYSQL_PASSWORD=your_password
      - MYSQL_HOST=10.0.2.23        # 外部 MySQL 地址
      - MYSQL_PORT=9307              # 外部 MySQL 端口
      # Redis 配置
      - REDIS_HOST=192.168.1.147     # 外部 Redis 地址
      - REDIS_PORT=9379              # 外部 Redis 端口
      - REDIS_PASSWORD=Shkj@123!@#   # Redis 密码（支持特殊字符）
      - REDIS_DB=8                    # Redis 数据库编号
```

### 4. 启动服务

```bash
docker-compose up -d
```

### 5. 初始化管理员账号

```bash
docker exec spug init_spug admin spug.cc
```

## 📖 使用指南

### 版本切换命令

进入容器后，可以使用以下命令切换运行时版本：

```bash
# 进入容器
docker exec -it spug bash

# 切换 JDK 版本
usejdk 17        # 切换到 JDK 17
java -version    # 验证

# 切换 Maven 版本（需要先切换 JDK）
usejdk 17        # 先切换 JDK
usemvn 3.9.11    # 切换到 Maven 3.9.11
mvn -v           # 验证

# 切换 Node.js 版本
usenode 20       # 切换到 Node.js 20
node -v          # 验证
```

**注意**：
- 版本包会在首次使用时自动解压到容器内的 `/opt/ext` 目录
- 环境变量会在当前 shell 会话中生效
- 如果进入容器后命令不生效，执行 `source /root/.bashrc` 重新加载

### 版本包命名规则

脚本支持以下命名模式：

**JDK**：
- `jdk8.tar.gz`、`jdk17.tar.gz` 等
- `OpenJDK*8*.tar.gz`、`OpenJDK*17*.tar.gz` 等（模式匹配）

**Maven**：
- `apache-maven-3.6.3-bin.tar.gz`、`apache-maven-3.9.11-bin.tar.gz` 等
- `maven-3.6.3.tar.gz` 等（模式匹配）

**Node.js**：
- `node-v14.21.3-linux-x64.tar.gz`、`node-v20.10.0-linux-x64.tar.gz` 等
- `node-v14*.tar.gz`、`node-v20*.tar.gz` 等（模式匹配）

## 🔧 配置说明

### 环境变量

| 变量名 | 说明 | 默认值 | 必填 |
|--------|------|--------|------|
| `MYSQL_DATABASE` | MySQL 数据库名 | `spug` | 是 |
| `MYSQL_USER` | MySQL 用户名 | `spug` | 是 |
| `MYSQL_PASSWORD` | MySQL 密码 | - | 是 |
| `MYSQL_HOST` | MySQL 主机地址 | `127.0.0.1` | 是 |
| `MYSQL_PORT` | MySQL 端口 | `3306` | 是 |
| `REDIS_HOST` | Redis 主机地址 | `127.0.0.1` | 是 |
| `REDIS_PORT` | Redis 端口 | `6379` | 是 |
| `REDIS_PASSWORD` | Redis 密码 | - | 否 |
| `REDIS_DB` | Redis 数据库编号 | `1` | 否 |

### 挂载目录

| 挂载路径 | 说明 | 权限 |
|---------|------|------|
| `/opt/ext/jdk` | JDK 版本包目录 | 只读 |
| `/opt/ext/maven` | Maven 版本包目录 | 只读 |
| `/opt/ext/node` | Node.js 版本包目录 | 只读 |
| `/data/spug` | Spug 数据目录 | 读写 |

## 🐛 故障排查

### 1. 容器无法启动

检查日志：
```bash
docker logs spug
```

常见问题：
- Redis 连接失败：检查 `REDIS_HOST`、`REDIS_PORT`、`REDIS_PASSWORD` 配置
- MySQL 连接失败：检查网络连通性和 MySQL 配置

### 2. 版本切换命令不生效

```bash
# 重新加载函数定义
source /root/.bashrc

# 或重新进入容器
docker exec -it spug bash
```

### 3. 找不到版本包

- 确认版本包已正确挂载到容器内
- 检查版本包命名是否符合规则
- 查看容器内目录：`docker exec spug ls -la /opt/ext/jdk`

## 📝 更新日志

### v1.0.0 (2025-01-XX)
- ✅ 支持外部 Redis（带密码）
- ✅ 实现 JDK/Maven/Node.js 版本切换功能
- ✅ 优化镜像体积
- ✅ 修复 Redis 密码认证问题
- ✅ 修复 Nginx 用户权限问题

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

## 📄 许可证

本项目基于 [Spug](https://github.com/openspug/spug) 二次开发，遵循原项目的 [AGPL-3.0](https://opensource.org/licenses/AGPL-3.0) 许可证。

**重要声明**：
- 本项目仅对容器运行时环境进行增强，不涉及 Spug 核心业务逻辑修改
- 本项目遵循原项目的开源协议，尊重原作者的版权
- 使用本项目时，请遵守原项目的许可证要求

## 🙏 致谢

- 感谢 [Spug](https://github.com/openspug/spug) 项目提供优秀的开源运维平台
- 感谢所有为 Spug 项目做出贡献的开发者

## 📮 联系方式

如有问题或建议，请通过以下方式联系：
- 提交 Issue：https://github.com/971171444/spug-enhanced-runtime/issues
- 原项目官网：https://www.spug.cc

---

**⚠️ 免责声明**：本项目为个人学习研究使用，不对使用本项目造成的任何损失负责。请在生产环境使用前充分测试。
