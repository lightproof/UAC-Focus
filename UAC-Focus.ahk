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
; -notify           start with "Notify on focus" option enabled
; -notifyall        start with "Notify on everything" option enabled
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


#SingleInstance Force


; Vars
	Version = v0.5.3
	App_Name = UAC-Focus by lightproof
	App_Icon = %A_ScriptDir%/assets/icon.ico
	global Repo = "https://github.com/lightproof/UAC-Focus"



; Set app icon
	IfExist, %App_Icon%
		Menu, Tray, Icon, %App_Icon%



; Set notification levels
	Arg = %1%

	Notify_Lvl = 0		; default

	if Arg = -notify
		Notify_Lvl = 1

	if Arg = -notifyall
		Notify_Lvl = 2


	Lvl_Name_0 = Never
	Lvl_Name_1 = On focus
	Lvl_Name_2 = On everything



; Tray tooltip
	Gosub Set_Tray_Tooltip



; Elevation check
	Gosub Elevation_check



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

		-notify           Start with "Notify on focus" option enabled. This will display notification each time the UAC window gets focused.

		-notifyall        Start with "Notify on everything" option enabled. Same as above, but also display notification if the UAC window has been already focused by the OS.
		)



; Tray menu

	Menu, Tray, Click, 2
	Menu, Tray, Nostandard

	Menu, Tray, Add, &About, About
	Menu, Tray, Default, &About
	Menu, Tray, Add

	Menu, OptionID, Add, %Lvl_Name_0%, Notify_Toggle
	Menu, OptionID, Add, %Lvl_Name_1%, Notify_Toggle
	Menu, OptionID, Add, %Lvl_Name_2%, Notify_Toggle
	Menu, Tray, Add, &Notify, :OptionID

	Menu_item_name := Lvl_Name_%Notify_Lvl%
	Menu, OptionID, Check, %Menu_item_name%

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
		WinWait, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe, , 0.5	; TODO: try replacing with a Shell Hook in future?
		
		if ErrorLevel
		{
			Sleep 250	; delay to reduce polling intencity for potentially lower CPU usage
			Goto focus_loop_end
		}

		ifWinNotActive, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe
		{

			WinActivate

			if (Notify_Lvl = "1" or Notify_Lvl = "2")
				TrayTip, UAC-Focus, Window focused, 3, 1

		}
		Else
		{

			if Notify_Lvl = 2
				TrayTip, UAC-Focus, Already in focus, 3, 1

		}

		WinWaitClose, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe

		focus_loop_end:
	}



; Subroutines
; -------------------------------------
	Set_Tray_Tooltip:
		Loop, 3
		{
			Indx = %A_Index%
			Indx := Indx - 1

			Menu_item_name := Lvl_Name_%Indx%

			if Notify_Lvl = %Indx%
				Menu, Tray, Tip, UAC-Focus %Version%`nNotify: %Menu_item_name%
		}
	return



	Elevation_check:
		if not A_IsAdmin
		{

			try
			{

				if A_IsCompiled
					Run *RunAs "%A_ScriptFullPath%" %Arg% /restart

				else
					Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%" %Arg%

			}
			catch
			{

				MsgBox, 0x30, UAC-Focus, The program needs to be run as Administrator!
				ExitApp

			}

		}
	return



	Notify_Toggle:
		Loop, 3
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

		Gosub Set_Tray_Tooltip
	return



	Help_Msg:


		IfWinNotExist, Help ahk_class #32770
		{
			MsgBox, 0x20, Help, %HelpText%
		}
	return



	About:
		OnMessage(0x53, "WM_HELP")
		Gui +OwnDialogs

		SetTimer, Button_Rename, 10

		IfWinNotExist, About ahk_class #32770
		{
			MsgBox, 0x4040, About, %AboutText%

		}


		 WM_HELP()
		 {
			run, %Repo%
			WinClose, About ahk_class #32770
		 }
	return



	Button_Rename:
		IfWinNotExist, About ahk_class #32770
			return

		SetTimer, Button_Rename, Off
		WinActivate
		ControlSetText, Button2, &GitHub
	return
