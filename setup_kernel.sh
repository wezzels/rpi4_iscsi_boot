KERNEL=kernel8
git clone --depth=1 https://github.com/raspberrypi/linux
cd linux
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- bcm2711_defconfig
cp ../config ./.config
make ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- Image modules dtbs
sudo make modules_install
sudo cp arch/arm64/boot/dts/*.dtb /boot/
sudo cp arch/arm64/boot/dts/overlays/*.dtb* /boot/overlays/
sudo cp arch/arm64/boot/dts/overlays/README /boot/overlays/
sudo cp arch/arm64/boot/Image /boot/$KERNEL.img
