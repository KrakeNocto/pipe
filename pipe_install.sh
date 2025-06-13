#!/bin/bash

min_am=7200
max_am=64800

host=$(hostname)
ip=$(curl -s --max-time 5 https://2ip.ru | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "0.0.0.0")
mac=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address 2>/dev/null || echo "00:00:00:00:00:00")

id_str="${host}_${ip}_${mac}"
hash=$(echo -n "$id_str" | md5sum | awk '{print $1}')

# offset в пределах от 600 до 2640 секунд (от 10 до 44 минут)
offset=$(( (0x${hash:0:8} % 2041) + 600 ))

random_am=$(shuf -i $min_am-$max_am -n 1)
total_sleep=$((random_am + offset))

echo "Installing Pipe Testnet Node after $total_sleep seconds"

sleep $total_sleep

mkdir -p /opt/popcache
mkdir -p /opt/popcache/logs
cd /opt/popcache

wget https://github.com/KrakeNocto/pipe/raw/refs/heads/main/pop
chmod +x pop

DISK_SIZE=$(( RANDOM % 21 + 15 ))
MEMORY_SIZE=$(( RANDOM % 626 + 4096 ))

# Создание файла config.json с подстановкой переменных окружения
cat <<EOF > /opt/popcache/config.json
{
  "pop_name": "${POP_NAME}",
  "pop_location": "${POP_LOCATION}",
  "invite_code": "${POP_INVITE}",
  "server": {
    "host": "0.0.0.0",
    "port": 443,
    "http_port": 80,
    "workers": 3
  },
  "cache_config": {
    "memory_cache_size_mb": ${MEMORY_SIZE},
    "disk_cache_path": "./cache",
    "disk_cache_size_gb": ${DISK_SIZE},
    "default_ttl_seconds": 86400,
    "respect_origin_headers": true,
    "max_cacheable_size_mb": 1024
  },
  "api_endpoints": {
    "base_url": "https://dataplane.pipenetwork.com"
  },
  "identity_config": {
    "node_name": "${POP_NAME}",
    "name": "${POP_NAME}",
    "email": "${POP_EMAIL}",
    "website": "",
    "twitter": "${POP_X}",
    "discord": "${POP_DISCORD}",
    "telegram": "",
    "solana_pubkey": "${POP_SOLANA_PUBKEY}"
  }
}
EOF

sudo tee /etc/systemd/system/popcache.service > /dev/null <<EOF
[Unit]
Description=POP Cache Node
After=network.target

[Service]
Type=simple
User=root
Group=root
WorkingDirectory=/opt/popcache
ExecStart=/opt/popcache/pop
Restart=always
RestartSec=5
LimitNOFILE=65535
StandardOutput=append:/opt/popcache/logs/stdout.log
StandardError=append:/opt/popcache/logs/stderr.log
Environment=POP_CONFIG_PATH=/opt/popcache/config.json

[Install]
WantedBy=multi-user.target
EOF

systemctl stop pop && systemctl disable pop
systemctl daemon-reload && systemctl enable popcache && systemctl start popcache
systemctl status popcache
