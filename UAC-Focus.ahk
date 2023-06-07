;
; UAC-Focus
;
; An AutoHotKey script that focuses UAC window for quick control with keyboard shortcuts.
;
; https://github.com/lightproof/UAC-Focus
;
;
; How to use:
; Run this script with Administrator privileges
;
;
; Startup parameters:
; -notify		-	display notification when UAC window gets focused by the script
; -notifyall	-	also display notification when UAC window appears already focused
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


#SingleInstance Prompt


; Vars
	version = v0.5.0
	appname = UAC-Focus by lightproof
	repo = https://github.com/lightproof/UAC-Focus
	RunMode = silent

	if not RunMode = silent
		notify_opt = 1
	Else
		notify_opt = 0



; Command line arguments
	arg = %1%

	if arg = -notify
		RunMode = notify

	if arg = -notifyall
		RunMode = notifyall



; App icon
	appicon = %A_ScriptDir%/assets/icon.ico

	IfExist, %appicon%
		Menu, Tray, Icon, %appicon%



; Tray tooltip
	Gosub Set_Tray_Tooltip



; Elevation check
	if not A_IsAdmin
	{

		try
		{

			if A_IsCompiled
				Run *RunAs "%A_ScriptFullPath%" %arg% /restart

			else
				Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%" %arg%

		} catch {

			MsgBox, 48, UAC-Focus, The program needs to be run as Administrator!

		}

		ExitApp

	}



; Tray menu
	Menu, Tray, Click, 2
	Menu, Tray, Nostandard

	Menu, Tray, Add, &About, About
	Menu, Tray, Default, &About
	Menu, Tray, Add


	Menu, Tray, Add, Notify on focus, Notify_Toggle

	If Notify_Opt = 1
		Menu, Tray, Check, Notify on focus


	Menu, Tray, Add
	Menu, Tray, Add, &Open file location, Open_Location

	Menu, Tray, Add, &Help, Help_Msg

	Menu, Tray, Add
	Menu, Tray, Add, E&Xit, Quit


; Main detect and refocus loop
	Loop
	{

		WinWait, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe

		ifWinNotActive, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe
		{

			WinActivate

			if (RunMode = "notify" or RunMode = "notifyall")
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
	Set_Tray_Tooltip:
		if RunMode = silent
		{
			Menu, Tray, Tip, UAC-Focus %version%
		} Else {
			Menu, Tray, Tip, UAC-Focus %version%`n( mode: %RunMode% )
		}
	return


	Notify_Toggle:
		Menu, Tray, ToggleCheck, Notify on focus

		notify_opt := !notify_opt

		if notify_opt = 1
			RunMode = notify
		Else
			RunMode = silent

		Gosub Set_Tray_Tooltip
	return


	Help_Msg:
		MsgBox, 64, %appname%,
		(LTrim
		Startup parameters:

		-notify       -- Enables "Notify on focus" option by default. The program will display notification each time the UAC window gets focused.

		-notifyall    -- Same as above, but also displays notification if the UAC window have been already focused by the OS.
		)
	return


	About:
		OnMessage(0x53, "WM_HELP")
		Gui +OwnDialogs

		SetTimer, Button_Rename, 10

		MsgBox, 0x4040, About,
		(LTrim
		%appname% %version%

		An AutoHotKey script that automatically focuses UAC window for quick control with keyboard shortcuts.

		%repo%
		)


		 WM_HELP() {
			Gosub, GitHub
			WinClose, About ahk_class #32770
		 }
	return


	Button_Rename:
		IfWinNotExist, About aHK_class #32770
			return

		SetTimer, Button_Rename, Off
		WinActivate
		ControlSetText, Button2, &GitHub
	return


	GitHub:
		run, %repo%
	return


	Open_Location:
		run, explorer %A_ScriptDir%
	return


	Quit:
		ExitApp
