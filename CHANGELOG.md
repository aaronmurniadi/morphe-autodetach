# Changelog

## v1.1.0

- Detach engine bundled. One module, no separate `zygisk-detach` install.
- Detection of every Morphe root-mount module at `/data/adb/modules/*-morphe`.
- List rebuilt on install and on every boot.
- Optional `detach.txt` for extra packages and `skip.txt` for exclusions.
- Installer checks: Zygisk enabled, no conflicting `zygisk-detach` module.
- Uninstall script clears the engine list.
- Log at `/data/adb/modules/morphe-autodetach/detach.log`.
