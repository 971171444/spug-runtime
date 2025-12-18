import os
from urllib.parse import quote

# 生产环境建议关闭 DEBUG
DEBUG = False
ALLOWED_HOSTS = ["*"]

# 如果不想在文件里写死 SECRET_KEY，可以通过环境变量传入
SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY", "change-me-please")

# 外部 MySQL，通过环境变量注入连接信息
DATABASES = {
    "default": {
        "ATOMIC_REQUESTS": True,
        "ENGINE": "django.db.backends.mysql",
        "NAME": os.environ.get("MYSQL_DATABASE"),
        "USER": os.environ.get("MYSQL_USER"),
        "PASSWORD": os.environ.get("MYSQL_PASSWORD"),
        "HOST": os.environ.get("MYSQL_HOST"),
        "PORT": os.environ.get("MYSQL_PORT"),
        "OPTIONS": {
            "charset": "utf8mb4",
            "sql_mode": "STRICT_TRANS_TABLES",
        },
    }
}

# 外部 Redis
REDIS_HOST = os.environ.get("REDIS_HOST", "127.0.0.1")
REDIS_PORT = int(os.environ.get("REDIS_PORT", "6379"))
REDIS_DB = int(os.environ.get("REDIS_DB", "1"))
REDIS_PASSWORD = os.environ.get("REDIS_PASSWORD", "")

# django-redis 缓存配置（使用 URL 格式）
if REDIS_PASSWORD and REDIS_PASSWORD.strip():
    quoted_pwd = quote(REDIS_PASSWORD, safe="")
    redis_location = f"redis://:{quoted_pwd}@{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}"
else:
    redis_location = f"redis://{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}"

# channels_redis 配置（WebSocket 使用）
# channels_redis 需要明确的 host, port, password, db 参数
if REDIS_PASSWORD and REDIS_PASSWORD.strip():
    # 有密码时使用字典格式，分别指定参数
    redis_channel_host = {
        "address": (REDIS_HOST, REDIS_PORT),
        "password": REDIS_PASSWORD,  # 直接使用原始密码，不需要 URL 编码
        "db": REDIS_DB,
    }
else:
    # 无密码时也使用字典格式，确保 db 参数正确传递
    redis_channel_host = {
        "address": (REDIS_HOST, REDIS_PORT),
        "db": REDIS_DB,
    }

CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": redis_location,
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        },
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


