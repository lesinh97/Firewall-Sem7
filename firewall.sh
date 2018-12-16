#!/bin/bash
# Khai báo PATH - Path declare
PATH=/sbin:/usr/sbin:/bin:/usr/bins
#####################################
# Khai báo các service port, mục đích làm script dễ đọc thôi - Port declare
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
  /etc/init.d/iptables save && # Luu setting vao thu muc config cua iptables
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

# Trao doi packet duoc cho phep sau khi viec khoi tao session thanh cong
# Packet communication after session establishment is permitted

iptables -A INPUT  -p tcp -m state --state ESTABLISHED,RELATED -j ACCEPT
########################################################################
# Chong lai steath scan - steath scan attack measures -nmap

iptables -N STEALTH_SCAN # Tao moi chain "STEAlTH_SCAN" - make a chain
iptables -A STEALTH_SCAN -j LOG --log-prefix "stealth_scan_attack: "
iptables -A STEALTH_SCAN -j DROP
# Chuyen qua chain "STEALTH_SCAN" cho nhung packet da duoc stealth scan
# Jump to the "STEALTH_SCAN" chain for stealth scanned packets
iptables -A INPUT -p tcp --tcp-flags SYN,ACK SYN,ACK -m state --state NEW -j STEALTH_SCAN

iptables -A INPUT -p tcp --tcp-flags SYN,FIN SYN,FIN         -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST         -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j STEALTH_SCAN

iptables -A INPUT -p tcp --tcp-flags FIN,RST FIN,RST -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,FIN FIN     -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,PSH PSH     -j STEALTH_SCAN
iptables -A INPUT -p tcp --tcp-flags ACK,URG URG     -j STEALTH_SCAN
#########################################################################
# Chong lai ping of death
# Thuat toan la cu tu choi dich vao co hon 1ping/s
# Discard if more than 1 ping per second lasts ten times
iptables -N PING_OF_DEATH # Make chain with the name "PING_OF_DEATH"
iptables -A PING_OF_DEATH -p icmp --icmp-type echo-request \
         -m hashlimit \
         --hashlimit 1/s \
         --hashlimit-burst 10 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_PING_OF_DEATH \
         -j RETURN

# Doc cheat sheet o README.md
# Tu choi nhung ICMP vuot qua gioi han
iptables -A PING_OF_DEATH -j LOG --log-prefix "ping_of_death_attack: "
iptables -A PING_OF_DEATH -j DROP

# Nhay den chain POD
iptables -A INPUT -p icmp --icmp-type echo-request -j PING_OF_DEATH

#########################################################################
# Chong lai SYN FLOOD - Counter SYN FLOOD
# Nen bat SYN Cookie - Should turn on SYN cookie in addtion.
iptables -N SYN_FLOOD # Make chain with the name "SYN_FLOOD"
iptables -A SYN_FLOOD -p tcp --syn \
         -m hashlimit \
         --hashlimit 200/s \
         --hashlimit-burst 3 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_SYN_FLOOD \
         -j RETURN

# Huy cac goi SYN vuot qua gioi han
# Discard SYN packet exceeding limit
iptables -A SYN_FLOOD -j LOG --log-prefix "syn_flood_attack: "
iptables -A SYN_FLOOD -j DROP

# Nhay den chain SYN_FLOOD
# SYN packet jumps to "SYN_FLOOD" chain
iptables -A INPUT -p tcp --syn -j SYN_FLOOD

#########################################################################
# Chong lai HTTP/Dos - DDos
# Counter HTTP/Dos - DDos
ptables -N HTTP_DOS # Make chain with the name "HTTP_DOS"
iptables -A HTTP_DOS -p tcp -m multiport --dports $HTTP \
         -m hashlimit \
         --hashlimit 1/s \
         --hashlimit-burst 100 \
         --hashlimit-htable-expire 300000 \
         --hashlimit-mode srcip \
         --hashlimit-name t_HTTP_DOS \
         -j RETURN

# Huy ket noi vuot qua gioi han
# Discard connection exceeding limit
iptables -A HTTP_DOS -j LOG --log-prefix "http_dos_attack: "
iptables -A HTTP_DOS -j DROP

# Nhay den chain HTTP_DOS
# Packets to HTTP jump to "HTTP_DOS" chain
iptables -A INPUT -p tcp -m multiport --dports $HTTP -j HTTP_DOS

###########################################################
# Counter: IDENT port probe
# Use ident to allow an attacker to prepare for future attacks,
# Perform a port survey to see if the system is vulnerable
# As DROP reduces responses of mail servers etc REJECT
###########################################################
iptables -A INPUT -p tcp -m multiport --dports $IDENT -j REJECT --reject-with tcp-reset

###########################################################
# Allow input from specific host
###########################################################

###########################################################
# Other than that
# Those which also did not apply to the above rule logging and discarding
###########################################################
iptables -A INPUT  -j LOG --log-prefix "drop: "
iptables -A INPUT  -j DROP

###########################################################
# SSH lockout workaround
# Sleep for 30 seconds and then reset iptables.
# If SSH is not locked out, you should be able to press Ctrl - C.
###########################################################
trap 'finailize && exit 0' 2 # Ctrl - C if you want
echo "In 30 seconds iptables will be automatically reset."
echo "Don't forget to test new SSH connection!"
echo "If there is no problem then press Ctrl-C to finish."
sleep 30
echo "rollback..."
initialize




