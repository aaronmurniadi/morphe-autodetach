#!/system/bin/sh
# Waits for the boot to finish, then rebuilds the detach list.
#
# The wait is bounded. A boot that never reports ready must not leave this
# script running for ever.

MODDIR=${0%/*}
i=0

while [ "$(getprop sys.boot_completed)" != "1" ]; do
	i=$((i + 1))
	if [ "$i" -gt 300 ]; then
		echo "$(date '+%Y-%m-%d %H:%M:%S') boot not completed after 300s, abort" >>"$MODDIR/detach.log"
		exit 1
	fi
	sleep 1
done

# Let Play Store and the Morphe mounts settle before the list is rebuilt.
sleep 5

sh "$MODDIR/detach.sh"
