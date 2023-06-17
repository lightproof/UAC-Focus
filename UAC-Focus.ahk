/*
  UAC-Focus by lightproof

  An AutoHotKey script that focuses UAC window for quick control
  with keyboard shortcuts.

  https://github.com/lightproof/UAC-Focus


  Startup parameters:
	-notify           start with "Notify on focus" enabled by default
	-notifyall        start with "Notify always" enabled by default
	-beep             start with "Beep on focus" enabled by default
	-beepall          also beep when the UAC window pops up already focused by the OS
	-showtip          display current settings in a tray tooltip at script startup
	-noflash          do not briefly change tray icon when the UAC window gets focused
*/


; Startup settings
	#NoEnv
	#SingleInstance Force
	#WinActivateForce
	Process, Priority,, Normal
	; SetBatchLines, 2
	DetectHiddenWindows, On


; Vars
	version := "v0.7.3"
	app_name := "UAC-Focus by lightproof"
	global tray_icon := A_ScriptDir "/assets/icon.ico"
	global tray_icon_flashed := "HICON:*" . icon_green()
	global repo := "https://github.com/lightproof/UAC-Focus"
	current_pid := DllCall("GetCurrentProcessId")
	about_window := "About ahk_class #32770 ahk_pid " current_pid
	help_window := "Help ahk_class #32770 ahk_pid " current_pid


; Set defaults
	global notify_lvl := 0
	global startup_tip := 0
	global beep := "Off"
	global tray_flash := 1


; Set string names
	lvl_name_0 := "Never"
	lvl_name_1 := "On focus"
	lvl_name_2 := "Always"


; About window
	about_text := "
	( LTrim RTrim0 Join
		" app_name " " version "
		`n`n

		An AutoHotKey script that focuses UAC window for quick control with keyboard shortcuts.
		`n`n

		" repo "
	)"


