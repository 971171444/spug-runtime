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
REDIS_PORT = os.environ.get("REDIS_PORT", "6379")
REDIS_DB = os.environ.get("REDIS_DB", "1")
REDIS_PASSWORD = os.environ.get("REDIS_PASSWORD", "")

if REDIS_PASSWORD and REDIS_PASSWORD.strip():
    quoted_pwd = quote(REDIS_PASSWORD, safe="")
    redis_location = f"redis://:{quoted_pwd}@{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}"
    # channels_redis 有密码时使用字典格式
    redis_channel_host = {
        "address": f"redis://:{quoted_pwd}@{REDIS_HOST}:{REDIS_PORT}/{REDIS_DB}"
    }
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


