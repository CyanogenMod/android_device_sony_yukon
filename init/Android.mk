#
# A preboot executable used to toggle between regular and recovery boots
# Define the device specific FOTA node with:
#     TARGET_DEV_BLOCK_FOTA_NUM := "NODE"
#

LOCAL_PATH:= $(call my-dir)

include $(CLEAR_VARS)

LOCAL_SRC_FILES := \
    init_exec.cpp \
    init_files.cpp \
    init_io.cpp \
    init_main.cpp \
    extract_ramdisk.cpp

LOCAL_CPPFLAGS := \
    -Wall \
    -Wextra \
    -Werror

LOCAL_CPPFLAGS += -DDEV_BLOCK_FOTA_NUM=\"$(TARGET_DEV_BLOCK_FOTA_NUM)\"

LOCAL_MODULE := init_sony
LOCAL_MODULE_TAGS := optional

LOCAL_MODULE_PATH := $(TARGET_ROOT_OUT)/sbin

LOCAL_REQUIRED_MODULES := init toybox_static
LOCAL_FORCE_STATIC_EXECUTABLE := true
LOCAL_STATIC_LIBRARIES := \
    libbase \
    libc \
    libelf \
    libz

LOCAL_CLANG := true

include $(BUILD_EXECUTABLE)

root_init      := $(TARGET_ROOT_OUT)/init
root_init_real := $(TARGET_ROOT_OUT)/init.real

	# If /init is a file and not a symlink then rename it to /init.real
	# and make /init be a symlink to /sbin/init.sh (which will execute
	# /init.real, if appropriate.
$(root_init_real): $(root_init) $(TARGET_ROOT_OUT)/sbin/init_sony $(PRODUCT_OUT)/utilities/toybox
	cp $(PRODUCT_OUT)/utilities/toybox $(TARGET_ROOT_OUT)/sbin/toybox
	$(hide) if [ ! -L $(root_init) ]; then \
	  echo "/init $(root_init) isn't a symlink"; \
	  mv $(root_init) $(root_init_real); \
	  ln -s sbin/init_sony $(root_init); \
	else \
	  echo "/init $(root_init) is already a symlink"; \
	fi

ALL_DEFAULT_INSTALLED_MODULES += $(root_init_real)

