# MacHood

![Swift](https://img.shields.io/badge/Language-Swift-orange)
![Python](https://img.shields.io/badge/Daemon-Python%203-blue)
![Platform](https://img.shields.io/badge/Platform-macOS-lightgrey)
![Framework](https://img.shields.io/badge/Framework-Quartz-orange)

There really aren't many decent layout macros out there for mac players on Roblox. MacHood fixes that — it's a native macOS app built with Swift and a Python backend, specifically for animation canceling and speed glitching in Da Hood. It works by rapidly spamming configurable key sequences to handle zooming.

Full disclosure: I used AI to help with some of the Swift UI and multi-threading logic, but the core execution and architecture is solid.

---

## How It Works

* **Native macOS app**: Built with Swift and SwiftUI, no Python runtime needed to launch — just open the `.app`.
* **Python daemon**: A background Python process handles low-level input injection via the macOS Quartz framework, bypassing typical software lag.
* **Unix socket**: Swift and Python communicate over a local Unix socket (`/tmp/machood.sock`) for real-time control.
* **Configurable hotkey**: Toggle the macro on/off with any key or mouse button you set in the UI.
* **Custom key sequences**: Add, remove, and reorder the keys being spammed directly from the app.
* **Speed control**: Slider scales from 5 up to 200 presses per second.

---

## Download

Grab the latest `.dmg` from the [Releases](../../releases) page, open it, and drag MacHood into your Applications folder.

---

## Build from Source

Make sure you have Python 3 and the required libraries installed:

```bash
pip3 install pyobjc-framework-Quartz pynput
```

Then compile and build the app bundle:

```bash
swiftc MacHoodApp.swift ContentView.swift RaycastWindow.swift DaemonConnection.swift -o MacHood

mkdir -p MacHood.app/Contents/MacOS
mkdir -p MacHood.app/Contents/Resources

cp MacHood MacHood.app/Contents/MacOS/MacHood
cp cat.icns MacHood.app/Contents/Resources/cat.icns
cp machood_daemon.py MacHood.app/Contents/Resources/
cp Info.plist MacHood.app/Contents/Info.plist

chmod +x MacHood.app/Contents/MacOS/MacHood
open MacHood.app
```

---

## Permissions

Because MacHood injects global inputs via Quartz, macOS will require Accessibility permissions. Go to:

**System Settings → Privacy & Security → Accessibility**

And enable MacHood. Without this the macro won't be able to send keys to the game.

---

## Usage

* Add any keys you want to spam in the UI — defaults to `i` and `o` for animation canceling, but you can use scroll wheel zoom, `f`, or literally any key you want.
* Adjust the slider to change presses per second.
* Press your configured hotkey to toggle the macro on and off while playing.
