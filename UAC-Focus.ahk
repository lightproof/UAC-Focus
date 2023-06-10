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
; -beepall          also beep when the UAC window pops up already focused by the OS
; -showtip          display current settings in a tray tooltip at script startup
; -noflash          do not briefly change tray icon when the UAC window gets focused
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; startup settings
	#NoEnv
	#SingleInstance Force
	#WinActivateForce
	Process, Priority,, Normal
	SetBatchLines, 2

; Vars
	Version := "v0.6.1"
	App_Name := "UAC-Focus by lightproof"
	global Tray_Icon := A_ScriptDir "/assets/icon.ico"
	global Tray_Icon_Green := "HICON:*" . icon_green()
	global Repo := "https://github.com/lightproof/UAC-Focus"
	Own_PID := DllCall("GetCurrentProcessId")
	AboutWindow := "About ahk_class #32770 ahk_pid" Own_PID
	HelpWindow := "Help ahk_class #32770 ahk_pid" Own_PID

; Set app tray icon
	Gosub TrayIconSet

; Set defaults
	global Notify_Lvl = 0
	global StartupTip = 0
	global Beep = Off
	global TrayIconFlash = 1

; Set string names
	Lvl_Name_0 = Never
	Lvl_Name_1 = On focus
	Lvl_Name_2 = Always

; About window text
	AboutText =
	(LTrim
		%App_Name% %Version%

		An AutoHotKey script that automatically focuses UAC window for quick control with keyboard shortcuts.

		%Repo%
	)

; Help window text
	HelpText =
	(LTrim
		Startup parameters:

		-notify
		Start with "Notify on focus" enabled by default.
		This will display notification each time the UAC window gets focused.

		-notifyall
		Start with "Notify always" enabled by default.
		Same as above, but also display notification if the UAC window pops up already focused by the OS.

		-beep
		Start with "Beep on focus" enabled by default.
		This will sound two short beeps each time the UAC window gets focused.

		-beepall
		Same as above, but also beep once when the UAC window pops up already focused by the OS.

		-showtip
		Display current settings in a tray tooltip at script startup.

		-noflash
		Do not briefly change tray icon when the UAC window gets focused.
		)

; Set startup parameters
	Loop, %0%		; do for each parameter
	{
		Args := Args %A_Index% " "		; combined arguments string
		Arg := %A_Index%

		if Arg = -notify
		{
			global Notify_Lvl := 1
		}

		if Arg = -notifyall
		{
			global Notify_Lvl := 2
		}

		if Arg = -showtip
		{
			StartupTip = 1
		}

		if Arg = -beep
		{
			global Beep := "On"
		}

		if Arg = -beepall
		{
			global Beep := "All"
		}

		if Arg = -noflash
		{
			global TrayIconFlash := 0
		}
	}

; Request process elevation if not admin
	Gosub Elevation_check

