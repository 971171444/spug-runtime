# Spug Enhanced Runtime

> **基于 [Spug](https://github.com/openspug/spug) 的增强版容器运行时环境**

[![License](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](https://opensource.org/licenses/AGPL-3.0)
[![Based on Spug](https://img.shields.io/badge/based%20on-Spug-green.svg)](https://github.com/openspug/spug)

## 📋 项目说明

本项目基于 [Spug](https://github.com/openspug/spug) 开源运维平台进行增强运行时环境，主要针对容器运行时环境进行了功能增强和优化。

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
- ✅ 单命令 `useenv`：同时设置 JDK/Maven/Node，可用环境变量传参，适合流水线

### 3. 镜像
- ✅ 使用 Ubuntu 22.04 LTS 作为基础镜像

## 🚀 快速开始

1) 准备（可选）版本包目录  
   为 JDK/Maven/Node 提前放好压缩包，构建时即可按需选择：
   ```bash
   /path/to/versions/
   ├── jdk/
   │   ├── OpenJDK8U-jdk_x64_linux_hotspot_8u472b08.tar.gz
   │   ├── OpenJDK17U-jdk_x64_linux_hotspot_17.0.17_10.tar.gz
   │   └── OpenJDK21U-jdk_x64_linux_hotspot_21.0.9_10.tar.gz
   ├── maven/
   │   ├── apache-maven-3.6.3-bin.tar.gz
   │   └── apache-maven-3.9.11-bin.tar.gz
   └── node/
       ├── node-v14.21.3-linux-x64.tar.gz
       ├── node-v16.19.0-linux-x64.tar.gz
       ├── node-v18.20.4-linux-x64.tar.gz
       └── node-v20.10.0-linux-x64.tar.gz
   ```

2) 构建镜像  
   ```bash
   git clone https://github.com/971171444/spug-runtime.git
   cd spug-runtime
   docker build -t spug-runtime:latest .
   # 或自定义
   docker build \
   --build-arg SPUG_REPO=https://github.com/openspug/spug.git \
   --build-arg SPUG_REF=3.0 \
   -t spug-runtime:latest .
   ```

3) 使用 Docker Compose 启动  
   下面示例直接挂载版本包目录，并暴露 18083 端口：
   ```yaml
   version: "3.9"
   services:
     spug:
       image: spug-runtime:latest
       container_name: spug
       privileged: true
       restart: always
       volumes:
         - /path/to/versions/jdk:/opt/ext/jdk:ro
         - /path/to/versions/maven:/opt/ext/maven:ro
         - /path/to/versions/node:/opt/ext/node:ro
         - ./spug-data:/data/spug:rw     # 可选
         - ./spug-repos:/data/repos:rw   # 可选
       ports:
         - "18083:80"
       environment:
         MYSQL_DATABASE: spug
         MYSQL_USER: spug
         MYSQL_PASSWORD: your_password
         MYSQL_HOST: 10.0.2.23
         MYSQL_PORT: 9307
         REDIS_HOST: 192.168.1.147
         REDIS_PORT: 9379
         REDIS_PASSWORD: Shkj@123!@#
         REDIS_DB: 8
   ```
   保存为 `docker-compose.yml` 后执行：
   ```bash
   docker compose up -d
   ```

4) 进入容器并选择构建工具链版本  
   ```bash
   docker exec -it spug bash
   useenv --jdk 17 --maven 3.9.11 --node 20 --show   # Maven 会复用已选 JDK
   ```
   脚本会按需解压挂载的包并在当前 shell 内生效。

5) 初始化管理员账号  
   ```bash
   docker exec spug init_spug admin spug.cc
   ```

## 📖 使用指南

### 构建/版本选择命令（唯一入口：`useenv`）

- 推荐（流水线一行搞定，命令跟在 `--` 之后）：  
  ```bash
  useenv --jdk 17 --maven 3.9.11 --show -- mvn clean package -DskipTests
  ```
- 环境变量传参示例：  
  ```bash
  JDK_VERSION=17 MAVEN_VERSION=3.9.11 NODE_VERSION=20 useenv --show -- mvn clean package -DskipTests
  ```

**注意**：
- 版本包会在首次使用时自动解压到容器内 `/opt/ext`，再次使用走缓存
- 环境变量仅对当前 shell 生效，需要的话执行 `source /root/.bashrc` 重新加载

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

**⚠️ 免责声明**：本项目为个人学习研究使用，不对使用本项目造成的任何损失负责。请在生产环境使用前充分测试。
