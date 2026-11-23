#!/system/bin/sh
# morphe-autodetach - keep Morphe root-mount apps detached from Play Store.
#
# The detach engine is bundled in this module (see NOTICE). It hooks Play Store
# and hides the listed packages from Play's package queries.
#
# This script builds the package list and serializes it into the engine format.

MODDIR=${0%/*}
LOG=$MODDIR/detach.log
DATA=/data/adb/zygisk-detach
BIN=$DATA/detach.bin
LIST=$DATA/autodetach.txt
TMPDIR=/data/local/tmp/morphe-autodetach.$$
PKGS=$TMPDIR/pkgs

mkdir -p "$TMPDIR" "$DATA" || exit 1
: >"$LOG"

log() {
	echo "$*" >>"$LOG"
}

cleanup() {
	rm -rf "$TMPDIR"
}
trap cleanup EXIT INT TERM

# 1. Pick the engine binary for this CPU.
case "$(getprop ro.product.cpu.abi)" in
	arm64-v8a) ARCH=arm64 ;;
	armeabi-v7a | armeabi) ARCH=arm ;;
	x86_64) ARCH=x64 ;;
	x86) ARCH=x86 ;;
	*)
		log "ERROR: unsupported CPU: $(getprop ro.product.cpu.abi)"
		exit 1
		;;
esac

ENGINE=$MODDIR/bin/$ARCH/detach
if [ ! -x "$ENGINE" ]; then
	log "ERROR: engine binary missing: $ENGINE"
	exit 1
fi
log "engine: $ENGINE"

# 2. Collect the packages to detach.
: >"$PKGS"

# 2a. Every Morphe root-mount module. The module id is "<package>-morphe".
for mod in /data/adb/modules/*-morphe; do
	[ -d "$mod" ] || continue
	[ -f "$mod/disable" ] && continue
	[ -f "$mod/remove" ] && continue

	id=$(sed -n 's/^id=//p' "$mod/module.prop" 2>/dev/null | head -n 1)
	pkg=${id%-morphe}
	if [ -n "$pkg" ] && [ "$pkg" != "$id" ]; then
		echo "$pkg" >>"$PKGS"
	fi

	# Fallback: package names from the APK file names inside the module.
	for apk in "$mod"/*.apk; do
		[ -f "$apk" ] || continue
		name=${apk##*/}
		name=${name%.apk}
		case "$name" in
			*-stock | *-patched) continue ;;
		esac
		echo "$name" >>"$PKGS"
	done
done

# 2b. Extra packages from the user. One package per line, "#" starts a comment.
for f in "$MODDIR/detach.txt" /sdcard/detach.txt; do
	[ -f "$f" ] || continue
	sed 's/#.*//' "$f" | tr -d '\r' | grep -v '^[[:space:]]*$' | tr -d '[:space:]' >>"$PKGS"
done

sort -u "$PKGS" | grep -v '^$' >"$TMPDIR/list"

# 2c. Packages the user wants to keep attached.
if [ -f "$MODDIR/skip.txt" ]; then
	sed 's/#.*//' "$MODDIR/skip.txt" | tr -d '\r' | grep -v '^[[:space:]]*$' | tr -d '[:space:]' | sort -u >"$TMPDIR/skip"
	if [ -s "$TMPDIR/skip" ]; then
		grep -v -x -F -f "$TMPDIR/skip" "$TMPDIR/list" >"$TMPDIR/keep"
		mv -f "$TMPDIR/keep" "$TMPDIR/list"
	fi
fi

if [ -s "$TMPDIR/list" ]; then
	log "packages: $(tr '\n' ' ' <"$TMPDIR/list")"
else
	log "packages: none"
fi

# 3. An empty list must clear the engine list, not leave the old one behind.
cp -f "$TMPDIR/list" "$LIST"
rm -f "$TMPDIR/detach.bin"
"$ENGINE" serialize "$LIST" "$TMPDIR/detach.bin" >>"$LOG" 2>&1

if [ ! -s "$TMPDIR/detach.bin" ]; then
	log "ERROR: the engine could not serialize the list"
	exit 1
fi

if cmp -s "$TMPDIR/detach.bin" "$BIN"; then
	log "no change, $(wc -l <"$LIST") package(s) detached"
	exit 0
fi

mv -f "$TMPDIR/detach.bin" "$BIN"
chmod 644 "$BIN"
log "updated detach.bin, $(wc -l <"$LIST") package(s) detached"

# 4. Restart Play Store so it reads the new list.
am force-stop com.android.vending >/dev/null 2>&1
exit 0