; Set and/or show the tooltip on startup
	Gosub Set_Tray_Tooltip

	if (A_IsAdmin and StartupTip = 1)
	{
		TrayTip, UAC-Focus %Version%, Notify: %Menu_item_name%`nBeep: %Beep%, 3, 0x1
	}

; Tray menu
	Menu, Tray, Click, 2
	Menu, Tray, Standard		; Standard/NoStandard  = debugging / regular
	Menu, Tray, Add, &About, About
	Menu, Tray, Default, &About
	Menu, Tray, Icon, &About, %A_Windir%\system32\SHELL32.dll, 278		; letter «i» in blue circle
	Menu, Tray, Add

	; "Notify" submenu
	Menu, OptionID, Add, %Lvl_Name_0%, Notify_Toggle
	Menu, OptionID, Add, %Lvl_Name_1%, Notify_Toggle
	Menu, OptionID, Add, %Lvl_Name_2%, Notify_Toggle
	Menu, OptionID, Add
	Menu, OptionID, Add, Beep on focus, Notify_Toggle
	Menu, Tray, Add, &Notify, :OptionID
	; Menu, Tray, Icon, &Notify, %A_Windir%\system32\SHELL32.dll, 222		; white balloon tip with «i»

	; check matching Notify_Lvl entry
	Menu_item_name := Lvl_Name_%Notify_Lvl%
	Menu, OptionID, Check, %Menu_item_name%

	; check/uncheck beep menu
	if not Beep = Off
	{
		Menu, OptionID, Check, Beep on focus
	}
	else
	{
		Menu, OptionID, Uncheck, Beep on focus
	}

	Menu, Tray, Add
	Menu, Tray, Add, &Open file location, Open_Location
	Menu, Tray, Icon, &Open file location, %A_Windir%\system32\SHELL32.dll, 56	; document under loupe

	Open_Location()
	{
		run, explorer %A_ScriptDir%
	}

	Menu, Tray, Add, &Help, Help_Msg
	Menu, Tray, Icon, &Help, %A_Windir%\system32\SHELL32.dll, 24		; «?» mark in blue circle
	Menu, Tray, Add
	Menu, Tray, Add, E&xit, Exit
	; Menu, Tray, Icon, E&xit, %A_Windir%\system32\SHELL32.dll, 132		; red «X» mark

	Exit()
	{
		ExitApp
	}

; Shell hook
Gui +LastFound
hWnd := WinExist()
DetectHiddenWindows, On

DllCall( "RegisterShellHookWindow", UInt,hWnd )
MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )
OnMessage( MsgNum, "ShellMessage" )

; Main Detect And Focus Loop
	ShellMessage( wParam,lParam )
	{
		If ( wParam = 1 )
		{
			WinGet, process, ProcessName, ahk_id %lParam%
			WinGetClass, class, ahk_id %lParam%
			global Window_Handle := lParam

			if (InStr(class, "Credential Dialog Xaml Host") and InStr(process, "consent.exe"))
			{

				if not WinActive (ahk_id Window_Handle)
				{

					if (Notify_Lvl = "1" or Notify_Lvl = "2" and Beep = "All")
					{
						soundbeep, , 100
					}

					if Notify_Lvl = 2
					{
						TrayTip, UAC-Focus, Already in focus, 3, 1
					}
				}
				else
				{
					WinActivate (ahk_id Window_Handle)

					Gosub OnActivateDo
				}

				; WinWaitClose, ahk_id %Window_Handle%	; if enabled, stops working with multiple windows
			}
		}
	}

; -------------------------------------
; Subroutines
	TrayIconSet:

		if FileExist(Tray_Icon)
		{
			Menu, Tray, Icon, %Tray_Icon%
		}

	return
; Subroutine
	TrayIconFlash:

		SetTimer, TrayIconFlash, Off

		; Menu, Tray, Icon, %A_Windir%\system32\imageres.dll, 102	; green shield with checkmark
		; Menu, Tray, Icon, %A_Windir%\System32\shell32.dll, 239	; blue circled arrows
		; Menu, Tray, Icon, %A_Windir%\System32\shell32.dll, 297	; green checkmark

		; flash tray icon
		Loop, 4
		{
			Menu, Tray, Icon, %Tray_Icon_Green%		; use embedded icon data
			sleep 125
			Gosub TrayIconSet
			sleep 125
		}

	return

; Subroutine
	OnActivateDo:

		if (Notify_Lvl = "1" or Notify_Lvl = "2")
		{
			TrayTip, UAC-Focus, Window focused, 3, 1

			if not Beep = Off
			{
				Loop, 2
					SoundBeep, , 100
			}
		}

		if TrayIconFlash
		{
			SetTimer, TrayIconFlash, 10
		}

	return

; Subroutine
	Set_Tray_Tooltip:

		Loop, 3
		{
			Indx := A_Index - 1		; because Notify_Lvl starts with 0

			if Notify_Lvl = %Indx%
			{
				Menu_item_name := Lvl_Name_%Indx%
				Menu, Tray, Tip, UAC-Focus %Version%`nNotify: %Menu_item_name%`nBeep: %Beep%
			}
		}

	return

; Subroutine
	Elevation_check:

		if not A_IsAdmin
		{

			try
			{

				if A_IsCompiled
				{
					Run *RunAs "%A_ScriptFullPath%" %Args% /restart
				}
				else
				{
					Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%" %Args%
				}
			}
			catch
			{
				MsgBox, 0x30, UAC-Focus, The program needs to be run as Administrator!
				ExitApp
			}
		}

	return

; Subroutine
	Notify_Toggle:

		if A_ThisMenuItem = Beep on focus		; Beep toggle
		{
			Menu, OptionID, ToggleCheck, Beep on focus

			if not Beep = On
			{
				Beep = On
				SoundBeep, , 100
				SoundBeep, , 100
			}
			else
			{
				Beep = Off
			}
		}
		else
		{

			; notify toggle
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
		}

		Gosub Set_Tray_Tooltip

	return

; Subroutine
	Help_Msg:

		If not WinExist(HelpWindow)
		{
			MsgBox, 0x20, Help, %HelpText%
		}
		else
		{
			WinActivate
		}

	return

; Subroutine
	About:

		; "Help" button control
		OnMessage(0x53, "WM_HELP")
		Gui +OwnDialogs

		SetTimer, Button_Rename, 10

		If not WinExist(AboutWindow)
		{
			MsgBox, 0x4040, About, %AboutText%`
		}

		; "Help" button action
		 WM_HELP()
		 {
			run, %Repo%
			WinClose, About ahk_class #32770
		 }

	return

