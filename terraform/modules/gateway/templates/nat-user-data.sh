#!/bin/bash
dnf install -y iptables-services
systemctl enable --now iptables
echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/custom-ip-forwarding.conf
sysctl -p /etc/sysctl.d/custom-ip-forwarding.conf
IF=$(ip route show default | awk '{print $5; exit}')
iptables -t nat -A POSTROUTING -o "$IF" -j MASQUERADE
iptables -F FORWARD
service iptables save