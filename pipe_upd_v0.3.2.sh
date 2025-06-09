cd /opt/popcache

systemctl stop popcache

rm -f pop
wget https://github.com/KrakeNocto/pipe/blob/main/pop-v0.3.2-linux-x64.tar.gz
tar -xvzf pop-v0.3.2-linux-x64.tar.gz
chmod +x pop

rm -f logs/*

systemctl start popcache && systemctl status popcache
