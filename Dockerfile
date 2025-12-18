### 前端构建阶段（Node.js 16，兼容 webpack 4）
FROM node:16-alpine AS frontend-builder
WORKDIR /build

ARG SPUG_REPO=https://github.com/openspug/spug.git
ARG SPUG_REF=3.0

RUN apk add --no-cache git && \
    git clone --depth 1 --branch "${SPUG_REF}" "${SPUG_REPO}" /tmp/spug && \
    cp -r /tmp/spug/spug_web/. /build/ && \
    npm config set registry https://registry.npmmirror.com && \
    npm install --legacy-peer-deps --no-audit --no-fund && \
    GENERATE_SOURCEMAP=false npm run build

### 运行时镜像阶段（后端 Python 环境 + Nginx + Supervisor）
FROM ubuntu:22.04

ARG SPUG_REPO=https://github.com/openspug/spug.git
ARG SPUG_REF=3.0

ENV TZ=Asia/Shanghai \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

# 1. 基础包（使用清华源）
RUN sed -i 's|http://.*archive.ubuntu.com|http://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list && \
    sed -i 's|http://.*security.ubuntu.com|http://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    sed -i 's|http://mirrors.tuna.tsinghua.edu.cn|https://mirrors.tuna.tsinghua.edu.cn|g' /etc/apt/sources.list && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        tzdata locales \
        gcc g++ make \
        python3 python3-dev python3-pip \
        default-libmysqlclient-dev libldap2-dev libsasl2-dev \
        nginx supervisor \
        wget curl tar bzip2 gzip git unzip xz-utils \
        net-tools sshpass rsync && \
    rm -rf /var/lib/apt/lists/*

# 2. 配置 locale
RUN locale-gen en_US.UTF-8

# 3. 从 GitHub 拉取 Spug 源码（后端）
RUN git clone --depth 1 --branch "${SPUG_REF}" "${SPUG_REPO}" /tmp/spug

# 4. 安装 Python 包（使用清华源）
#   注意：单独安装 mysqlclient，提供 MySQLdb 模块给 Django 使用
RUN pip3 install --no-cache-dir --upgrade pip wheel setuptools -i https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip3 install --no-cache-dir "setuptools<81" -i https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip3 install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple -r /tmp/spug/spug_api/requirements.txt && \
    pip3 install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple "mysqlclient<2.2" && \
    pip3 install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple gunicorn

# 5. 复制 Spug 后端代码到运行目录
RUN mkdir -p /data/spug && \
    cp -r /tmp/spug/spug_api /data/spug/spug_api

# 6. 从前端构建阶段复制构建产物
COPY --from=frontend-builder /build/build /data/spug/spug_web/build

# 7. 清理编译工具，保留 git（Spug 运行时需要）和 MySQL/LDAP 运行时库
RUN apt-get purge -y gcc g++ make python3-dev && \
    apt-get autoremove -y --purge && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache /root/.pip

# =====================================================================
# 运行时外置：JDK/Node/Maven 通过挂载提供
# =====================================================================
WORKDIR /opt
RUN mkdir -p /opt/ext

# =====================================================================
# 复制版本切换脚本、创建目录、验证安装
# =====================================================================
COPY scripts/*.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh && \
    ln -sf /usr/local/bin/envctl.sh /usr/local/bin/useenv && \
    mkdir -p /data/repos /data/spug/spug_api /data/spug/spug_api/logs /data/spug/spug_web/build /opt/ext && \
    chmod +x /data/spug/spug_api/tools/*.sh 2>/dev/null || true && \
    echo 'source /usr/local/bin/envctl.sh 2>/dev/null || true' >> /root/.bashrc

# =====================================================================
# 拷贝配置文件和业务代码
# =====================================================================
COPY config/init_spug /usr/bin/
COPY config/nginx.conf /etc/nginx/
COPY config/ssh_config /etc/ssh/
COPY config/spug.ini /etc/supervisor/conf.d/spug.conf
COPY config/entrypoint.sh /

# =====================================================================
# 数据卷 & 端口 & 健康检查
# =====================================================================
VOLUME /data
EXPOSE 80

# 健康检查（检查 API 服务）
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://127.0.0.1:9001/api/account/user/info/ || exit 1

ENTRYPOINT ["/entrypoint.sh"]
