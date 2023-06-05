;
; UAC-Focus
;
; AHK script that focuses UAC window for quick control with keyboard shortcuts.
;
; https://github.com/lightproof/UAC-Focus
;
;
; Instructions:
; Run the script with the highest privileges as "NT AUTHORITY\SYSTEM". See GitHub page for more details.
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



; Basics
	version = v0.2.0
	repo = https://github.com/lightproof/UAC-Focus
	appicon = icon.ico

	IfExist, %appicon%
		Menu, Tray, Icon, icon.ico
		

; Menu & settings
	Menu, Tray, Tip, UAC-Focus %version%
	Menu, Tray, Click, 2
	Menu, Tray, NoStandard


; Menu body
	Menu, Tray, Add, &About, about, :FileMenu
	Menu, Tray, Default, &About
	Menu, Tray, Add
	Menu, Tray, Add, &GitHub page, github
	Menu, Tray, Add
	Menu, Tray, Add, E&xit, quit



; Main loop
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



; Menu targets
	about:
		MsgBox, 64, UAC-Focus, UAC-Focus by Lightproof, %version%`n`n%repo%	
	return


	github:
		run, %repo%
	return


	quit:
		ExitApp
