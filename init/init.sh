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

LED_RED="/sys/class/leds/led:rgb_red/brightness"
LED_GREEN="/sys/class/leds/led:rgb_green/brightness"
LED_BLUE="/sys/class/leds/led:rgb_blue/brightness"

led_amber() {
  busybox echo 255 > ${LED_RED}
  busybox echo 255 > ${LED_GREEN}
  busybox echo   0 > ${LED_BLUE}
}

led_orange() {
  busybox echo 255 > ${LED_RED}
  busybox echo 100 > ${LED_GREEN}
  busybox echo   0 > ${LED_BLUE}
}

led_off() {
  busybox echo   0 > ${LED_RED}
  busybox echo   0 > ${LED_GREEN}
  busybox echo   0 > ${LED_BLUE}
}

KEY_EVENT=/dev/input/event2

busybox mkdir -m 755 /dev/input
busybox mknod -m 600 ${KEY_EVENT} c 13 67
busybox cat ${KEY_EVENT} > /dev/key-events &

led_amber

busybox sleep 3
busybox pkill -f "cat ${KEY_EVENT}"

# Check for key events, or being explicity asked to go into recovery mode
# See kernel/arch/arm/mach-msm/restart.c (msm_restart_prepare function) for
# a mapping of reboot modes to constants.
warmboot_recovery=0x77665502

if [ -s /dev/key-events ] || busybox grep -q warmboot=${warmboot_recovery} /proc/cmdline; then 
  echo "Entering Recovery mode" >> ${LOG}
  led_orange
  busybox mkdir -m 755 -p /dev/block
  busybox mknod -m 600 /dev/block/mmcblk0p16 b 179 16
  busybox mount -o remount,rw /
  busybox ln -sf /sbin/busybox /sbin/sh
  extract_elf_ramdisk -i /dev/block/mmcblk0p16 -o /recovery.cpio -t /
  busybox rm /sbin/sh
  #busybox mkdir /recovery
  #cd /recovery
  busybox rm init*.rc init*.sh 
  busybox cpio -i -u < /recovery.cpio
  busybox rm init
  busybox rm /recovery.cpio
  #cd /
  # adb shell seems to want sh to be in /system/bin/sh, and also wants
  # /system/bin to be in the PATH.
  busybox mkdir -p /system/bin
  for app in $(busybox --list); do
    busybox ln -s /sbin/busybox /system/bin/sh
  done
  export _PATH=${_PATH}:/system/bin
else
  echo "Booting Normally" >> ${LOG}
fi
led_off

echo "PATH=${PATH}" >> ${LOG}
echo "_PATH=${_PATH}" >> ${LOG}

busybox umount /proc
busybox umount /sys

busybox rm -rf /dev/*

busybox mv /init.real /init

busybox date >> ${LOG}
export PATH="${_PATH}"
exec /init
