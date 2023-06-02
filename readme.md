## UAC-Focus
###### Make UAC keyboard shortcuts great again

##### ABOUT
This is a simple AutoHotKey script that makes it easier to control UAC Prompts with the use of keyboard shortcuts (`Alt+Y`/`Alt+N` by default). It have been tested to work on Windows 10 21H2, but should probably also work on Windows 11, 8/8.1 and maybe even 7 or Vista.

##### The problem:
By default Windows UAC is set up to run on a secure desktop. Consequently, the UAC Prompt window is always in focus when it appears, and is easy to control using the keyboard. If, however, UAC is set up to run on a regular desktop (without dimming), the UAC Prompt window doesn't always come up in focus, making it inconvenient to control it with the keyboard, forcing the user to explicitly switch to UAC window first using either mouse or `Alt+Tab`.


##### The solution:
This AutoHotKey script waits for the UAC Prompt window to appear and then brings it in focus, making keyboard shortcuts usage more convenient.


##### HOW TO USE
The UAC Prompt host process (consent.exe) runs under SYSTEM account and cannot be easily accessed due to security reasons. Because of this the script must be run with the highest privileges (as `NT Authority\System`).

There are several ways to do this:
				
1. using PsExec[^1] with a `-s` parameter

2. using NirCmd[^2] with an `elevatecmd runassystem` parameter.

3. using a Task Scheduler task with *"Run with highest privileges"* setting enabled.[^3]


---
##### DISCLAIMER
Running a process as a System user is a potential security risk and is usually discouraged. Although this script is probably unlikely to compromise system security, at least when used as a standalone exe, it, nevertheless, comes with ABSOLUTELY NO WARRANTY WHATSOEVER and you are using it AT YOUR OWN RISK. You have been warned.

[^1]: https://learn.microsoft.com/en-us/sysinternals/downloads/psexec#using-psexec
[^2]: https://www.nirsoft.net/utils/nircmd.html
[^3]: this actually runs the task under user account, but with at least enough privileges to access processes started by `NT Authority\System`. If user account is part of Administrators group of course.
