#IPTables Config Files
#!!!!!!!!EXECUTE AS ADMIN!!!!!!!!
#Clean the IP Tables
iptables -F
iptables -t nat -F
#Confirm that there are no current rules

#Create a list of alias
SMTP_IP=10.10.10.2
DNS_IP=10.10.10.2
DNS2_IP=193.137.16.175
WEB_IP=10.10.10.2
KERBEROS_IP=10.20.20.2
MAIL_IP=10.10.10.2
VPN_IP=10.10.10.2
FTP_IP=10.10.10.2
DATASTORE_IP=10.20.20.2
EXTERN_IP=172.16.121.133

iptables -t filter -A FORWARD -p icmp -s 10.10.10.0/24 -d 10.20.20.0/24 -j ACCEPT ##Checked
iptables -t filter -A FORWARD -p icmp -s 10.20.20.0/24 -d 10.10.10.0/24 -j ACCEPT ##Checked

#IntraNetwork Conf

##Exceptions
###DNS Resolution
####Internal
iptables -t filter -A FORWARD -p udp -s 10.20.20.0/24 -d $DNS_IP --dport 53 -j ACCEPT
iptables -t filter -A FORWARD -p udp -s $DNS_IP --sport 53 -d 10.20.20.0/24 -j ACCEPT
iptables -t filter -A FORWARD -p tcp -s 10.20.20.0/24 -d $DNS_IP --dport 53 -j ACCEPT
iptables -t filter -A FORWARD -p tcp -s $DNS_IP --sport 53 -d 10.20.20.0/24 -j ACCEPT
#External (Not done yet)


###SMTP
iptables -t filter -A FORWARD -p tcp -s 10.20.20.0/24 -d $SMTP_IP --dport 25 -j ACCEPT
iptables -t filter -A FORWARD -p tcp -s $SMTP_IP --sport 25 -d 10.20.20.0/24 -j ACCEPT

###POP & IMAP
iptables -A FORWARD -p tcp -s 10.20.20.0/24 -d $MAIL_IP --dport 143 -j ACCEPT
iptables -A FORWARD -p tcp -s $MAIL_IP --sport 143 -d 10.20.20.0/24 -j ACCEPT

iptables -A FORWARD -p tcp -s 10.20.20.0/24 -d $MAIL_IP --dport 110 -j ACCEPT
iptables -A FORWARD -p tcp -s $MAIL_IP --sport 110 -d 10.20.20.0/24 -j ACCEPT

###HTTP and HTTPS
iptables -A FORWARD -p tcp -s 10.20.20.0/24 -d $WEB_IP --dport 80 -j ACCEPT
iptables -A FORWARD -p tcp -s $WEB_IP --sport 80 -d 10.20.20.0/24 -j ACCEPT

iptables -A FORWARD -p tcp -s 10.20.20.0/24 -d $WEB_IP --dport 443 -j ACCEPT
iptables -A FORWARD -p tcp -s $WEB_IP --sport 443 -d 10.20.20.0/24  -j ACCEPT

###VPN
####Postgres
iptables -A FORWARD -p tcp -s $VPN_IP -d $DATASTORE_IP --dport 5432 -j ACCEPT
iptables -A FORWARD -p tcp -s $DATASTORE_IP --sport 5432 -d $VPN_IP -j ACCEPT

####Kerberos
iptables -A FORWARD -p tcp -s $VPN_IP -d $KERBEROS_IP --dport 88 -m connlimit --connlimit-upto 10 -j ACCEPT
iptables -A FORWARD -p tcp -s $KERBEROS_IP --sport 88 -d $VPN_IP -j ACCEPT


#Outside -> In (Using NAT)
##FTP 
###Active (20 for data , 21 for controls)
iptables -t nat -A PREROUTING -d $EXTERN_IP -i ens160 -p tcp --dport 21 -j DNAT --to-destination $FTP_IP
iptables -t nat -A PREROUTING -d $EXTERN_IP -i ens160 -p tcp --dport 20 -j DNAT --to-destination $FTP_IP
iptables -t nat -A POSTROUTING -s $FTP_IP -o ens160 -p tcp --sport 20 -j SNAT --to-source $EXTERN_IP
iptables -t nat -A POSTROUTING -s $FTP_IP -o ens160 -p tcp --sport 21 -j SNAT --to-source $EXTERN_IP

###Passive
iptables -t nat -A PREROUTING  -d $EXTERN_IP -p tcp --dport 1024:65535 -j DNAT --to $FTP_IP:1024-65535
iptables -A FORWARD -s $FTP_IP -p tcp --sport 1024:65535 -j ACCEPT
iptables -A OUTPUT -p tcp --sport 1024: --dport 1024: -m state --state ESTABLISHED -j ACCEPT
iptables -A INPUT -p tcp --sport 1024: --dport 1024: -m state --state ESTABLISHED,RELATED,NEW -j ACCEPT


##Drop all communications between networks, except
###Logger
#iptables -t filter -A FORWARD -p all -s 10.10.10.0/24 -d 10.20.20.0/24 -j LOG --log-prefix "default drop"
#iptables -t filter -A FORWARD -p all -s 10.20.20.0/24 -d 10.10.10.0/24 -j LOG --log-prefix "DEF DROP 2 -->"

#iptables -t filter -A FORWARD -p all -s 10.10.10.0/24 -d 10.20.20.0/24 -j DROP ##Checked
#iptables -t filter -A FORWARD -p all -s 10.20.20.0/24 -d 10.10.10.0/24 -j DROP ##Checked
 

## IN -> OUT
iptables -A FORWARD -p udp -s 10.20.20.0/24 --dport 53 -o ens160 -j ACCEPT
iptables -A FORWARD -p udp -d 10.20.20.0/24 --sport 53 -i ens160 -j ACCEPT
iptables -A FORWARD -p udp -s 10.20.20.0/24 -m multiport --dports 20,21,22,53,80,443 -o ens160 -j ACCEPT
iptables -A FORWARD -p udp -d 10.20.20.0/24 -m multiport --sports 20,21,22,53,80,443 -i ens160 -j ACCEPT

iptables -t nat -A POSTROUTING -p udp --sport 53 -o ens160 -j MASQUERADE
iptables -t nat -A POSTROUTING -p tcp -m multiport --sports 20,21,22,53,80,443 -o ens160 -j MASQUERADE
iptables -t nat -A POSTROUTING -p tcp --dport 1024: -o ens160 -j MASQUERADE

iptables -P FORWARD DROP

#List all rules applies 
iptables -L --line-numbers
iptables -L -t nat --line-numbers  