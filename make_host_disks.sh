RPI_SERIAL=$1
newhostname=$RPI_SERIAL
echo "Configuring $RPI_SERIAL"
RPI_KERNEL_VERSION=`uname -r`
TARGET_IQN="iqn.2021-01.k3s.geek-${RPI_SERIAL}.cluster:rpis"
INITIATOR_IQN="iqn.2021-01.k3s.${RPI_SERIAL}.cluster.initiator:rpi-k3s"
BACKSTORE_SIZE="16G"
IMAGE_FILE="ubuntu-20.10-preinstalled-server-arm64+raspi.img"
STORAGE_MACHINE_IP="192.168.0.214"

apt -y install kpartx cloud-guest-utils

mkdir -p "/tftpboot/$RPI_SERIAL/"
cp -r "/tmp/bootpart/$RPI_KERNEL_VERSION/firmware/"* "/tftpboot/$RPI_SERIAL/"
#cp /tftpboot/$RPI_SERIAL/firmware/bootcode.bin /tftpboot/bootcode.bin
echo "initramfs initrd.img followkernel" \
    >> "/tftpboot/$RPI_SERIAL/config.txt"
cp /tftpboot/$RPI_SERIAL/vmlinuz /tftpboot/$RPI_SERIAL/vmlinux
#echo "arm_64bit=1" >> /tftpboot/$RPI_SERIAL/config.txt

targetcli /iscsi create "$TARGET_IQN"
targetcli saveconfig

targetcli /backstores/fileio create \
    "backstore-$RPI_SERIAL" \
    "/srv/backing-file-$RPI_SERIAL" \
    "$BACKSTORE_SIZE" \
    true \
    true
targetcli "/iscsi/$TARGET_IQN/tpg1/luns" create \
    "/backstores/fileio/backstore-$RPI_SERIAL"
targetcli "/iscsi/$TARGET_IQN/tpg1/acls" create \
    "$INITIATOR_IQN" \
    false
targetcli "/iscsi/$TARGET_IQN/tpg1/acls/$INITIATOR_IQN" create \
    0 \
    "/backstores/fileio/backstore-$RPI_SERIAL"
targetcli saveconfig

pv "$IMAGE_FILE" \
    | dd of="/srv/backing-file-$RPI_SERIAL" bs=4M conv=noerror,notrunc

boot_part_offset="$(($(/usr/bin/partx --nr 1 --output start --noheadings \
    "/srv/backing-file-$RPI_SERIAL") * 512))"
boot_part_uuid="$(blkid --probe --offset "$boot_part_offset" \
    --output value --match-tag UUID "/srv/backing-file-$RPI_SERIAL")"
root_part_offset="$(($(/usr/bin/partx --nr 2 --output start --noheadings \
    "/srv/backing-file-$RPI_SERIAL") * 512))"
root_part_uuid="$(blkid --probe --offset "$root_part_offset" \
    --output value --match-tag UUID "/srv/backing-file-$RPI_SERIAL")"

echo "boot UUID: ${boot_part_uuid}"
echo "boot offset: ${boot_part_offset}"
echo "root UUID: ${root_part_uuid}"
echo "root offset: ${root_part_offset}"

echo \
    dwc_otg.lpm_enable=0 \
    console=tty1 \
    rootfstype=ext4 \
    elevator=deadline \
    fsck.repair=yes \
    rootwait \
    cgroup_enable=cpuset \
    cgroup_memory=1 \
    cgroup_enable=memory \
    ip=::::rpi-k3s:eth0:dhcp \
    root=UUID=$root_part_uuid \
    ISCSI_INITIATOR=$INITIATOR_IQN \
    "ISCSI_TARGET_NAME=$TARGET_IQN" \
    "ISCSI_TARGET_IP=$STORAGE_MACHINE_IP" \
    ISCSI_TARGET_PORT=3260 \
    rw \
>"/tftpboot/$RPI_SERIAL/cmdline.txt"
#cp /tftpboot/$RPI_SERIAL/cmdline.txt /tftpboot/$RPI_SERIAL/firmware/cmdline.txt
apt -y install cloud-guest-utils

creation_output="$(kpartx -asv "/srv/backing-file-$RPI_SERIAL")"
loop_device="$(echo "$creation_output" \
    | head -n 1 \
    | sed -E 's/add map (loop[0-9]+)p.*/\1/')"
growpart "/dev/$loop_device" 2
partprobe "/dev/$loop_device"

boot_part_offset="$(($(/usr/bin/partx --nr 1 --output start --noheadings \
    "/srv/backing-file-$RPI_SERIAL") * 512))"
boot_part_uuid="$(blkid --probe --offset "$boot_part_offset" \
    --output value --match-tag UUID "/srv/backing-file-$RPI_SERIAL")"
root_part_offset="$(($(/usr/bin/partx --nr 2 --output start --noheadings \
    "/srv/backing-file-$RPI_SERIAL") * 512))"
root_part_uuid="$(blkid --probe --offset "$root_part_offset" \
    --output value --match-tag UUID "/srv/backing-file-$RPI_SERIAL")"
echo "THESE ARE THE UUIDS"
echo "boot UUID: ${boot_part_uuid}"
echo "boot offset: ${boot_part_offset}"
echo "root UUID: ${root_part_uuid}"
echo "root offset: ${root_part_offset}"


e2fsck -f -v -p "/dev/disk/by-uuid/${root_part_uuid}"
resize2fs "/dev/disk/by-uuid/${root_part_uuid}"
root_temp_dir="$(mktemp -d)"
mount "/dev/disk/by-uuid/${root_part_uuid}" "$root_temp_dir"
#sed -E -i \
#    "s|.*/boot.*|UUID=${boot_part_uuid} /boot vfat defaults 0 2|" \
#    "$root_temp_dir/etc/fstab"
#sed -E -i \
#    "s|.*/ +.*|UUID=${root_part_uuid} / ext4 defaults,noatime 0 1|" \
#    "$root_temp_dir/etc/fstab"
###Add root customizations
echo "${newhostname}" > ${root_temp_dir}/etc/hostname

###

umount "$root_temp_dir"
rmdir "$root_temp_dir"

boot_temp_dir="$(mktemp -d)"
mount "/dev/disk/by-uuid/${boot_part_uuid}" "${boot_temp_dir}"
###Add boot 
touch ${boot_temp_dir}/ssh
###
umount "$boot_temp_dir"
rmdir "$boot_temp_dir"

kpartx -dv "/srv/backing-file-${RPI_SERIAL}"

