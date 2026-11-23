#!/system/bin/sh
# Runs inside the Magisk / KernelSU installer.
#
# $MODPATH is the staging directory. $NVBASE is /data/adb. $MODID is this
# module id. All three are set by the installer.

chmod -R 755 "$MODPATH/bin"

# Keep the user files across a module update.
OLD=$NVBASE/modules/$MODID
for f in detach.txt skip.txt; do
	if [ -f "$OLD/$f" ]; then
		cp -f "$OLD/$f" "$MODPATH/$f"
		ui_print "- kept $f"
	fi
done

# The bundled engine is a Zygisk module. Zygisk must be on.
ZYGISK=0
if [ "$(magisk --sqlite "SELECT value FROM settings WHERE key='zygisk'" 2>/dev/null | tail -n 1)" = "value=1" ]; then
	ZYGISK=1
fi
if [ -d "$NVBASE/modules/zygisksu" ] || [ -d "$NVBASE/modules/zygisk_next" ]; then
	ZYGISK=1
fi

if [ "$ZYGISK" = "0" ]; then
	abort "! Zygisk is disabled
! Enable Zygisk in Magisk settings, reboot, then flash again"
fi

# Two hooks on the same Play Store is a conflict, not a feature.
if [ -d "$NVBASE/modules/zygisk-detach" ]; then
	abort "! zygisk-detach is installed
! This module already bundles that engine
! Remove the zygisk-detach module, reboot, then flash again"
fi

ui_print "- Detaching now"
sh "$MODPATH/detach.sh"
RC=$?

if [ -s "$MODPATH/detach.log" ]; then
	ui_print "$(sed 's/^/    /' "$MODPATH/detach.log")"
fi

if [ "$RC" -eq 0 ]; then
	ui_print "- The module rebuilds the list on every boot."
else
	ui_print "- Detach failed with code $RC"
	ui_print "- Read /data/adb/modules/$MODID/detach.log after the reboot"
fi

rm -f "$MODPATH/detach.log"
