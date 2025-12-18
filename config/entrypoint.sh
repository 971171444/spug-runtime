#!/bin/bash
# Spug Runtime 容器启动脚本（尽量简单稳定）
set -e

# 确保必要的目录存在
mkdir -p /data/spug/spug_api/logs /data/repos /var/run /var/log/supervisor

# 确保启动脚本有执行权限
chmod +x /data/spug/spug_api/tools/*.sh 2>/dev/null || true

# 验证关键文件存在
if [ ! -f /data/spug/spug_api/manage.py ]; then
    echo "❌ ERROR: /data/spug/spug_api/manage.py not found!"
    exit 1
fi

if [ ! -d /data/spug/spug_web/build ] || [ ! -f /data/spug/spug_web/build/index.html ]; then
    echo "⚠️  WARNING: Frontend build directory incomplete, but continuing..."
fi

# 清理旧的 supervisor socket
rm -f /var/run/supervisor.sock

# 设置 Python 警告
export PYTHONWARNINGS=ignore:::pkg_resources

# 等待数据库和 Redis 就绪（最多等待 30 秒）
echo "Waiting for dependencies to be ready..."
MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    # 检查数据库连接（如果配置了）
    if [ -n "${MYSQL_HOST:-}" ] && [ -n "${MYSQL_PORT:-}" ]; then
        if timeout 2 bash -c "echo > /dev/tcp/${MYSQL_HOST}/${MYSQL_PORT}" 2>/dev/null; then
            echo "✅ MySQL connection ready"
            break
        fi
    fi
    # 检查 Redis 连接（如果配置了）
    if [ -n "${REDIS_HOST:-}" ] && [ -n "${REDIS_PORT:-}" ]; then
        if timeout 2 bash -c "echo > /dev/tcp/${REDIS_HOST}/${REDIS_PORT}" 2>/dev/null; then
            echo "✅ Redis connection ready"
            break
        fi
    fi
    sleep 2
    WAITED=$((WAITED + 2))
done

# 启动 supervisor
echo "Starting Spug services..."
exec supervisord -n -c /etc/supervisor/supervisord.conf
