#
# Creates the init.sh script used to toggle between regular and recovery boots
# on the shinano and aries devices.
#

LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE       := init.sh
LOCAL_MODULE_PATH  := $(TARGET_ROOT_OUT)/sbin
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_SRC_FILES    := init.sh
LOCAL_REQUIRED_MODULES := busybox init extract_elf_ramdisk
include $(BUILD_PREBUILT)

root_init      := $(TARGET_ROOT_OUT)/init
root_init_real := $(TARGET_ROOT_OUT)/init.real

	# If /init is a file and not a symlink then rename it to /init.real
	# and make /init be a symlink to /sbin/init.sh (which will execute
	# /init.real, if appropriate.
$(root_init_real): $(root_init)
	$(hide) echo "===== BEFORE ====="
	$(hide) ls -l $(TARGET_ROOT_OUT)
	$(hide) if [ ! -L $(root_init) ]; then \
	  echo "/init $(root_init) isn't a symlink"; \
	  mv $(root_init) $(root_init_real); \
	  ln -s sbin/init.sh $(root_init); \
	else \
	  echo "/init $(root_init) is already a symlink"; \
	fi
	$(hide) echo "===== AFTER ====="
	$(hide) ls -l $(TARGET_ROOT_OUT)
	$(hide) rm -f $(TARGET_ROOT_OUT)/sbin/sh
	$(hide) ln -s busybox $(TARGET_ROOT_OUT)/sbin/sh

ALL_DEFAULT_INSTALLED_MODULES += $(root_init_real)

include $(CLEAR_VARS)
LOCAL_MODULE       := busybox
LOCAL_MODULE_PATH  := $(TARGET_ROOT_OUT)/sbin
LOCAL_MODULE_CLASS := EXECUTABLES
LOCAL_SRC_FILES    := busybox
include $(BUILD_PREBUILT)

include $(CLEAR_VARS)
LOCAL_SRC_FILES := extract_elf_ramdisk.c
LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_STATIC_LIBRARIES := libelf libc libm libz
LOCAL_C_INCLUDES := \
	external/elfutils/0.153/libelf \
	external/zlib
LOCAL_CFLAGS := -g -c -W
LOCAL_MODULE := extract_elf_ramdisk
LOCAL_MODULE_TAGS := eng
LOCAL_MODULE_CLASS := RECOVERY_EXECUTABLES
LOCAL_MODULE_PATH := $(PRODUCT_OUT)/utilities
include $(BUILD_EXECUTABLE)

