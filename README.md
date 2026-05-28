# macHood

https://img.shields.io/badge/Language-Python%203-blue
https://img.shields.io/badge/Platform-macOS-lightgrey
https://img.shields.io/badge/UI-CustomTkinter-darkgreen
https://img.shields.io/badge/Framework-Quartz-orange

There really aren't many decent layout macros out there for mac players on Roblox. This is a straightforward script made to fix that, specifically for animation canceling and speed glitching in Da Hood. It works by rapidly spamming the i and o keys to handle zooming. 

Full disclosure: I used an AI to help cook up the dark UI and clean up some of the multi-threading logic because front-end layout is not my thing, but the core execution is solid.

---

## How It Works

* Low-level inputs: Uses the macOS Quartz framework to inject keyboard events directly into the HID system so it bypasses typical software lag[cite: 1].
* Middle click toggle: You can start or stop the loop instantly using your middle click (scroll wheel click or mapped mouse side buttons)[cite: 1].
* CustomTkinter UI: Dark mode GUI with a live press counter and a speed slider that scales from 5 up to 200 presses per second[cite: 1].

---

## Requirements

You need Python 3 installed on your Mac. You will also need a few libraries to handle the GUI and mouse/keyboard hooks:

```bash
pip3 install pyobjc-framework-Quartz pynput customtkinter
```[cite: 1]

---

## Running the Macro

1. Clone or download this repository.
2. Open your terminal in the script folder.
3. Run the application file:

```bash
python3 macro_app.py
```[cite: 1]

Note: Because this script handles global inputs via Quartz, macOS privacy settings will require you to give your Terminal application (or IDE) Accessibility Permissions under System Settings > Privacy & Security > Accessibility. Otherwise, the macro won't be able to send keys to the game.

---

## Usage

* The keys to spam default to "i o" for zooming, but you can change them in the UI text box if needed[cite: 1].
* Adjust the slider to change your clicks per second[cite: 1].
* Press your middle mouse button to toggle it on and off while playing[cite: 1].
