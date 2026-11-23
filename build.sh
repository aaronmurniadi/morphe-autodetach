#!/bin/sh
# Build the module zip into dist/.
#
# The detach engine comes from the official zygisk-detach release. It is fetched
# at build time, so the repository stays source-only.
set -e

cd "$(dirname "$0")"

ZD_VERSION=${ZD_VERSION:-v1.24.0}
VERSION=$(sed -n 's/^version=//p' module.prop)
[ -n "$VERSION" ] || {
	echo "version missing in module.prop"
	exit 1
}

CACHE=build/cache
STAGE=build/module
OUT=dist/morphe-autodetach-$VERSION.zip

rm -rf build dist
mkdir -p "$CACHE" "$STAGE" dist

# 1. Fetch the engine release and keep it cached per version.
ZD_ZIP=$CACHE/zygisk-detach-$ZD_VERSION.zip
if [ ! -f "$ZD_ZIP" ]; then
	echo "downloading zygisk-detach $ZD_VERSION"
	curl -fsSL -o "$ZD_ZIP" \
		"https://github.com/j-hc/zygisk-detach/releases/download/$ZD_VERSION/zygisk-detach-$ZD_VERSION.zip"
fi

# 2. Stage our files, then the engine files.
cp module.prop customize.sh service.sh post-fs-data.sh uninstall.sh detach.sh \
	README.md LICENSE LICENSE-Apache-2.0 NOTICE CHANGELOG.md "$STAGE/"
cp detach.txt.example skip.txt.example "$STAGE/"

unzip -q -o "$ZD_ZIP" 'zygisk/*' 'bin/*' -d "$STAGE"
chmod -R 755 "$STAGE/bin"

# 3. Build the zip. -X keeps macOS metadata out.
(
	cd "$STAGE"
	zip -r -q -X "../../$OUT" . -x '*.DS_Store'
)

echo "$OUT"
unzip -l "$OUT" | tail -20
