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
