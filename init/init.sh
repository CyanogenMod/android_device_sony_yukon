#!/sbin/busybox sh
set +x
_PATH="$PATH"
export PATH=/sbin

cd /

LOG=boot.txt

busybox date >> ${LOG}
exec >> ${LOG} 2>&1
set -x
busybox rm /init

busybox mkdir -m 755 -p /cache
busybox mkdir -m 555 -p /proc
busybox mount -t proc proc /proc

busybox mkdir -m 755 -p /sys
busybox mount -t sysfs sysfs /sys

busybox mknod -m 666 /dev/null c 1 3

# include device specific vars
source /sbin/bootrec-device

# Check the cmdline if the OS asked us to boot into recovery mode
# See kernel/arch/arm/mach-msm/restart.c (msm_restart_prepare function) for
# a mapping of reboot modes to constants.
warmboot_recovery=0x77665502

if busybox grep -q warmboot=${warmboot_recovery} /proc/cmdline; then
  echo "Entering Recovery mode" >> ${LOG}
  busybox mkdir -m 755 -p /dev/block
  busybox mknod -m 600 ${BOOTREC_FOTA_NODE}
  busybox mount -o remount,rw /
  busybox ln -sf /sbin/busybox /sbin/sh
  extract_elf_ramdisk -i ${BOOTREC_FOTA} -o /recovery.cpio -t /
  busybox rm /sbin/sh
  busybox rm init*.rc init*.sh 
  busybox cpio -i -u < /recovery.cpio
  busybox rm init
  busybox rm /recovery.cpio
else
  echo "Booting Normally" >> ${LOG}
fi

echo "PATH=${PATH}" >> ${LOG}
echo "_PATH=${_PATH}" >> ${LOG}

busybox umount /proc
busybox umount /sys

busybox rm -rf /dev/*

busybox mv /init.real /init

busybox date >> ${LOG}
export PATH="${_PATH}"
exec /init
