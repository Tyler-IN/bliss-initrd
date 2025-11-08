#!/bin/sh
set -eu
export PATH=/sbin:/bin
[ -x /bin/busybox ] && /bin/busybox --install -s /bin

MAGISK=/magisk
APKBASE=${MAGISK}
[ -x "$MAGISK/magiskinit" ] || exit 0

# If overlay files exist, patch sepolicy/init.rc like the stock shim
inittmp=/android/dev
mkdir -p "$inittmp/.overlay/upper" "$inittmp/.overlay/work"
mount -t tmpfs tmpfs "$inittmp" || true

# bind helper for policy
bind_policy() {
  policy="$1"
  if [ -x "$MAGISK/magiskpolicy" ]; then
    "$MAGISK/magiskpolicy" --load "$policy" \
      --save "$inittmp/.overlay/policy" --magisk "allow * magisk_file lnk_file *" || true
    mount --bind "$inittmp/.overlay/policy" "$policy" || true
  fi
}

# If we’re running in ramdisk/rootfs (Android-x86 style), drop our files in place
if mount | grep -qE ' (rootfs|tmpfs) on /android '; then
  mount -o rw,remount /android || true
  mkdir -p /android/magisk
  # fix placeholders if needed
  [ -f "$MAGISK/overlay.sh" ] && sed -i "s|MAGISK_FILES_BASE|$MAGISK|g" "$MAGISK/overlay.sh"
  [ -f "$MAGISK/magisk.rc"   ] && sed -i "s|MAGISK_FILES_BASE|$MAGISK|g" "$MAGISK/magisk.rc"
  cp -a "$MAGISK/"* /android/magisk 2>/dev/null || true
  # splice our rc into android init.rc if present
  if [ -f "$MAGISK/magisk.rc" ] && [ -f /android/init.rc ]; then
    cat "$MAGISK/magisk.rc" >> /android/init.rc
  fi
fi

# Patch common sepolicy locations if they exist
if [ -f /android/system/vendor/etc/selinux/precompiled_sepolicy ]; then
  bind_policy /android/system/vendor/etc/selinux/precompiled_sepolicy
elif [ -f /android/sepolicy ]; then
  bind_policy /android/sepolicy
fi

# cleanup mount
umount -l "$inittmp" 2>/dev/null || true

exit 0
