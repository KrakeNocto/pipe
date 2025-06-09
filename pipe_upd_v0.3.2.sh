cd /opt/popcache

systemctl stop popcache

rm -f pop
wget https://github.com/KrakeNocto/pipe/raw/refs/heads/main/pop
chmod +x pop

rm -f logs/*

systemctl start popcache && systemctl status popcache && ./pop -v
