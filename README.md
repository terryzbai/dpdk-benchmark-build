# README

## Usage

1. Build rootfs and device tree with Makefile. Run:

``` 
make
```

2. Upload the images to a TFTP server and boot the kernel via U-Boot. Example:

```
dhcp; tftpboot 0x40000000 /maaxboard_terryb/linux_dpdk/Image; tftpboot 0x5f000000 /maaxboard_terryb/linux_dpdk/linux.dtb; tftpboot 0x4c000000 /maaxboard_terryb/linux_dpdk/initramfs.img; setenv bootargs "console=ttymxc0,115200 console=tty1 fbcon=rotate:0 rootfstype=ext4 root=/dev/mmcblk0p2 rw rootwait debug"; booti 0x40000000 0x4c000000 0x5f000000
```
Note: the address of device tree should be high enough to avoid overwritting the rootfs.
