RPI_SERIAL=$1

for dir in $(mount | grep loop | cut -f3 -d" ")
do
	echo "dir is: $dir"
        umount "$dir"
	rmdir "$dir"
done

