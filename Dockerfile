# ======================
# Build & Runtime in one stage (为了 mysqlclient/ldap 安装稳定)
# 使用 Ubuntu 22.04 LTS (主流稳定，支持 Node.js 18/20，glibc 2.35)
# ======================
FROM ubuntu:22.04

ENV TZ=Asia/Shanghai \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    DEBIAN_FRONTEND=noninteractive

# 1. 先使用 http 源安装 ca-certificates，然后切换到清华源安装其他包
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

# 3. 安装 Python 包（使用清华源）
COPY spug_api/requirements.txt /tmp/requirements.txt

# 3. 安装 Python 包（使用清华源）
RUN pip3 install --no-cache-dir --upgrade pip wheel setuptools -i https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip3 install --no-cache-dir "setuptools<81" -i https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip3 install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple -r /tmp/requirements.txt && \
    pip3 install --no-cache-dir -i https://pypi.tuna.tsinghua.edu.cn/simple gunicorn

# 4. 清理编译工具和缓存
RUN echo -e '\n# Source definitions\n. /etc/profile\n' >> /root/.bashrc && \
    apt-get purge -y gcc g++ make && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache /root/.pip
# =====================================================================
# 2. 运行时外置：JDK/Node/Maven 通过挂载提供
#    镜像仅保留脚本，不预装任何 JDK/Node/Maven
#    挂载示例（宿主解压后）：
#      - /host/ext/jdk8:/opt/ext/jdk8:ro
#      - /host/ext/jdk17:/opt/ext/jdk17:ro
#      - /host/ext/jdk21:/opt/ext/jdk21:ro
#      - /host/ext/maven-3.9.11:/opt/ext/maven3.9:ro
#      - /host/ext/node20:/opt/ext/node20:ro
# =====================================================================
WORKDIR /opt
RUN mkdir -p /opt/ext

# =====================================================================
# 复制版本切换脚本、创建目录、验证安装
# =====================================================================
COPY script/*.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/*.sh && \
    ln -sf /usr/local/bin/usejdk.sh /usr/local/bin/usejdk && \
    ln -sf /usr/local/bin/usemvn.sh /usr/local/bin/usemvn && \
    ln -sf /usr/local/bin/usenode.sh /usr/local/bin/usenode && \
    mkdir -p /data/repos /data/spug/spug_api /data/spug/spug_web/build /opt/ext && \
    echo 'source /usr/local/bin/functions.sh 2>/dev/null || true' >> /root/.bashrc

# =====================================================================
# 拷贝配置文件和业务代码
# =====================================================================
COPY docs/docker/init_spug /usr/bin/
COPY docs/docker/nginx.conf /etc/nginx/
COPY docs/docker/ssh_config /etc/ssh/
COPY docs/docker/spug.ini /etc/supervisor/conf.d/spug.conf
COPY docs/docker/entrypoint.sh /
COPY spug_api/ /data/spug/spug_api/
COPY spug_web/build/ /data/spug/spug_web/build/

# =====================================================================
# 数据卷 & 端口
# =====================================================================
VOLUME /data
EXPOSE 80

ENTRYPOINT ["/entrypoint.sh"]
