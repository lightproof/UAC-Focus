## ![icon](assets/icon.png?raw=true) UAC-Focus

### ABOUT

This is a simple AutoHotKey script that makes it easier to control User Account Control (UAC) prompts with the use of keyboard shortcuts (`Alt`+`Y` / `Alt`+`N`)[^1]. It have been tested to work on Windows 10 21H2, but should probably also work on Windows 11, 8/8.1 and maybe even 7 or Vista.

#### Rationale:

By default Windows UAC is set up to run on a secure (dimmed) desktop. Consequently, the UAC prompt window is always in focus when it appears, and is easy to control using the keyboard. If, however, UAC is set up to run on a regular desktop, the UAC Prompt window doesn't always come up in focus, making it inconvenient to control with the keyboard, forcing the user to explicitly switch to UAC window first using either mouse or `Alt`+`Tab`.

#### Solution:

This AutoHotKey script waits for the UAC prompt window to appear and then brings it in focus, making keyboard shortcuts usage more convenient.

## HOW TO USE

Run the script as Administrator.

The UAC prompt host process `consent.exe` is run by `NT Authority\System` user and cannot be accessed by a non-elevated process for security reasons. Therefore the script must be run with Administrator privileges to work and it will prompt for them upon start when run without elevation.

[^1]: this is a default for a non-localized (i.e. english) Windows UI. If the UI is in another language, the letter corresponding to each option can be found out by pressing `Alt` twice while UAC window is open.