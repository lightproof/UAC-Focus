## ![icon](assets/icon.png?raw=true) UAC-Focus

### ABOUT

This is a simple AutoHotKey script that makes it easier to control UAC Prompts with the use of keyboard shortcuts (`Alt`+`Y` / `Alt`+`N`)[^1]. It have been tested to work on Windows 10 21H2, but should probably also work on Windows 11, 8/8.1 and maybe even 7 or Vista.

#### Rationale:

By default Windows UAC is set up to run on a secure (dimmed) desktop. Consequently, the UAC Prompt window is always in focus when it appears, and is easy to control using the keyboard. If, however, UAC is set up to run on a regular desktop, the UAC Prompt window doesn't always come up in focus, making it inconvenient to control with the keyboard, forcing the user to explicitly switch to UAC window first using either mouse or `Alt`+`Tab`.

#### Solution:

This AutoHotKey script waits for the UAC Prompt window to appear and then brings it in focus, making keyboard shortcuts usage more convenient.

## HOW TO USE

The UAC Prompt host process (consent.exe) runs under SYSTEM account and cannot be easily accessed due to security reasons. Because of this the script must be run with the highest privileges (as `NT Authority\System`).

There are several ways to do this:
				
1. using Microsoft Sysinternals' **PsExec**[^2] with a `-s` parameter

2. using Nir Sofer's **NirCmd**[^3] with an `elevatecmd runassystem` parameter.

3. using Windows **Task Scheduler** task with `Run with highest privileges` setting enabled.[^4]

---

### DISCLAIMER

Running a process as a System user is a potential security risk and is usually discouraged. Although this script is probably unlikely to compromise system security, it, nevertheless, comes with ABSOLUTELY NO WARRANTY and you are using it AT YOUR OWN RISK. You have been warned.

[^1]: this is a default for a non-localized (i.e. english) Windows UI. If the UI is in another language, the letter corresponding to each option can be found out by pressing `Alt` twice while UAC window is open.

[^2]: https://learn.microsoft.com/en-us/sysinternals/downloads/psexec#using-psexec

[^3]: https://www.nirsoft.net/utils/nircmd.html

[^4]: this actually runs the task under user account, but with high enough privileges to access processes started by `NT Authority\System`.
