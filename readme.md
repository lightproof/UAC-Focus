# ![icon](assets/icon.png?raw=true) UAC-Focus

### [Download latest version](https://github.com/lightproof/UAC-Focus/releases/latest/download/UAC-Focus.exe)

## ABOUT

This is a simple AutoHotKey script that makes it easier to control User Account Control (UAC) prompts with the use of keyboard shortcuts (<kbd>Alt</kbd>+<kbd>Y</kbd> / <kbd>Alt</kbd>+<kbd>N</kbd>)[^1]. It have been tested to work on Windows 10, but should probably also work on Windows 11, 8/8.1 and maybe even 7 or Vista.

### Rationale

By default Windows UAC is set up to run on a secure (dimmed) desktop. Consequently, the UAC prompt window is always in focus when it appears, and is easy to control using the keyboard. If, however, UAC is set up to run on a regular desktop, the UAC Prompt window doesn't always come up in focus, making it inconvenient to control with the keyboard, forcing the user to explicitly switch to UAC window first using either mouse or <kbd>Alt</kbd>+<kbd>Tab</kbd>.

### Solution

This AutoHotKey script waits for the UAC prompt window to appear and then brings it in focus if it already isn't, making keyboard shortcuts usage more convenient.

## HOW TO USE

The script must be run with Administrator privileges to work and will prompt for them upon start if needed. This is required because the UAC prompt host process `consent.exe` is run by `NT Authority\System` and can't be accessed by a non-elevated process for security reasons.

### Startup parameters

While options can be toggled from the tray menu, they will reset to defaults on the next run. Use the following startup parameters to change the defaults:

`-notify`

Start with **Notify on focus** enabled. This will display notification each time the UAC window gets focused.

`-notifyall`

Start with **Notify always** enabled. Same as above, but also display notification if the UAC window pops up already focused by the OS.

`-beep`

Start with **Beep on focus** enabled. This will sound two short beeps each time the UAC window gets focused.

[comment]: # (`-beepall`)

[comment]: # (Same as above, but also beep once when the UAC window pops up already focused by the OS.)

`-showtip`

Display current settings in a tray tooltip at script startup.

`-noflash`

Do not briefly change tray icon when the UAC window gets focused.

[^1]: this is a default for a non-localized (i.e. english) Windows UI. If the UI is in another language, the letter corresponding to each option can be found out by pressing <kbd>Alt</kbd> twice while UAC window is open.