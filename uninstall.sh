#!/system/bin/sh
# Runs when the module is removed. Drops the engine list so Play Store sees the
# apps again after the reboot.

rm -f /data/adb/zygisk-detach/detach.bin
rm -f /data/adb/zygisk-detach/autodetach.txt
am force-stop com.android.vending >/dev/null 2>&1
