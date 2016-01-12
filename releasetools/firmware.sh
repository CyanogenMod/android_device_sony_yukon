#!/sbin/sh

set -e

# Detect the model from the LTALabel partition
# This looks something like:
# 1284-8432_5-elabel-D5303-row.html
mkdir -p /lta-label
mount -t ext4 /dev/block/platform/msm_sdcc.1/by-name/LTALabel /lta-label
variant=`ls /lta-label/*.html | sed s/.*-elabel-// | sed s/-row.html// | tr -d '\n\r'`
umount /lta-label

# Set the variant as a prop
touch /vendor/build.prop
echo ro.fxp.variant=$variant >> /vendor/build.prop

# Symlink the correct modem blobs
basedir="/system/blobs/$variant/"
cd $basedir
find . -type f | while read file; do ln -s $basedir$file /system/etc/firmware/$file ; done

if [ ! -f "/system/etc/firmware/modem.mdt" ]; then
  exit 1
fi

exit 0

