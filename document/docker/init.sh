#!/bin/bash

echo "📦 初始化挂载目录和权限中..."

CURRENT_UID=$(id -u)
CURRENT_GID=$(id -g)

DIRS=(
  ./mydata/mysql/data/db
  ./mydata/mysql/data/conf
  ./mydata/mysql/log

  ./mydata/redis/data

  ./mydata/nginx/conf
  ./mydata/nginx/html
  ./mydata/nginx/log

  ./mydata/rabbitmq/data
  ./mydata/rabbitmq/log

  ./mydata/elasticsearch/plugins
  ./mydata/elasticsearch/data

  ./mydata/logstash

  ./mydata/mongo/db
)

for dir in "${DIRS[@]}"; do
  mkdir -p "$dir"
done

echo "🛠️ 设置通用目录权限..."
chmod -R 775 ./mydata

echo "👤 设置目录属主为 UID=${CURRENT_UID}, GID=${CURRENT_GID}..."
chown -R "${CURRENT_UID}:${CURRENT_GID}" ./mydata 2>/dev/null || echo "⚠️ 无法设置属主为当前用户，忽略错误"

# Elasticsearch 要求 data 目录为 1000:1000
if command -v sudo >/dev/null 2>&1; then
  echo "⚙️ 设置 Elasticsearch data 属主为 1000:1000..."
  sudo chown -R 1000:1000 ./mydata/elasticsearch/data

  echo "🔒 设置 RabbitMQ 目录权限为 999:999..."
  sudo chown -R 999:999 ./mydata/rabbitmq
  sudo chmod -R 755 ./mydata/rabbitmq

  COOKIE="./mydata/rabbitmq/data/.erlang.cookie"
  if [ -f "$COOKIE" ]; then
    sudo chmod 600 "$COOKIE"
    sudo chown 999:999 "$COOKIE"
  fi
else
  echo "⚠️ 无 sudo 权限，跳过 RabbitMQ 和 Elasticsearch 权限设置，可能导致容器无法正常启动"
fi

# 写 logstash.conf
cat > ./mydata/logstash/logstash.conf <<'EOF'
input {
  tcp {
    mode => "server"
    host => "0.0.0.0"
    port => 4560
    codec => json_lines
    type => "debug"
  }
  tcp {
    mode => "server"
    host => "0.0.0.0"
    port => 4561
    codec => json_lines
    type => "error"
  }
  tcp {
    mode => "server"
    host => "0.0.0.0"
    port => 4562
    codec => json_lines
    type => "business"
  }
  tcp {
    mode => "server"
    host => "0.0.0.0"
    port => 4563
    codec => json_lines
    type => "record"
  }
}
filter{
  if [type] == "record" {
    mutate {
      remove_field => "port"
      remove_field => "host"
      remove_field => "@version"
    }
    json {
      source => "message"
      remove_field => ["message"]
    }
  }
}
output {
  elasticsearch {
    hosts => "localhost:9200"
    index => "mall-%{type}-%{+YYYY.MM.dd}"
  }
}
EOF

# 写 nginx.conf
cat > ./mydata/nginx/conf/nginx.conf <<'EOF'
worker_processes  1;

events {
    worker_connections  1024;
}

http {
    server {
        listen       80;
        server_name  localhost;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }
}
EOF

echo "✅ 初始化完成，请运行：docker-compose up -d"
