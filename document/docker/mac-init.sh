#!/bin/bash

echo "📦 初始化挂载目录和权限中..."

DIRS=(
  ./mydata/mysql/data/db
  ./mydata/mysql/data/conf
  ./mydata/mysql/log

  ./mydata/redis/data

  ./mydata/nginx/conf
  ./mydata/nginx/html
  ./mydata/nginx/log

  ./mydata/logstash

  ./mydata/mongo/db
)

# 只为非 volume 的组件建目录（RabbitMQ、ES 将用 named volume）
for dir in "${DIRS[@]}"; do
  mkdir -p "$dir"
done

echo "🛠️ 设置通用目录权限..."
chmod -R 777 ./mydata

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
    hosts => "http://elasticsearch:9200"
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
