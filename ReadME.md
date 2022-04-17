# STI Ass 2 - IPTables + Snort Conf

## Network Topology
![Net Topology](./Imgs/topology.png)
http://blog.hakzone.info/posts-and-articles/ftp/configure-iptables-to-support-ftp-passive-transfer-mode/ 


TCP Sockets with netcat
Server 
nc -lp <port>
Client 
nc <ip> <port>
UCP Sockets with netcat
Server 
nc -ulp <port>
Client 
nc -u <ip> <port>

root@Router:/home/tldart# iptables -t nat -A POSTROUTING -p udp --dport domain -o ens160 -j MASQUERADE
root@Router:/home/tldart# iptables -t nat -F
root@Router:/home/tldart# iptables -A FORWARD -j drop
iptables v1.8.7 (nf_tables): Chain 'drop' does not exist
Try `iptables -h' or 'iptables --help' for more information.
root@Router:/home/tldart# iptables -P FORWARD DROP
root@Router:/home/tldart# iptables -P FORWARD ACCEPT
root@Router:/home/tldart# iptables -P FORWARD DROP
root@Router:/home/tldart# iptables -P FORWARD ACCEPT
root@Router:/home/tldart# iptables -t nat -A POSTROUTING -p udp --dport domain -o ens160 -j MASQUERADE
root@Router:/home/tldart# iptables -P FORWARD DROP