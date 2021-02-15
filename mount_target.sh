RPI_SERIAL=$1

creation_output="$(kpartx -asv "/srv/backing-file-$RPI_SERIAL")"
loop_device="$(echo "$creation_output" \
	    | head -n 1 \
	        | sed -E 's/add map (loop[0-9]+)p.*/\1/')"

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


root_temp_dir="$(mktemp -d)"
mount "/dev/disk/by-uuid/${root_part_uuid}" "$root_temp_dir"
boot_temp_dir="$(mktemp -d)"
mount "/dev/disk/by-uuid/${boot_part_uuid}" "${boot_temp_dir}"

