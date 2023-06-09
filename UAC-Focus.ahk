;
; UAC-Focus by lightproof
;
; An AutoHotKey script that focuses UAC window for quick control with keyboard shortcuts.
;
; https://github.com/lightproof/UAC-Focus
;
;
; Startup parameters:
; -notify           start with "Notify on focus" enabled by default
; -notifyall        start with "Notify always" enabled by default
; -beep             start with "Beep on focus" enabled by default
; -showtip          display current settings in a tray tooltip at script startup
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#NoEnv
#SingleInstance Force


; Vars
	Version := "v0.6.0"
	App_Name := "UAC-Focus by lightproof"
	App_Icon := A_ScriptDir "/assets/icon.ico"
	global Repo := "https://github.com/lightproof/UAC-Focus"
	PID := DllCall("GetCurrentProcessId")

	AboutWindow := "About ahk_class #32770 ahk_pid" PID
	HelpWindow := "Help ahk_class #32770 ahk_pid" PID



; Set app icon
	if FileExist(App_Icon)
		Menu, Tray, Icon, %App_Icon%


; Set defaults
	Notify_Lvl = 0
	StartupTip = 0
	Beep = Off


; Set string names
	Lvl_Name_0 = Never
	Lvl_Name_1 = On focus
	Lvl_Name_2 = Always


; Messagebox Text
	AboutText =
	(LTrim
		%App_Name% %Version%

		An AutoHotKey script that automatically focuses UAC window for quick control with keyboard shortcuts.

		%Repo%
	)


	HelpText =
	(LTrim
		Startup parameters:

		-notify
		Start with "Notify on focus" enabled by default.
		This will display notification each time the UAC window gets focused.

		-notifyall
		Start with "Notify always" enabled by default.
		Same as above, but also display notification if the UAC window has been already focused by the OS.

		-beep
		Start with "Beep on focus" enabled by default.
		This will sound two short beeps each time the UAC window gets focused.
		
		-showtip
		Display current settings in a tray tooltip at script startup.
		)



; Set startup parameters
	Loop, %0%		; do for each parameter
	{
		Args := Args %A_Index% " "		; combined arguments string
		Arg := %A_Index%

		if Arg = -notify
			Notify_Lvl = 1

		if Arg = -notifyall
			Notify_Lvl = 2

		if Arg = -showtip
			StartupTip = 1

		if Arg = -beep
			Beep = On

	}

	
	
; Set and/or show the tooltip on startup
	if A_IsAdmin and if StartupTip = 1
		TrayTip, UAC-Focus %Version%, Notify: %Menu_item_name%`nBeep: %Beep%, 3, 0x1

	Gosub Set_Tray_Tooltip


; Request process elevation if not admin
	Gosub Elevation_check



; Tray menu
	Menu, Tray, Click, 2
	Menu, Tray, Nostandard

	Menu, Tray, Add, &About, About
	Menu, Tray, Default, &About
	Menu, Tray, Add

	; "Notify" submenu
	Menu, OptionID, Add, %Lvl_Name_0%, Notify_Toggle
	Menu, OptionID, Add, %Lvl_Name_1%, Notify_Toggle
	Menu, OptionID, Add, %Lvl_Name_2%, Notify_Toggle
	Menu, OptionID, Add
	Menu, OptionID, Add, Beep on focus, Notify_Toggle
	Menu, Tray, Add, &Notify, :OptionID


	Menu_item_name := Lvl_Name_%Notify_Lvl%
	Menu, OptionID, Check, %Menu_item_name%		; check appropreate Notify_Lvl


	if Beep = On		; check/uncheck beep menu
		Menu, OptionID, Check, Beep on focus
	else
		Menu, OptionID, Uncheck, Beep on focus


	Menu, Tray, Add
	Menu, Tray, Add, &Open file location, Open_Location


	Open_Location()
	{
		run, explorer %A_ScriptDir%
	}


	Menu, Tray, Add, &Help, Help_Msg
	Menu, Tray, Add
	Menu, Tray, Add, E&xit, Exit


	Exit()
	{
		ExitApp
	}



; MAIN DETECT AND FOCUS LOOP
	Loop
	{
		WinWait, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe, , 0.5		; TODO: try replacing with a Shell Hook in future?

		if ErrorLevel
		{
			Sleep 250		; delay to reduce polling intencity for potentially lower CPU usage
			Goto focus_loop_end
		}

		if not WinActive ("ahk_class Credential Dialog Xaml Host ahk_exe consent.exe")
		{

			WinActivate

			if (Notify_Lvl = "1" or Notify_Lvl = "2")
			{
				TrayTip, UAC-Focus, Window focused, 3, 1

				if Beep = On
				{
					Loop, 2
						SoundBeep, , 100
				}
			}

		}
		Else
		{

			if Notify_Lvl = 2
				TrayTip, UAC-Focus, Already in focus, 3, 1

		}

		WinWaitClose, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe

		focus_loop_end:
	}



; Subroutines-------------------------------------
	Set_Tray_Tooltip:
		Loop, 3
		{
			Indx = %A_Index%
			Indx := Indx - 1	; because Notify_Lvl starts with 0


			if Notify_Lvl = %Indx%
			{
				Menu_item_name := Lvl_Name_%Indx%
				Menu, Tray, Tip, UAC-Focus %Version%`nNotify: %Menu_item_name%`nBeep: %Beep%
			}
		}
	return


; ----------------------
	Elevation_check:
		if not A_IsAdmin
		{

			try
			{

				if A_IsCompiled
					Run *RunAs "%A_ScriptFullPath%" %Args% /restart
				else
					Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%" %Args%

			}
			catch
			{

				MsgBox, 0x30, UAC-Focus, The program needs to be run as Administrator!
				ExitApp

			}

		}
	return


; ----------------------
	Notify_Toggle:
		if A_ThisMenuItem = Beep on focus		; Beep toggle
		{
			Menu, OptionID, ToggleCheck, Beep on focus

			if Beep = Off
			{
				Beep = On
				
				Loop, 2
					SoundBeep, , 100
			}
			else
				Beep = Off
		}
		else
		{
			Loop, 3		; notify toggle
			{
				Indx = %A_Index%
				Indx := Indx - 1

				Menu_item_name := Lvl_Name_%Indx%


				if A_ThisMenuItem = %Menu_item_name%
				{
					Menu, OptionID, Check, %Menu_item_name%
					Notify_Lvl = %Indx%
				}
				else
				{
					Menu, OptionID, Uncheck, %Menu_item_name%
				}
			}

		}

		Gosub Set_Tray_Tooltip
	return


; ----------------------
	Help_Msg:
		If not WinExist(HelpWindow)
			MsgBox, 0x20, Help, %HelpText%
		else
			WinActivate
	return


; ----------------------
	About:
		OnMessage(0x53, "WM_HELP")		; "Help" button control
		Gui +OwnDialogs

			SetTimer, Button_Rename, 10

		If not WinExist(AboutWindow)
			MsgBox, 0x4040, About, %AboutText%`


		 WM_HELP()						; "Help" button action
		 {
			run, %Repo%
			WinClose, About ahk_class #32770
		 }
	return


; ----------------------
	Button_Rename:
		If WinExist(AboutWindow)
		{
			SetTimer, Button_Rename, Off
			WinActivate
			ControlSetText, Button2, &GitHub
		}
	return