; Help window
	help_text := "
	( LTrim RTrim0 Join
		Startup parameters:
		`n`n

		-notify
		`n
		Start with ""Notify on focus"" enabled by default.
		`n
		This will display notification each time the UAC window gets focused.
		`n`n

		-notifyall
		`n
		Start with ""Notify always"" enabled by default.
		`n
		Same as above, but also display notification if the UAC window
		pops up already focused by the OS.
		`n`n

		-beep
		`n
		Start with ""Beep on focus"" enabled by default.
		`n
		This will sound two short beeps each time the UAC window gets focused.
		`n`n

		-beepall
		`n
		Same as above, but also beep once when the UAC window pops up already focused by the OS.
		`n`n

		-showtip
		`n
		Display current settings in a tray tooltip at script startup.
		`n`n

		-noflash
		`n
		Do not briefly change tray icon when the UAC window gets focused.
		)"


; Set startup parameters
	Loop, %0%
	{
		args := args %A_Index% " "
		arg := %A_Index%

		if arg = -notify
			global notify_lvl := 1

		if arg = -notifyall
			global notify_lvl := 2

		if arg = -showtip
			startup_tip = 1

		if arg = -beep
			global beep := "On"

		if arg = -beepall
			global beep := "Always"

		if arg = -noflash
			global tray_flash := 0
	}

	notify_lvl_name := lvl_name_%notify_lvl%

	set_tray_icon(tray_icon)
	set_tray_tooltip()

	request_process_elevation(args)

; Show startup tooltip
	if (A_IsAdmin and startup_tip = 1)
		TrayTip, UAC-Focus %version%, Notify: %notify_lvl_name%`nBeep: %beep%, 3, 0x1


; Tray menu
	Menu, Tray, Click, 2
	Menu, Tray, NoStandard

	; Enable for debug menu
	; Menu, Tray, Add, &Debug, debug
	; Menu, Tray, Add

	Menu, Tray, Add, &About, about_box
	Menu, Tray, Default, &About
	; Menu, Tray, Default, &Debug

	; Letter «i» in blue circle icon
	Menu, Tray, Icon, &About, %A_Windir%\system32\SHELL32.dll, 278
	Menu, Tray, Add

	; "Notify" submenu
	Menu, OptionID, Add, %lvl_name_0%, notify_toggle
	Menu, OptionID, Add, %lvl_name_1%, notify_toggle
	Menu, OptionID, Add, %lvl_name_2%, notify_toggle
	Menu, OptionID, Add
	Menu, OptionID, Add, Beep on focus, notify_toggle
	Menu, Tray, Add, &Notify, :OptionID

	Menu, OptionID, Check, %notify_lvl_name%

	if not (beep = "Off")
		Menu, OptionID, Check, Beep on focus
	else
		Menu, OptionID, Uncheck, Beep on focus

	Menu, Tray, Add
	Menu, Tray, Add, &Open file location, open_Location

	; Document with loupe icon
	Menu, Tray, Icon, &Open file location, %A_Windir%\system32\SHELL32.dll, 56
	Menu, Tray, Add, &Help, help_box

	; «?» mark in blue circle icon
	Menu, Tray, Icon, &Help, %A_Windir%\system32\SHELL32.dll, 24
	Menu, Tray, Add
	Menu, Tray, Add, E&xit, Exit

	; Red «X» mark icon
	; Menu, Tray, Icon, E&xit, %A_Windir%\system32\SHELL32.dll, 132


; Shell hook
Gui +LastFound
hWnd := WinExist()

DllCall( "RegisterShellHookWindow", UInt,hWnd )
MsgNum := DllCall( "RegisterWindowMessage", Str,"SHELLHOOK" )
OnMessage( MsgNum, "ShellMessage" )

	ShellMessage( wParam,lParam )
	{
		hwnd := lParam
		WinGet, process, ProcessName, ahk_id %hwnd%
		WinGetClass, class, ahk_id %hwnd%

		if (InStr(class, "Credential Dialog Xaml Host")	and InStr(process, "consent.exe"))
		{
			; Detect flashing window
			if (wParam = 0x8006)	; HSHELL_FLASH
				win_activate(hwnd)

			; Detect regular window
			If ( wParam = 1 )	; HSHELL_WINDOWCREATED := 1
			{
				if WinActive (ahk_id hwnd)
					win_already_active(hwnd)
				else
					win_activate(hwnd)
			}
		}
	}


; ================================================================================================
	; ^r::Reload


; Functions
	set_tray_icon(tray_icon)
	{
		if FileExist(tray_icon)
			Menu, Tray, Icon, %tray_icon%
	}


	win_activate(hwnd)
	{
			if not (beep = "Off")
			{
				SoundBeep, , 100
				SoundBeep, , 100
			}

			PostMessage, WM_SYSCOMMAND := 0x0112, SC_HOTKEY := 0xF150, %hwnd%,,

			if (notify_lvl = "1" or notify_lvl = "2")
				TrayTip, UAC-Focus, Window focused, 3, 1

			if tray_flash
				SetTimer, flash_tray_icon, -10
	}


	win_already_active(hwnd)
	{
		if (beep = "Always")
			SoundBeep, , 100

		if notify_lvl = 2
			TrayTip, UAC-Focus, Already in focus, 3, 1
	}


	help_button_action()
	{
		run, %repo%
		WinClose, About ahk_class #32770
	}


	rename_help_button(about_window)
	{
		loop, 
		{
			If WinExist(about_window)
			{
				WinActivate
				ControlSetText, Button2, &GitHub
				Break
			}
		}
	}


	set_tray_tooltip()
	{
		Loop, 3
		{
			loop_index := A_Index - 1		; Because notify_lvl starts with 0

			if notify_lvl = %loop_index%
			{
				notify_lvl_name := lvl_name_%loop_index%
				Menu, Tray, Tip,
				( LTrim
					UAC-Focus %version%
					Notify: %notify_lvl_name%
					Beep: %beep%
				)
			}
		}
	}


	debug()
	{
	ListVars
	; Pause On
	}


	open_Location()
	{
		run, explorer %A_ScriptDir%
	}


	exit()
	{
		ExitApp
	}


; Subroutines
	flash_tray_icon:
		Menu, Tray, Icon, %tray_icon_flashed%		; Use embedded icon data
		sleep 2000
		set_tray_icon(tray_icon)
		
		/*
		Additional icons to consider:
		
		White balloon tip with "i"
		Menu, Tray, Icon, %A_Windir%\system32\shell32.dll, 222
		
		Green shield with checkmark
		Menu, Tray, Icon, %A_Windir%\system32\imageres.dll, 102
		
		Blue circled arrows
		Menu, Tray, Icon, %A_Windir%\System32\shell32.dll, 239

		Green checkmark
		Menu, Tray, Icon, %A_Windir%\System32\shell32.dll, 297
		*/

	return



; Subroutine
	request_process_elevation(args)
	{
		if not A_IsAdmin
		{
			try
			{
				if A_IsCompiled
					Run *RunAs "%A_ScriptFullPath%" %args% /restart
				else
					Run *RunAs "%A_AhkPath%" /restart "%A_ScriptFullPath%" %args%
			}
			catch
			{
				MsgBox, 0x30, UAC-Focus, The program needs to be run as Administrator!
				ExitApp
			}
		}
}


; Subroutine
	notify_toggle:
		if A_ThisMenuItem = Beep on focus
		{
			if beep = Off
			{
				beep = On
				TrayTip, UAC-Focus, Beep: %beep%,,1
				Menu, OptionID, Check, Beep on focus
				SoundBeep, , 100
				SoundBeep, , 100
			}
			else
			{
				beep = Off
				TrayTip, UAC-Focus, Beep: %beep%,,1
				Menu, OptionID, Uncheck, Beep on focus
			}
		}

		if not (A_ThisMenuItem = "Beep on focus")
		{

			; notify toggle
			Loop, 3
			{
				loop_index := A_Index - 1		; Because notify_lvl starts with 0
				notify_lvl_name := lvl_name_%loop_index%
				
				if A_ThisMenuItem = %notify_lvl_name%
				{
					notify_lvl = %loop_index%
					Menu, OptionID, Check, %notify_lvl_name%
					TrayTip, UAC-Focus, Notify: %notify_lvl_name%,,1
				}
				else
				{
					Menu, OptionID, Uncheck, %notify_lvl_name%
				}
			}
		}

		set_tray_tooltip()
	return


; Subroutine
	help_box:

		If not WinExist(help_window)
			MsgBox, 0x20, Help, %help_text%
		else
			WinActivate
	return


; Subroutine
	about_box:
		OnMessage(0x53, "help_button_action")	; WM_HELP
		Gui +OwnDialogs

		fn := Func("rename_help_button").Bind(about_window)
		SetTimer, % fn, -20		; less than 20ms won't work

		If not WinExist(about_window)
			MsgBox, 0x4040, About, %about_text%`
		else
			WinActivate

	return

; ================================================================================================
; Embedded icon data generated by Image2Include.ahk
; Do Not Change This
icon_green(NewHandle := False)
{
	Static hBitmap := icon_green()
	If (NewHandle)
	   hBitmap := 0
	If (hBitmap)
	   Return hBitmap
	VarSetCapacity(B64, 5716 << !!A_IsUnicode)
	B64 := "
	( LTrim
		AAABAAEAICAAAAEAIACoEAAAFgAAACgAAAAgAAAAQAAAAAEAIAAAAAAAABAAABMLAAATCwAAAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAAAAAAAAAAAAAAAAAAADAAAALQAAAFUAAABxAAAAfwAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAIAA
		AACAAAAAgAAAAIAAAAB7AAAAbgAAAFgAAAAwAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAAAAOwUKCoMzbHGsSJ6s1E60yvFRvNX+T7vV/0+71f9Pu9X/Tb3V/0+rvf+6oVH/uHsA/7N6AP+veAD/
		r3gA/7B6APqpdwDtmW4A12tRALAKCACDAAAAOwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAFwAAAE
		wzam+rT7bL70i12P8/rdf/OKbW/zak1v82pNb/NaPV/zWj1f80pdX/NYOl/6JxN/+cUQD/jEsA/4BEAP+ARQD/h0kA
		/49QAP+aWwD/pmkA/6d1AO9iSwCrAAAATAAAABcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABIDBQWBR5qny0q63v8+rt
		z/N6jc/zen2/83p9v/N6fb/zeo3P83qNz/N6jc/zWr3P82h6v/pnQ5/3hAAP8qFwH/RScB/1YwAP9tOgD/dD4A/4VH
		AP+STgD/nFoA/6ZqAP+MZwDLBQQAgQAAABIAAAAAAAAAAAAAAAAAAAAAAAAAS0WXosZJvuT/Oa7j/zmt4v85ruP/Oa
		7k/zir4P82pdj/NaPV/zeq3v85ruP/OLLl/zmNsv+qdjr/LxkB/yTHJP8dox3/EmQS/w9SD/9ZMQD/gEUA/5NOAP+Y
		UQD/lVAA/6RnAP+FYgDGAAAASwAAAAAAAAAAAAAAAAAAAD41b3SrTsTp/zuz6f87s+r/O7Tr/zu07P87te3/OKzh/z
		GVw/8ujbj/M53N/zmv5f86ue//O5O5/5lrNP9CIQD/Pt0+/z7dPv8y2zL/H68f/z4gAP+PTAD/nVQA/55UAP+ZUgD/
		llEA/6ZqAP9kTACrAAAAPgAAAAAAAAAEBg0Ng1fG3/JDve7/PLjw/zy48f89uvP/Pbv0/z689v8UMDv/GDpK/yBiff
		8sh7D/NaHS/zm47P87lLr/NSUR/yG5If8+3T7/Pt0+/z7dPv8oFgH/YTYB/6JWAP+qWgD/pVgA/55UAP+YUQD/nFkA
		/6l1APIMCgCEAAAABAAAAC44d32uT8nw/z279P8+vPb/Pr33/z6++f8/v/r/P8D7/xk+T/833Df/FzVD/x9gfP8tib
		T/NabW/yxviv9FLhX/PN08/z7dPv8+3T7/Jc8l/0IiAP+eVAD/sV8A/7JfAP+rWwD/o1cA/5xTAP+XUQD/p2oA/2lP
		AK4AAAAvAAAAVlCwwNZHw/T/Pr75/z+/+v8/wPv/P8H9/z/B/f9Awv7/GT5Q/z7dPv8z2zP/FzVE/yBifv8sjbX/Ey
		ct/yLAIv8+3T7/PN08/z7dPv8pFwH/ZjkB/61dAP+6YwD/t2IA/7FeAP+pWgD/oFYA/5pSAP+gXgD/mG4A1gAAAFcA
		AABtV8fe7EPC+P8/wf3/P8H9/0DC/v9Aw///QMP//0DD//8ZPlD/Pt0+/z7dPv8z2zP/FzVE/x9jfv8ZND//Pt0+/z
		7dPv8+3T7/JtYm/0MiAP+XUQD/qVsA/69dAP+sXAD/qFkA/6BVAP+bUwD/mlIA/51XAP+rdwDwAAAAcAAAAHpb1O/5
		QMH7/0HD//9ExP//Q8T//0PE//9Bw///QMP//xk+UP8+3T7/Pt0+/z7dPv8z2zP/FzZE/x+tH/8+3T7/Pt0+/z7dPv
		8kFAH/WjIB/4lJAP+OTAD/j0wA/41LAP+KSgD/hUcA/4pKAP+XUAD/nVQA/7V8APwAAAB9AAAAgFzZ9/8/wf3/Ssb/
		/0rG//9Hxf//RcX//0HD//9Aw///GT5Q/z7dPv8+3T7/Pt0+/z7dPv8z2zP/Pt0+/z7dPv8+3T7/Pt0+/yMTAf8kEw
		H/JBQB/yQUAf8kFAH/JBMB/yMTAf8kFAH/hkcA/5hRAP+dVAD/t30A/wAAAIAAAACAXdv5/0DD//9QyP//Tsf//0rG
		//9Gxf//QsT//0DD//8ZPlD/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/PN
		08/zrcOv853Dn/Jc8l/ygVAf+WUAD/nlQA/59VAP+4fgD/AAAAgAAAAIBd3Pr/RMT//1PJ//9QyP//S8f//0bF//9C
		xP//QMP//xk+UP8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/PN08/y
		bVJv8pFgH/e0MA/6RXAP+jWAD/n1UA/7l+AP8AAACAAAAAgFrd+/9Ex///Usv//07K//9Jyf//RMf//z/G//89xf//
		GD9Q/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8m2Cb/KhYB/4BEAP
		+vWgD/rFoA/6ZWAP+hVAD/uXwA/wAAAIAAAACAn93y/3PH7v9+zO//e8rv/3bJ7v9yx+7/b8bt/23F7f8nP0r/Pt0+
		/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/K9or/yodDf+DXSz/tn49/7Z/Pv+ueT
		v/p3Q5/6JxN/+6oVH/AAAAgAAAAIDIhhv/nmMd/6VuLv+jayn/n2Uh/51hGv+aXRX/mVsS/zUeBv8+3T7/Pt0+/z7d
		Pv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/zDaMP8RISf/LG2H/z2WvP89mMD/O5S6/zmNsv82h6v/NY
		Ol/0+rvf8AAACAAAAAgNyUAP/FbQ3/yXgf/8h0Gf/GbxH/xGsK/8NnA//CZQD/QiEA/z7dPv8+3T7/Pt0+/z7dPv8+
		3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv853Dn/ESky/yuJrv88vvX/PsP8/zzB+P86uvD/OLLl/zWr3P80pdX/Tb3V/w
		AAAIAAAACA25YA/8NvD//HeiH/xnYb/8RxEv/CbAr/wGgD/79mAP9BIQD/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/
		Pt0+/z7dPv8+3T7/Otw6/xEoMv8sh67/Pbv1/0DC/v8/wf3/Pr74/zy48P85r+X/N6jc/zWj1f9Pu9X/AAAAgAAAAI
		DblgD/xHET/8h8Jf/HeB7/xHIU/8JtC//AaAT/v2YA/0EhAP8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+
		/zzdPP8RKDL/LIeu/z279f9Awv7/QMP//z/B/f8+vvj/PLjw/zmv5f83qNz/NaPV/0+71f8AAACAAAAAgNyXAP/FdR
		n/yoAr/8h6Iv/FdBf/wm4N/8BpBf+/ZwH/QSEA/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/ESgy/yyH
		rv89u/X/QML+/0DD//9Aw///P8H9/z6++P88uPD/Oa/l/zeo3P82pNb/T7vV/wAAAIAAAAB825YA/Mh7Iv/MhTT/yo
		Ar/8Z3Hf/DcBH/wWoH/79nAf9BIQD/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/xEpMv8sh67/Pbv1/0DC/v9A
		w///QMP//0DC/v8/wfz/Pr33/zy48P85r+X/N6fb/zek1v9Qu9P8AAAAfQAAAHDTlALvzoYt/8+MQP/Nhjb/yX0m/8
		V0F//CbQv/wGgE/0EhAP8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8aKS7/Koiu/z279f9Awv7/QMP//0DD//9Aw///
		QML+/z/B/P8+vff/PLfv/zmu5P83p9v/OabW/02zyfAAAABwAAAAVbuKCtXVlTr/05VO/9CPRP/MhTP/yHoi/8RxE/
		/Bawn/QSIB/z7dPv8+3T7/Pt0+/z7dPv8+3T7/IhQE/0qIof87vfX/QML+/0DD//9Aw///QMP//0DD//9Awv7/P8D7
		/z689v87te3/Oa7k/zen2/8+rdf/SJ+u1QAAAFYAAAAtfmIKrN+nRP/WnVz/1JlV/9COQ//LgzH/x3kg/8RxE/9CJA
		T/Pt0+/z7dPv8+3T7/Pt0+/ysXAf9pQg//a77k/z/F/v9CxP//QsT//0HD//9Bw///QMP//z/B/f8/v/r/Pbv0/zu0
		7P85ruP/N6jc/0e12P80bXOtAAAALgAAAAMMCgGD261E8d6sZ//Zo2b/1ZpW/9COQ//LgzH/yHoi/0MmCP8+3T7/Pt
		0+/z7dPv8qGAP/hksH/5ddGf9yxu3/RMf//0bF//9Gxf//RcX//0PE//9Aw///P8H9/z6++f89uvP/O7Tr/zmt4v8+
		r9z/ULfM8QUKCoMAAAADAAAAAAAAAD15ZCCp5rlp/9upcP/ZpGf/1ZpW/9CPRP/MhTT/RCkM/z7dPv8+3T7/KxkF/4
		ZPDf++axD/nmUh/3bJ7v9Jyf//S8f//0rG//9Hxf//Q8T//0DC/v8/wPv/Pr33/zy48f87s+r/Oa7j/0q73v8yaG2q
		AAAAPQAAAAAAAAAAAAAAAAAAAEuxk0LJ5blw/9yrcP/Zo2b/1ZpW/9CPRf9FKxH/Pt0+/ywbB/+HVBX/vnEa/8d0Gf
		+jayn/e8rv/07K//9QyP//Tsf//0rG//9DxP//P8H9/z+/+v8+vPb/PLjw/zy06f9JvuT/RpijyQAAAEsAAAAAAAAA
		AAAAAAAAAAAAAAAAFQQDAYGpjj/E5rpp/96sZ//Wnl3/05VP/0cuFP8xIAz/ilkd/8B3JP/GeiH/yXgf/6VuLv9+zO
		//Usv//1PJ//9PyP//Scb//0DD//8/wfz/Pr75/z279P9Evu//T8Tp/0WVn8QCBASBAAAAFQAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAAEAAAAEtyXh6m2axD7d+oRP/Wlzr/RywP/5VfGv+/cRj/w3ET/8NvD//FbQ3/nmMd/3PH7v9Ex///RM
		T//0DD//8/wf3/QcL7/0PD+P9IxfT/UMrw/1bE2u0xaGynAAAASwAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAAADkIBgGCd10JqbaHCtHSkwLu25YA+tyXAP/blgD/25YA/9yUAP/Ihhv/n93y/1nd+v9d3Pr/Xdv5/1
		zZ9/9a0u34V8Xc6k6rutE1bnOpBAcHggAAADkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAIAAAApAAAAUQAAAG4AAAB7AAAAgAAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAH
		gAAABrAAAAUQAAACkAAAACAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA/AAAP/gAAB/gAAAHwAAAA8AAAAOAAAABAAAA
		AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAACAAAABwAAAA8AAAAPgAAAH+AAAH/wAAD8=
	)"

	If
	( RTrim0 Join
		!DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt",
		0, "UInt", 0x01, "Ptr", 0, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
	)
	   Return False

	VarSetCapacity(Dec, DecLen, 0)

	If
	( RTrim0 Join
		!DllCall("Crypt32.dll\CryptStringToBinary", "Ptr", &B64, "UInt",
		0, "UInt", 0x01, "Ptr", &Dec, "UIntP", DecLen, "Ptr", 0, "Ptr", 0)
	)
	   Return False

	; Bitmap creation adopted from "How to convert Image data
	; (JPEG/PNG/GIF) to hBITMAP?" by SKAN
	; -> http://www.autohotkey.com/board/topic/21213-how-to-convert-image-
	; data-jpegpnggif-to-hbitmap/?p=139257

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
