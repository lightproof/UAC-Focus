;
; UAC-Focus
;
; An AutoHotKey script that focuses UAC window for quick control with keyboard shortcuts.
;
; https://github.com/lightproof/UAC-Focus
;
;
; How to use:
; Run the script with the highest privileges as "NT AUTHORITY\SYSTEM". See GitHub page for more details.
;
;
; Startup parameters:
; -notify		-	display notification when UAC window gets focused by the script
; -notifyall	-	also display notification when UAC window appears already focused
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



#SingleInstance Force



; Vars
	version = v0.4.0
	appname = UAC-Focus by lightproof
	repo = https://github.com/lightproof/UAC-Focus
	RunMode = silent



; App icon
	appicon = %a_scriptdir%/assets/icon.ico

	IfExist, %appicon%
		Menu, Tray, Icon, %appicon%

	

; Command line arguments
	arg = %1%

	if arg = -notify
		RunMode = notify

	if arg = -notifyall
		RunMode = notifyall
	
	

; Tray menu
	Menu, Tray, Tip, UAC-Focus %version%
	Menu, Tray, Click, 2
	Menu, Tray, NoStandard

	Menu, Tray, Add, &About, about, :FileMenu
	Menu, Tray, Default, &About
	Menu, Tray, Add
	Menu, Tray, Add, &Help, help
	Menu, Tray, Add, &Open file location, OpenLocation
	Menu, Tray, Add
	Menu, Tray, Add, E&xit, quit



; Main detect and focus loop
	Loop
	{

		WinWait, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe

		ifWinNotActive, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe
		{

			WinActivate
			
			if RunMode = notify
				TrayTip, UAC-Focus, Window focused, 3, 1
		}
		else
		{
			if RunMode = notifyall
				TrayTip, UAC-Focus, Already in focus, 3, 1

		}

		WinWaitClose, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe

	}



; Subroutines
	help:
		MsgBox, 64, %appname%,
		(LTrim
		Startup parameters:
		
		-notify    -    display notification when UAC window gets focused by the script
		
		-notifyall    -    also display notification when UAC window is shown already focused
		)
	return


	about:
		OnMessage(0x53, "WM_HELP")
		Gui +OwnDialogs
		
		SetTimer, ButtonRename, 10

		MsgBox, 0x4040, About,
		(LTrim
		%appname% %version%
		
		An AutoHotKey script that automatically focuses UAC window for quick control with keyboard shortcuts.
		
		%repo%
		)
		
		
		 WM_HELP() { 
			Gosub, github
			WinClose, %appname% ahk_class #32770
		 }
	return


	ButtonRename: 
		IfWinNotExist, About aHK_class #32770
			return
			
		SetTimer, ButtonRename, Off 
		WinActivate 
		ControlSetText, Button2, &GitHub
	return


	github:
		run, %repo%
	return


	OpenLocation:
		run, explorer.exe %a_scriptdir%
	return


	quit:
		ExitApp