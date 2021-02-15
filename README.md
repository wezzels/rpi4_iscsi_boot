
Usage:  Create a ISCSI and TFTP server

  sudo ./make_server_iscsi_target.sh
  
Create a ISCSI lun for a raspberry pi.
        
  sudo ./make_host_disks.sh <Serial of the booting PI.>

Tools:

  del_iscsi_lun.sh <Serial of the booting PI.>

  get_serial.sh 
  
  mount_target.sh <Serial of the booting PI.>
  
  show_disk.sh <Serial of the booting PI.>
  
  umount_target.sh 


Where Information and processes came from.

    https://software.fujitsu.com/jp/manual/manualfiles/m170005/j2ul2107/02enz203/j2107-00-09-06-03.html
    https://tech.xlab.si/blog/pxe-boot-raspberry-pi-iscsi/
    https://shawnwilsher.com/2020/05/network-booting-a-raspberry-pi-4-with-an-iscsi-root-via-freenas/
    https://opensource.com/article/20/3/kubernetes-raspberry-pi-k3s

