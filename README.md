# README

## Usage

1. Build rootfs and device tree with Makefile. Run:

``` 
make DPDK_LIB=<DPDK_LIB_PATH>
```

2. Upload the images to a TFTP server and boot the kernel via U-Boot. Example:

```
dhcp; tftpboot 0x40000000 /maaxboard_terryb/linux_dpdk/Image; tftpboot 0x5f000000 /maaxboard_terryb/linux_dpdk/linux.dtb; tftpboot 0x4c000000 /maaxboard_terryb/linux_dpdk/initramfs.img; setenv bootargs "console=ttymxc0,115200 earlycon=ec_imx6q,0x30860000,115200 rootfstype=ext4 root=/dev/mmcblk0p2 rw rootwait debug"; booti 0x40000000 0x4c000000 0x5f000000
```
Note: the address of device tree should be high enough to avoid overwritting the rootfs.

3. Create VM with QEMU/KVM for benchmarking:

```
qemu-system-aarch64 -machine virt,gic-version=3 -cpu cortex-a53 \
        -nographic \
        -kernel guest_linux_image \
        -initrd guest_rootfs.cpio.gz \
        -serial mon:stdio \
        -netdev user,id=net0,hostfwd=udp::1235-:1235,hostfwd=tcp::8037-:8037,hostfwd=udp::5201-:5201,hostfwd=tcp::5201-:5201 \
        -device virtio-net-device,netdev=net0,mac=52:54:00:12:34:56 \
        -m 1024 \
        -enable-kvm
```
