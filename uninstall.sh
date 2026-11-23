#!/system/bin/sh
# Runs when the module is removed.
#
# Two cases:
#   zygisk-detach module present   restore the list it had before this module
#                                  touched it, so its own configuration works
#                                  again
#   no zygisk-detach module        drop the list, so Play Store sees the apps
#                                  again after the reboot

ZD_MOD=/data/adb/modules/zygisk-detach
BACKUP=$DATA/detach.bin.before-morphe-autodetach

rm -f "$DATA/autodetach.txt"

if [ -f "$BACKUP" ]; then
	mv -f "$BACKUP" "$DATA/detach.bin"
else
	rm -f "$DATA/detach.bin"
fi

am force-stop com.android.vending >/dev/null 2>&1
