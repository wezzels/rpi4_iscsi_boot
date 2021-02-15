TARGET_IQN="iqn.2021-01.k3s.geek.cluster:rpis"
NETWORK_SUBNET="192.168.0.255"
apt -y install kpartx pv open-iscsi initramfs-tools
touch /etc/iscsi/iscsi.initramfs
update-initramfs -v -k "$(uname -r)" -c
if grep -q iscsi "/etc/initramfs-tools/modules"; then

      echo "iscsi_boot_sysfs" >> /etc/initramfs-tools/modules
      echo "iscsi_tcp" >> /etc/initramfs-tools/modules
      echo "iscsi_ibft" >> /etc/initramfs-tools/modules
      echo "iscsi" >> /etc/initramfs-tools/modules
fi

echo 'ISCSI_AUTO=true' > /etc/iscsi/iscsi.initramfs

mkdir -p /tmp/bootpart/
cp -r /boot/ /tmp/bootpart/$(uname -r)/

apt -y install targetcli-fb dnsmasq cloud-guest-utils
targetcli /iscsi create "$TARGET_IQN"
targetcli saveconfig
mkdir -p /tftpboot/

cat >/etc/dnsmasq.conf <<EOF
conf-dir=/etc/dnsmasq.d
EOF

systemctl disable --now systemd-resolved
systemctl stop systemd-resolved
rm -f /etc/resolv.conf 

timestamp="(date +"%T")"
cp /etc/resolv.conf /etc/resolv.conf_${timestamp}
cat >/etc/resolv.conf <<EOF
nameserver 192.168.0.42
nameserver 92.168.0.1
search cbhat.wezzel.com
EOF

cat >/etc/dnsmasq.d/proxydhcp.conf <<EOF
port=0
dhcp-range=$NETWORK_SUBNET,proxy
log-dhcp
log-queries
enable-tftp
tftp-root=/tftpboot
pxe-service=0,"Raspberry Pi Boot   "
pxe-prompt="Boot Raspberry Pi", 1
dhcp-no-override
dhcp-reply-delay=1
EOF

echo "Is the config OK?"
dnsmasq --test
systemctl enable dnsmasq
systemctl restart dnsmasq
