RPI_SERIAL=$1
echo "Delete $RPI_SERIAL"
TARGET_IQN="iqn.2021-01.k3s.geek-${RPI_SERIAL}.cluster:rpis"
INITIATOR_IQN="iqn.2021-01.k3s.${RPI_SERIAL}.cluster.initiator:rpi-k3s"
#targetcli ls
#targetcli /iscsi ls
targetcli /iscsi delete ${TARGET_IQN}
targetcli /backstores/fileio delete backstore-$RPI_SERIAL
rm -f /srv/backing-file-${RPI_SERIAL}
