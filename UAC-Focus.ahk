; 
; UAC-Focus
;
; AHK script that focuses UAC window for quick control with keyboard shortcuts.
;
; https://github.com/lightproof/UAC-Focus
;
;
; Instructions:
; The script must be run with the highest privileges as "NT AUTHORITY\SYSTEM". See GitHub page for more details.
; 
;

Loop
{

	WinWait, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe
	
	ifWinNotActive, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe
	{

		WinActivate
		; TrayTip, UAC-Focus, Window focused, 3, 1		;uncomment for message to appear every time the UAC window is focused

	}
	else
	{

		; TrayTip, UAC-Focus, Already in focus, 3, 1	;uncomment for message to appear every time the UAC window appears already focused

	}
	
	WinWaitClose, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe
	
}
