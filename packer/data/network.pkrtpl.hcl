%{ if ipv4_address != null ~}
network --activate --bootproto=static --device=${device} --gateway=${ipv4_gateway} --ip=${ipv4_address} --nameserver=${join(",", dns)} --netmask=${cidrnetmask("${ipv4_address}/${ipv4_netmask}")} --noipv6 --onboot=yes
%{ else ~}
network --bootproto=dhcp --device=${device}
%{ endif ~}
