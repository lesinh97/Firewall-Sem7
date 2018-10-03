#!/bin/bash
# Khai bao PATH - Path declare
PATH=/sbin:/usr/sbin:/bin:/usr/bins
#####################################
# Khai bao cac service port, neu khong khai bao thi dung so port - Port declare
SSH=22
FTP=20,21
DNS=53
SMTP=25,465,587
POP3=110,995
IMAP=143,993
HTTP=80,443
IDENT=113
NTP=123
MYSQL=3306
NET_BIOS=135,137,138,139,445
DHCP=67,68
#####################################
# Ham inintialize
inintialize() {
  iptables -F # khoi tao table - flush all rules
  iptables -X # xoa cac chain hien tai - delete all current chain
  iptables -Z # xoa packet counter va byte counter - clear the counter
  iptables -P INPUT   ACCEPT # tao accept chain cac input (cho phep traffic o tat ca cong)
  iptables -P OUTPUT  ACCEPT
  iptables -P FORWARD ACCEPT
}
# ham final thuc thi sau khi cac quy tac duoc thiet lap - Process after rule application
finalize()
{
  /etc/init.d/iptables save && # Luu setting vao thu muc config cuar iptables
  /etc/init.d/iptables restart && # Khoi dong lai iptables
  return 0
  return 1
}

if [ "$1" == "dev" ]
then
  iptables() { echo "iptables $@"; }
  finailize() { echo "finailize"; }
fi

# Init iptables
initialize

# Xac dinh cac policy truy cap - Determining policies
iptables -P INPUT   DROP  # *Neu khong drop truoc thi k the thuc hien duoc - Dang tim nguyen nhan
iptables -P OUTPUT  ACCEPT
iptables -P FORWARD DROP

# localhost
# Tham chieu den host rieng cua no o local loopback
iptables -A INPUT -i lo -j ACCEPT # SELF -> SELF

if [ "$LOCAL_NET" ]
# Neu bien LOCAL_NET duoc thiet lap se cho phep giao tiep voi cac server khac trong LAN
# When $ LOCAL_NET is set, it permits communication with other servers on the LAN
then
  iptables -A INPUT -p tcp -s $LOCAL_NET -j ACCEPT # LOCAL_NET -> SELF
fi

# Ket thuc phan set cho localhost - localhost end

# Cac host tin cay - trusted host
if [ "${ALLOW_HOSTS}" ]
# Neu ALLOW_HOSTS duoc thiet lap, cho phep host duoc phep truy cap
# If $ALLOW_HOSTS is set, permission to the host is permitted
then
  for allow_host in ${ALLOW_HOSTS[@]}
  do
    iptables -A INPUT -p tcp -s $allow_host -j ACCEPT # allow_host -> SELF
  done
fi

# Ket thuc phan set cho ALLOW_HOST - ALLOW_HOST end

if [ "${DENY_HOSTS}" ]
# just deny it :))
then
  for deny_host in ${DENY_HOSTS[@]}
  do
    iptables -A INPUT -s $deny_host -m limit --limit 1/s -j LOG --log-prefix "deny_host: "
    iptables -A INPUT -s $deny_host -j DROP
  done
fi

# Ket thuc phan set cho DENY_HOST, DENY HOST end


