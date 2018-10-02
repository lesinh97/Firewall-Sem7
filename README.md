# iptables scripts
## Some script features
 Basically destroy reception and handover, also designate to allow with a whitelist.
 Allow basically about sending. However, since there is a possibility of troubling an external server when the server becomes a stepping stone,
 If you are worried, you can rewrite the transmission as well as basic discard / whitelist as well.

## iptables common arguments
Prefixs | Features
------- | -------
-A,--append | Add one or more new rules to the specified chain
-D,--delete | Delete one or more rules from specified chain
-P, --policy| Set policy of designated chain to specified target
-N, --new-chain| Create a new user-defined chain
-X, --delete-chain | Delete specified user-defined chain
-F    | Table initialization
-p, --protocol | Specify protocol protocol (tcp, udp, icmp, all)
-s,  - source IP address [/ mask] | Source address. Describe IP address or host name
-d, - destination IP address [/ mask] | Address of the destination. Describe IP address or host name
-i , - in - interface | Specifies the interface on which the device packet comes in
-o, - out - interface | Specify the interface on which the device packet appears
-j, --jump | Specify action when matching target condition
-t, --table | Specify table table
-m state - state state | Specify condition of packet as condition
! | Invert the condition (except for ~)
 State can be NEW, ESTABLISHED, RELATED, INVALID
