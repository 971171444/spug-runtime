#!/bin/bash
#
set -e

if [ -e /root/.bashrc ]; then
    source /root/.bashrc
fi

if [ ! -d /data/spug/spug_api ]; then
#    git clone -b $SPUG_DOCKER_VERSION https://gitee.com/openspug/spug.git /data/spug
#    curl -o web.tar.gz https://cdn.spug.cc/spug/web_${SPUG_DOCKER_VERSION}.tar.gz
#    tar xf web.tar.gz -C /data/spug/spug_web/
#    rm -f web.tar.gz
    SECRET_KEY=$(< /dev/urandom tr -dc '!@#%^.a-zA-Z0-9' | head -c50)
    cat > /data/spug/spug_api/spug/overrides.py << EOF
import os


DEBUG = False
ALLOWED_HOSTS = ['127.0.0.1']
SECRET_KEY = '${SECRET_KEY}'

DATABASES = {
    'default': {
        'ATOMIC_REQUESTS': True,
        'ENGINE': 'django.db.backends.mysql',
        'NAME': os.environ.get('MYSQL_DATABASE'),
        'USER': os.environ.get('MYSQL_USER'),
        'PASSWORD': os.environ.get('MYSQL_PASSWORD'),
        'HOST': os.environ.get('MYSQL_HOST'),
        'PORT': os.environ.get('MYSQL_PORT'),
        'OPTIONS': {
            'charset': 'utf8mb4',
            'sql_mode': 'STRICT_TRANS_TABLES',
        }
    }
}

# Redis配置
REDIS_HOST = os.environ.get('REDIS_HOST', '127.0.0.1')
REDIS_PORT = os.environ.get('REDIS_PORT', '6379')
REDIS_DB = os.environ.get('REDIS_DB', '1')
REDIS_PASSWORD = os.environ.get('REDIS_PASSWORD', '')

from urllib.parse import quote

if REDIS_PASSWORD and REDIS_PASSWORD.strip():
    quoted_pwd = quote(REDIS_PASSWORD, safe='')
    redis_location = f"redis://:{quoted_pwd}@{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}"
    # channels_redis 有密码时使用字典格式
    redis_channel_host = {"address": f"redis://:{quoted_pwd}@{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}"}
else:
    redis_location = f"redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}"
    # channels_redis 无密码时使用元组格式
    redis_channel_host = (REDIS_HOST, int(REDIS_PORT))

CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": redis_location,
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        }
    }
}

CHANNEL_LAYERS = {
    "default": {
        "BACKEND": "channels_redis.core.RedisChannelLayer",
        "CONFIG": {
            "hosts": [redis_channel_host],
            "capacity": 1000,
            "expiry": 120,
        },
    },
}
EOF
fi

rm -f /var/run/supervisor.sock
export PYTHONWARNINGS=ignore:::pkg_resources
exec supervisord -n -c /etc/supervisor/supervisord.conf
