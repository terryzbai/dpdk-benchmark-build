BUILD_DIR ?= build
TOOL_DIR=$(abspath .)

ifeq ($(strip $(DPDK_LIB)),)
$(info DPDK_LIB must be specified)
endif

vpath %.c src/
CC_USERLEVEL := zig cc
CFLAGS_USERLEVEL := \
	-g3 \
	-O3 \
	-Wno-unused-command-line-argument \
	-Wall -Wno-unused-function \
	-D_GNU_SOURCE \
	-target aarch64-linux-gnu \

HOST_ETC_FILES := $(addprefix $(BUILD_DIR)/, profile)
HOST_USER_EXECUTABLES := $(addprefix $(BUILD_DIR)/, echoit guest_linux_image guest_rootfs.cpio.gz sshd_config test_dpdk_app)

GUEST_ETC_FILES := $(addprefix $(BUILD_DIR)/, profile)
GUEST_USER_EXECUTABLES := $(addprefix $(BUILD_DIR)/, echoit test_dpdk_app dpdk_devbind.py)

all: $(BUILD_DIR)/host_initramfs.img $(BUILD_DIR)/host_linux.dtb

$(BUILD_DIR):
	mkdir -p $@

$(BUILD_DIR)/echoit.o: $(TOOL_DIR)/src/echoit.c |$(BUILD_DIR)
	$(CC_USERLEVEL) $(CFLAGS_USERLEVEL) -o $@ -c $<

$(BUILD_DIR)/echoit: $(BUILD_DIR)/echoit.o |$(BUILD_DIR)
	$(CC_USERLEVEL) -static $(CFLAGS_USERLEVEL) $< -o $@

$(BUILD_DIR)/profile: $(TOOL_DIR)/etc/profile |$(BUILD_DIR)
	cp $< $@

$(BUILD_DIR)/test_dpdk_app: $(TOOL_DIR)/src/test_dpdk_app |$(BUILD_DIR)
	cp $< $@

$(BUILD_DIR)/dpdk_devbind.py: $(TOOL_DIR)/src/dpdk_devbind.py
	cp $< $@

$(BUILD_DIR)/sshd_config: $(TOOL_DIR)/etc/sshd_config |$(BUILD_DIR)
	cp $< $@

# HOST rootfs includes:
#   - etc/profile
#   - iperf3
#   - ipbench2
#   - dpdk
#   - qemu
#   - echoserver
#   - Guest rootfs (.cpio.gz)
#   - Guest Linux Image
$(BUILD_DIR)/host_rootfs.cpio.gz: $(TOOL_DIR)/host_rootfs.cpio.gz $(HOST_ETC_FILES) $(HOST_USER_EXECUTABLES) |$(BUILD_DIR)
	$(TOOL_DIR)/packrootfs $(TOOL_DIR)/host_rootfs.cpio.gz \
	    host_rootfs -o $@ \
	    --home $(HOST_USER_EXECUTABLES) \
	    --etc $(HOST_ETC_FILES)

# $(BUILD_DIR)/host_linux.dtb: $(TOOL_DIR)/host_linux.dts |$(BUILD_DIR)
# 	dtc -q -I dts -O dtb $< > $@

$(BUILD_DIR)/host_linux.dtb: $(BUILD_DIR)/host_linux.dts |$(BUILD_DIR)
	dtc -q -I dts -O dtb $< > $@

$(BUILD_DIR)/host_linux.dts: $(TOOL_DIR)/host_linux.dts $(TOOL_DIR)/host_overlay.dts |$(BUILD_DIR)
	$(TOOL_DIR)/dtscat $^ > $@


# Geust rootfs includes:
#   - etc/profile
#   - iperf3
#   - ipbench2
#   - dpdk
#   - echoserver
$(BUILD_DIR)/guest_rootfs.cpio.gz: $(TOOL_DIR)/guest_rootfs.cpio.gz $(GUEST__ETC_FILES) $(GUEST_USER_EXECUTABLES) |$(BUILD_DIR)
	$(TOOL_DIR)/packrootfs $(TOOL_DIR)/guest_rootfs.cpio.gz \
	    guest_rootfs -o $@ \
	    --home $(GUEST_USER_EXECUTABLES) \
	    --etc $(GUEST_ETC_FILES) \
	    --lib $(DPDK_LIB)

$(BUILD_DIR)/guest_linux_image: $(TOOL_DIR)/guest_linux_image |$(BUILD_DIR)
	cp $< $@


$(BUILD_DIR)/%_initramfs.img: $(BUILD_DIR)/%_rootfs.cpio.gz |$(BUILD_DIR)
	mkimage -A arm -O linux -T ramdisk -n "Initial Ram Disk" -d $< $@
	rm -rf $(TOOL_DIR)/host_rootfs
	rm -rf $(TOOL_DIR)/guest_rootfs

clean:
	rm -rf $(BUILD_DIR)