; Subroutine
	Button_Rename:

		If WinExist(AboutWindow)
		{
			SetTimer, Button_Rename, Off
			WinActivate
			ControlSetText, Button2, &GitHub
		}

	return

; Embedded icon data generated by Image2Include.ahk, ### DO NOT CHANGE! ###
	icon_green(NewHandle := False)
	{
		Static hBitmap := icon_green()
		If (NewHandle)
		   hBitmap := 0
		If (hBitmap)
		   Return hBitmap
		VarSetCapacity(B64, 5716 << !!A_IsUnicode)
		B64 := "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"
		If !DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", 0, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
		   Return False
		VarSetCapacity(Dec, DecLen, 0)
		If !DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt", 0, "UInt", 0x01, "Ptr", &Dec, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
		   Return False
		; Bitmap creation adopted from "How to convert Image data (JPEG/PNG/GIF) to hBITMAP?" by SKAN
		; -> http://www.autohotkey.com/board/topic/21213-how-to-convert-image-data-jpegpnggif-to-hbitmap/?p=139257
		hData := DllCall("Kernel32.dll\GlobalAlloc", "UInt", 2, "UPtr", DecLen, "UPtr")
		pData := DllCall("Kernel32.dll\GlobalLock", "Ptr", hData, "UPtr")
		DllCall("Kernel32.dll\RtlMoveMemory", "Ptr", pData, "Ptr", &Dec, "UPtr", DecLen)
		DllCall("Kernel32.dll\GlobalUnlock", "Ptr", hData)
		DllCall("Ole32.dll\CreateStreamOnHGlobal", "Ptr", hData, "Int", True, "PtrP", pStream)
		hGdip := DllCall("Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", "UPtr")
		VarSetCapacity(SI, 16, 0), NumPut(1, SI, 0, "UChar")
		DllCall("Gdiplus.dll\GdiplusStartup", "PtrP", pToken, "Ptr", &SI, "Ptr", 0)
		DllCall("Gdiplus.dll\GdipCreateBitmapFromStream",  "Ptr", pStream, "PtrP", pBitmap)
		DllCall("Gdiplus.dll\GdipCreateHICONFromBitmap", "Ptr", pBitmap, "PtrP", hBitmap, "UInt", 0)
		DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", pBitmap)
		DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", pToken)
		DllCall("Kernel32.dll\FreeLibrary", "Ptr", hGdip)
		DllCall(NumGet(NumGet(pStream + 0, 0, "UPtr") + (A_PtrSize * 2), 0, "UPtr"), "Ptr", pStream)
		Return hBitmap
	}
