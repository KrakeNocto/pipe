min_am=600
max_am=86400

host=$(hostname)
ip=$(curl -s --max-time 5 https://2ip.ru | grep -oP '\d+\.\d+\.\d+\.\d+' || echo "0.0.0.0")
mac=$(cat /sys/class/net/$(ip route show default | awk '/default/ {print $5}')/address 2>/dev/null || echo "00:00:00:00:00:00")

id_str="${host}_${ip}_${mac}"
hash=$(echo -n "$id_str" | md5sum | awk '{print $1}')

# offset в пределах от 600 до 2640 секунд (от 5 до 20 минут)
offset=$(( (0x${hash:0:8} % 901) + 300 ))

random_am=$(shuf -i $min_am-$max_am -n 1)
total_sleep=$((random_am + offset))

echo "Pipe update after $total_sleep seconds"

sleep $total_sleep

cd /opt/popcache

systemctl stop popcache

rm -f pop
wget https://github.com/KrakeNocto/pipe/raw/refs/heads/main/pop
chmod +x pop

rm -f logs/*

systemctl start popcache && systemctl status popcache && ./pop -v
