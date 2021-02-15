RPI_SERIAL=$1
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
