# Changelog

## v1.2.0

- An installed and enabled `zygisk-detach` module is used instead of the bundled engine. The installer drops the bundled `zygisk` and `bin` files then, so only one hook runs on Play Store.
- The `zygisk-detach` package list is saved to `/data/adb/zygisk-detach/detach.bin.before-morphe-autodetach` before this module replaces it. Uninstalling this module restores that list.
- A `zygisk-detach` module that is disabled or marked for removal is ignored.

## v1.1.0

- Detach engine bundled. One module, no separate `zygisk-detach` install.
- Detection of every Morphe root-mount module at `/data/adb/modules/*-morphe`.
- List rebuilt on install and on every boot.
- Optional `detach.txt` for extra packages and `skip.txt` for exclusions.
- Installer checks: Zygisk enabled, no conflicting `zygisk-detach` module.
- Uninstall script clears the engine list.
- Log at `/data/adb/modules/morphe-autodetach/detach.log`.
