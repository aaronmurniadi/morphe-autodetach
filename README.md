# morphe-autodetach

A Magisk / KernelSU module that keeps every [Morphe](https://morphe.software) root-mount app detached from Google Play Store.

<a href="https://www.buymeacoffee.com/aaronmurniadi"><img src="https://img.buymeacoffee.com/button-api/?text=Buy%20me%20a%20coffee&emoji=&slug=aaronmurniadi&button_colour=FFDD00&font_colour=000000&font_family=Cookie&outline_colour=000000&coffee_colour=ffffff" alt="Buy me a coffee"></a>

One zip. No second module to install. Nothing to configure.

If you already run a `zygisk-detach` module, this module finds it and uses its engine instead of the bundled one.

## The problem

Morphe can install a patched app with **Root mount**. Root mount does not install the patched APK. It bind-mounts the patched APK over the stock app. Android keeps the stock package, the stock signature and the stock data directory.

Play Store sees the same stock app, so it offers an update. When you accept it, Play Store writes a new APK into a new `/data/app` directory and the mount no longer matches. Two things can happen:

- The stock app runs instead of the patched app.
- The mount fails with a version mismatch.

Morphe documents one workaround: open the app page and select **Turn off updates**. Play Store sometimes ignores that setting and updates the app anyway.

Editing Play Store databases does not help either. Current Play Store versions decide the update offer from the server catalog and ignore the local tables, so a database-only module still shows **Update**.

## What this module does

The module hides the Morphe apps from Play Store's package queries. Play Store then shows `Install` instead of `Update` or `Open` on those app pages, and it cannot attach an update to them.

A small Zygisk engine inside Play Store does the filtering. On every boot the module rebuilds the package list from your installed Morphe modules, so a new Morphe app is detached without extra work.

The engine comes from [zygisk-detach](https://github.com/j-hc/zygisk-detach) by [j-hc](https://github.com/j-hc). It is fetched from the official release at build time and packed into this module. See [NOTICE](NOTICE).

An installed `zygisk-detach` module takes precedence. In that case the installer deletes the bundled engine files from this module, so only one hook runs on Play Store. Before this module replaces the `zygisk-detach` package list, it saves that list to `/data/adb/zygisk-detach/detach.bin.before-morphe-autodetach`. Removing this module puts the saved list back.

## Requirements

- Android 8 or newer, rooted.
- Magisk 20.4 or newer with **Zygisk enabled**, or KernelSU / APatch with **Zygisk Next**.
- Morphe app installed with the **Root mount** installer.

The installer stops with a clear message when Zygisk is off.

## Install

1. Download `morphe-autodetach-vX.Y.Z.zip` from [Releases](../../releases).
2. Open the Magisk, KernelSU or APatch app.
3. Select **Modules**, then **Install from storage**, then choose the zip.
4. Reboot.

The installer writes the detach list at once and the module refreshes it on every boot.

### If you already use zygisk-detach

Nothing to do. The installer detects `/data/adb/modules/zygisk-detach`, keeps its engine running, and removes the bundled engine from this module. The directory `/data/adb/modules/morphe-autodetach` then has no `zygisk` and no `bin` directory. That is expected.

A `zygisk-detach` module that is disabled or marked for removal does not count. The installer keeps the bundled engine in that case.

Build the zip yourself:

```sh
./build.sh
```

The script downloads the engine release and stages the module. Set `ZD_VERSION` to pin another engine version:

```sh
ZD_VERSION=v1.24.0 ./build.sh
```

## Usage

Nothing to configure. The module finds every Morphe root-mount module at `/data/adb/modules/*-morphe`, takes the package name from the module id, and detaches it.

Three optional text files give you control. All of them use one package name per line, and `#` starts a comment.

| File | Effect |
| --- | --- |
| `/data/adb/modules/morphe-autodetach/detach.txt` | Extra packages to detach, for apps that Morphe does not mount |
| `/sdcard/detach.txt` | Same list, easier to edit from a file manager |
| `/data/adb/modules/morphe-autodetach/skip.txt` | Packages to keep attached, even when Morphe mounts them |

Change a list, then run the script. No reboot needed:

```sh
su -c sh /data/adb/modules/morphe-autodetach/detach.sh
```

## Check that it works

1. Open the app page in Play Store. The button shows `Install`, not `Update`.
2. Read the log:

```sh
su -c cat /data/adb/modules/morphe-autodetach/detach.log
```

A healthy run looks like this:

```
engine: /data/adb/modules/morphe-autodetach/bin/arm64/detach
packages: com.google.android.apps.youtube.music com.google.android.youtube
  'com.google.android.apps.youtube.music'
  'com.google.android.youtube'
Serialized detach.txt
updated detach.bin, 2 package(s) detached
```

## Re-attach an app

1. Add the package to `skip.txt`, then run `detach.sh`. To re-attach everything, remove the module.
2. Reboot, or force-stop Play Store, so it loads the new list.

Removing the module also clears the engine list. The uninstall script handles that.

## Troubleshooting

| Symptom | Cause and fix |
| --- | --- |
| Installer stops with `Zygisk is disabled` | Turn on Zygisk in Magisk settings, reboot, flash again |
| Installer says `Using its engine, dropping the bundled one` | A `zygisk-detach` module is installed. This module uses it on purpose. Move the apps back to the bundled engine by removing `zygisk-detach`, then reflashing this zip |
| Play Store still shows `Update` | Confirm Zygisk is on, then check that `com.android.vending` is not in the Magisk denylist or in an app-hiding exclusion list. Reboot |
| `ERROR: engine binary missing` | The zip was unpacked by hand. Flash the release zip, or run `./build.sh` and flash the fresh output |
| A patched app stopped working after a Play Store update | The update got through before the module was active. Reinstall the matching stock version and remount in Morphe |
| Play Store shows `Install` and you want to update the app on purpose | Add the package to `skip.txt`, run `detach.sh`, then update the app from Play Store |

## Limitations

- Zygisk must stay enabled. A Magisk update, a ROM update or a root change can turn it off.
- Detaching removes security updates for the app. Detach only apps you patch on purpose.
- Only apps installed through **Root mount** keep their patches this way. A normal Morphe install has a different signature, and Play Store rejects its update on its own.
- If you clear Play Store data, the module keeps working. The engine list does not live in Play Store data.

## Credits and license

- [Morphe](https://github.com/MorpheApp) for the patcher and the root-mount installer.
- [j-hc](https://github.com/j-hc) for the detach engine, [zygisk-detach](https://github.com/j-hc/zygisk-detach), Apache-2.0. The engine binaries are redistributed unmodified from the official release. See [NOTICE](NOTICE) and [LICENSE-Apache-2.0](LICENSE-Apache-2.0).
- The detection, list handling and installer logic in this repository are MIT licensed. See [LICENSE](LICENSE).
