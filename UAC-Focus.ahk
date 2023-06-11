/*

  UAC-Focus by lightproof

  An AutoHotKey script that focuses UAC window for quick control
  with keyboard shortcuts.

  https://github.com/lightproof/UAC-Focus


  Startup parameters:
	-notify           start with "Notify on focus" enabled by default

	-notifyall        start with "Notify always" enabled by default

	-beep             start with "Beep on focus" enabled by default

	-beepall          also beep when the UAC window pops up
					  already focused by the OS

	-showtip          display current settings in a tray tooltip
					  at script startup

	-noflash          do not briefly change tray icon when
					  the UAC window gets focused

*/

; startup settings
	#NoEnv
	#SingleInstance Force
	#WinActivateForce
	Process, Priority,, Normal
	SetBatchLines, 2
	DetectHiddenWindows, On

; Vars
	Version := "v0.6.1"
	app_name := "UAC-Focus by lightproof"
	global tray_icon := A_ScriptDir "/assets/icon.ico"
	global tray_icon_green := "HICON:*" . icon_green()
	global repo := "https://github.com/lightproof/UAC-Focus"
	Own_PID := DllCall("GetCurrentProcessId")
	AboutWindow := "About ahk_class #32770 ahk_pid" Own_PID
	HelpWindow := "Help ahk_class #32770 ahk_pid" Own_PID

; Set app tray icon
	Gosub set_tray_icon

; Set defaults
	global notify_lvl := 0
	global startup_tip := 0
	global beep := "Off"
	global tray_icon_flash := 1

; Set string names
	lvl_name_0 := "Never"
	lvl_name_1 := "On focus"
	lvl_name_2 := "Always"

; About window
	about_text := "
	( LTrim RTrim0 Join
		" app_name " " version "
		`n`n

		An AutoHotKey script that focuses UAC window 
		for quick control with keyboard shortcuts.
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
		This will display notification each time the UAC window gets 
		focused.
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
		This will sound two short beeps each time the UAC window gets 
		focused.
		`n`n

		-beepall
		`n
		Same as above, but also beep once when the UAC window pops up 
		already focused by the OS.
		`n`n

		-showtip
		`n
		Display current settings in a tray tooltip at script startup.
		`n`n

		-noflash
		`n
		Do not briefly change tray icon when the UAC window 
		gets focused.
		)"

; Set startup parameters
	Loop, %0%		; do for each parameter
	{
		args := args %A_Index% " "		; combined arguments string
		arg := %A_Index%

		if arg = -notify
		{
			global notify_lvl := 1
		}

		if arg = -notifyall
		{
			global notify_lvl := 2
		}

		if arg = -showtip
		{
			startup_tip = 1
		}

		if arg = -beep
		{
			global beep := "On"
		}

		if arg = -beepall
		{
			global beep := "All"
		}

		if arg = -noflash
		{
			global tray_icon_flash := 0
		}
	}

; Request process elevation if not admin
	Gosub elevation_check

; Set and/or show the tooltip on startup
	Gosub set_tray_tooltip

	if (A_IsAdmin and startup_tip = 1)
	{
		TrayTip, 
		( LTrim RTrim0 Join
		UAC-Focus %version%, Notify: %Menu_item_name%`nBeep: %beep%, 
		3, 0x1
		)
	}

; Tray menu
	Menu, Tray, Click, 2
	Menu, Tray, NoStandard		; Standard/NoStandard  = debugging / normal
	Menu, Tray, Add, &About, about_box
	Menu, Tray, Default, &About

	; letter «i» in blue circle
	Menu, Tray, Icon, &About, %A_Windir%\system32\SHELL32.dll, 278
	Menu, Tray, Add

	; "Notify" submenu
	Menu, OptionID, Add, %lvl_name_0%, notify_toggle
	Menu, OptionID, Add, %lvl_name_1%, notify_toggle
	Menu, OptionID, Add, %lvl_name_2%, notify_toggle
	Menu, OptionID, Add
	Menu, OptionID, Add, Beep on focus, notify_toggle
	Menu, Tray, Add, &Notify, :OptionID
	
	; white balloon tip with «i»
	; Menu, Tray, Icon, &Notify, %A_Windir%\system32\SHELL32.dll, 222

	; check matching notify_lvl entry
	Menu_item_name := lvl_name_%notify_lvl%
	Menu, OptionID, Check, %Menu_item_name%

	; check/uncheck beep menu
	if not beep = "Off"
	{
		Menu, OptionID, Check, Beep on focus
	}
	else
	{
		Menu, OptionID, Uncheck, Beep on focus
	}

	Menu, Tray, Add
	Menu, Tray, Add, &Open file location, Open_Location
	
	; document with loupe
	Menu, Tray, Icon, &Open file location, %A_Windir%\system32\SHELL32.dll, 56

	Open_Location()
	{
		run, explorer %A_ScriptDir%
	}

	Menu, Tray, Add, &Help, help_box
	
	; «?» mark in blue circle
	Menu, Tray, Icon, &Help, %A_Windir%\system32\SHELL32.dll, 24
	Menu, Tray, Add
	Menu, Tray, Add, E&xit, Exit

	; red «X» mark
	; Menu, Tray, Icon, E&xit, %A_Windir%\system32\SHELL32.dll, 132

	Exit()
	{
		ExitApp
	}

; Shell hook
Gui +LastFound
hWnd := WinExist()

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

			if (InStr(class, "Credential Dialog Xaml Host")
				and InStr(process, "consent.exe"))
			{
				
				; temporarily change to 'if not' for easier debugging
				if WinActive (ahk_id lParam)
				{

					if (beep = "All")
						soundbeep, , 100

					if notify_lvl = 2
						TrayTip, UAC-Focus, Already in focus, 3, 1
				}
				else
				{
					WinActivate (ahk_id lParam)

					Gosub activation_followup
				}

				; if enabled, stops working with multiple windows:
				; WinWaitClose, ahk_id %lParam%
			}
		}
	}

; ============================================================================
; Subroutines
	set_tray_icon:

		if FileExist(tray_icon)
		{
			Menu, Tray, Icon, %tray_icon%
		}

	return
	
; Subroutine
	tray_icon_flash:

		SetTimer, tray_icon_flash, Off

		; green shield with checkmark
		; Menu, Tray, Icon, %A_Windir%\system32\imageres.dll, 102

		; blue circled arrows
		; Menu, Tray, Icon, %A_Windir%\System32\shell32.dll, 239

		; green checkmark
		; Menu, Tray, Icon, %A_Windir%\System32\shell32.dll, 297

		; flash tray icon
		Loop, 4
		{
			Menu, Tray, Icon, %tray_icon_green%		; use embedded icon data
			sleep 125
			Gosub set_tray_icon
			sleep 125
		}

	return

; Subroutine
	activation_followup:

		if (notify_lvl = "1" or notify_lvl = "2")
		{
			TrayTip, UAC-Focus, Window focused, 3, 1

			if not beep = "Off"
			{
				Loop, 2
					SoundBeep, , 100
			}
		}

		if tray_icon_flash
		{
			SetTimer, tray_icon_flash, 10
		}

	return

; Subroutine
	set_tray_tooltip:

		Loop, 3
		{
			Indx := A_Index - 1		; because notify_lvl starts with 0

			if notify_lvl = %Indx%
			{
				Menu_item_name := lvl_name_%Indx%
				Menu, Tray, Tip
				, UAC-Focus %version%`nNotify: %Menu_item_name%`nBeep: %beep%
			}
		}

	return

; Subroutine
	elevation_check:

		if not A_IsAdmin
		{

			try
			{

				if A_IsCompiled
				{
					Run *RunAs "%A_ScriptFullPath%" %args% /restart
				}
				else
				{
					(RTrim0 Join
						Run *RunAs "%A_AhkPath%" /restart 
						"%A_ScriptFullPath%" %args%
					)
				}
			}
			catch
			{
				MsgBox, 0x30, UAC-Focus
				, The program needs to be run as Administrator!
				ExitApp
			}
		}

	return

; Subroutine
	notify_toggle:

		if (A_ThisMenuItem = "Beep on focus" and not beep = "On")
			{
				beep = On
				Menu, OptionID, Check, Beep on focus
				SoundBeep, , 100
				SoundBeep, , 100
			}
			else
			{
				beep = Off
				Menu, OptionID, Uncheck, Beep on focus
			}

		if not (A_ThisMenuItem = "Beep on focus")
		{

			; notify toggle
			Loop, 3
			{
				Indx = %A_Index%
				Indx := Indx - 1
				Menu_item_name := lvl_name_%Indx%

				if A_ThisMenuItem = %Menu_item_name%
				{
					Menu, OptionID, Check, %Menu_item_name%
					notify_lvl = %Indx%
				}
				else
				{
					Menu, OptionID, Uncheck, %Menu_item_name%
				}
			}
		}

		Gosub set_tray_tooltip

	return

; Subroutine
	help_box:

		If not WinExist(HelpWindow)
		{
			MsgBox, 0x20, Help, %help_text%
		}
		else
		{
			WinActivate
		}

	return

; Subroutine
	about_box:

		; "Help" button control
		OnMessage(0x53, "WM_HELP")
		Gui +OwnDialogs

		SetTimer, Button_Rename, 10

		If not WinExist(AboutWindow)
		{
			MsgBox, 0x4040, About, %about_text%`
		}

		; "Help" button action
		 WM_HELP()
		 {
			run, %repo%
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

; Embedded icon data generated by Image2Include.ahk
; DO NOT CHANGE!
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
		AAABAAEAICAAAAEAIACoEAAAFgAAACgAAAAgAAAAQAAAAAEAIAAAAAAAABAAABMLAAATCw
		AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADAAAALQAAAFUAAABxAAAA
		fwAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAIAAAACAAAAAgAAAAIAAAAB7AAAAbgAAAF
		gAAAAwAAAAAwAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		AAAAOwUKCoMzbHGsSJ6s1E60yvFRvNX+T7vV/0+71f9Pu9X/Tb3V/0+rvf+6oVH/uHsA/7
		N6AP+veAD/r3gA/7B6APqpdwDtmW4A12tRALAKCACDAAAAOwAAAAAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAAAAAAAAAAAAAAFwAAAEwzam+rT7bL70i12P8/rdf/OKbW/zak1v82pNb/Na
		PV/zWj1f80pdX/NYOl/6JxN/+cUQD/jEsA/4BEAP+ARQD/h0kA/49QAP+aWwD/pmkA/6d1
		AO9iSwCrAAAATAAAABcAAAAAAAAAAAAAAAAAAAAAAAAAAAAAABIDBQWBR5qny0q63v8+rt
		z/N6jc/zen2/83p9v/N6fb/zeo3P83qNz/N6jc/zWr3P82h6v/pnQ5/3hAAP8qFwH/RScB
		/1YwAP9tOgD/dD4A/4VHAP+STgD/nFoA/6ZqAP+MZwDLBQQAgQAAABIAAAAAAAAAAAAAAA
		AAAAAAAAAAS0WXosZJvuT/Oa7j/zmt4v85ruP/Oa7k/zir4P82pdj/NaPV/zeq3v85ruP/
		OLLl/zmNsv+qdjr/LxkB/yTHJP8dox3/EmQS/w9SD/9ZMQD/gEUA/5NOAP+YUQD/lVAA/6
		RnAP+FYgDGAAAASwAAAAAAAAAAAAAAAAAAAD41b3SrTsTp/zuz6f87s+r/O7Tr/zu07P87
		te3/OKzh/zGVw/8ujbj/M53N/zmv5f86ue//O5O5/5lrNP9CIQD/Pt0+/z7dPv8y2zL/H6
		8f/z4gAP+PTAD/nVQA/55UAP+ZUgD/llEA/6ZqAP9kTACrAAAAPgAAAAAAAAAEBg0Ng1fG
		3/JDve7/PLjw/zy48f89uvP/Pbv0/z689v8UMDv/GDpK/yBiff8sh7D/NaHS/zm47P87lL
		r/NSUR/yG5If8+3T7/Pt0+/z7dPv8oFgH/YTYB/6JWAP+qWgD/pVgA/55UAP+YUQD/nFkA
		/6l1APIMCgCEAAAABAAAAC44d32uT8nw/z279P8+vPb/Pr33/z6++f8/v/r/P8D7/xk+T/
		833Df/FzVD/x9gfP8tibT/NabW/yxviv9FLhX/PN08/z7dPv8+3T7/Jc8l/0IiAP+eVAD/
		sV8A/7JfAP+rWwD/o1cA/5xTAP+XUQD/p2oA/2lPAK4AAAAvAAAAVlCwwNZHw/T/Pr75/z
		+/+v8/wPv/P8H9/z/B/f9Awv7/GT5Q/z7dPv8z2zP/FzVE/yBifv8sjbX/Eyct/yLAIv8+
		3T7/PN08/z7dPv8pFwH/ZjkB/61dAP+6YwD/t2IA/7FeAP+pWgD/oFYA/5pSAP+gXgD/mG
		4A1gAAAFcAAABtV8fe7EPC+P8/wf3/P8H9/0DC/v9Aw///QMP//0DD//8ZPlD/Pt0+/z7d
		Pv8z2zP/FzVE/x9jfv8ZND//Pt0+/z7dPv8+3T7/JtYm/0MiAP+XUQD/qVsA/69dAP+sXA
		D/qFkA/6BVAP+bUwD/mlIA/51XAP+rdwDwAAAAcAAAAHpb1O/5QMH7/0HD//9ExP//Q8T/
		/0PE//9Bw///QMP//xk+UP8+3T7/Pt0+/z7dPv8z2zP/FzZE/x+tH/8+3T7/Pt0+/z7dPv
		8kFAH/WjIB/4lJAP+OTAD/j0wA/41LAP+KSgD/hUcA/4pKAP+XUAD/nVQA/7V8APwAAAB9
		AAAAgFzZ9/8/wf3/Ssb//0rG//9Hxf//RcX//0HD//9Aw///GT5Q/z7dPv8+3T7/Pt0+/z
		7dPv8z2zP/Pt0+/z7dPv8+3T7/Pt0+/yMTAf8kEwH/JBQB/yQUAf8kFAH/JBMB/yMTAf8k
		FAH/hkcA/5hRAP+dVAD/t30A/wAAAIAAAACAXdv5/0DD//9QyP//Tsf//0rG//9Gxf//Qs
		T//0DD//8ZPlD/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7d
		Pv8+3T7/PN08/zrcOv853Dn/Jc8l/ygVAf+WUAD/nlQA/59VAP+4fgD/AAAAgAAAAIBd3P
		r/RMT//1PJ//9QyP//S8f//0bF//9CxP//QMP//xk+UP8+3T7/Pt0+/z7dPv8+3T7/Pt0+
		/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/PN08/ybVJv8pFgH/e0MA/6RXAP
		+jWAD/n1UA/7l+AP8AAACAAAAAgFrd+/9Ex///Usv//07K//9Jyf//RMf//z/G//89xf//
		GD9Q/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z
		7dPv8m2Cb/KhYB/4BEAP+vWgD/rFoA/6ZWAP+hVAD/uXwA/wAAAIAAAACAn93y/3PH7v9+
		zO//e8rv/3bJ7v9yx+7/b8bt/23F7f8nP0r/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt
		0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/K9or/yodDf+DXSz/tn49/7Z/Pv+ueTv/p3Q5/6Jx
		N/+6oVH/AAAAgAAAAIDIhhv/nmMd/6VuLv+jayn/n2Uh/51hGv+aXRX/mVsS/zUeBv8+3T
		7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/zDaMP8RISf/LG2H
		/z2WvP89mMD/O5S6/zmNsv82h6v/NYOl/0+rvf8AAACAAAAAgNyUAP/FbQ3/yXgf/8h0Gf
		/GbxH/xGsK/8NnA//CZQD/QiEA/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/
		Pt0+/z7dPv853Dn/ESky/yuJrv88vvX/PsP8/zzB+P86uvD/OLLl/zWr3P80pdX/Tb3V/w
		AAAIAAAACA25YA/8NvD//HeiH/xnYb/8RxEv/CbAr/wGgD/79mAP9BIQD/Pt0+/z7dPv8+
		3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Otw6/xEoMv8sh67/Pbv1/0DC/v8/wf3/Pr
		74/zy48P85r+X/N6jc/zWj1f9Pu9X/AAAAgAAAAIDblgD/xHET/8h8Jf/HeB7/xHIU/8Jt
		C//AaAT/v2YA/0EhAP8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/zzdPP8RKD
		L/LIeu/z279f9Awv7/QMP//z/B/f8+vvj/PLjw/zmv5f83qNz/NaPV/0+71f8AAACAAAAA
		gNyXAP/FdRn/yoAr/8h6Iv/FdBf/wm4N/8BpBf+/ZwH/QSEA/z7dPv8+3T7/Pt0+/z7dPv
		8+3T7/Pt0+/z7dPv8+3T7/ESgy/yyHrv89u/X/QML+/0DD//9Aw///P8H9/z6++P88uPD/
		Oa/l/zeo3P82pNb/T7vV/wAAAIAAAAB825YA/Mh7Iv/MhTT/yoAr/8Z3Hf/DcBH/wWoH/7
		9nAf9BIQD/Pt0+/z7dPv8+3T7/Pt0+/z7dPv8+3T7/Pt0+/xEpMv8sh67/Pbv1/0DC/v9A
		w///QMP//0DC/v8/wfz/Pr33/zy48P85r+X/N6fb/zek1v9Qu9P8AAAAfQAAAHDTlALvzo
		Yt/8+MQP/Nhjb/yX0m/8V0F//CbQv/wGgE/0EhAP8+3T7/Pt0+/z7dPv8+3T7/Pt0+/z7d
		Pv8aKS7/Koiu/z279f9Awv7/QMP//0DD//9Aw///QML+/z/B/P8+vff/PLfv/zmu5P83p9
		v/OabW/02zyfAAAABwAAAAVbuKCtXVlTr/05VO/9CPRP/MhTP/yHoi/8RxE//Bawn/QSIB
		/z7dPv8+3T7/Pt0+/z7dPv8+3T7/IhQE/0qIof87vfX/QML+/0DD//9Aw///QMP//0DD//
		9Awv7/P8D7/z689v87te3/Oa7k/zen2/8+rdf/SJ+u1QAAAFYAAAAtfmIKrN+nRP/WnVz/
		1JlV/9COQ//LgzH/x3kg/8RxE/9CJAT/Pt0+/z7dPv8+3T7/Pt0+/ysXAf9pQg//a77k/z
		/F/v9CxP//QsT//0HD//9Bw///QMP//z/B/f8/v/r/Pbv0/zu07P85ruP/N6jc/0e12P80
		bXOtAAAALgAAAAMMCgGD261E8d6sZ//Zo2b/1ZpW/9COQ//LgzH/yHoi/0MmCP8+3T7/Pt
		0+/z7dPv8qGAP/hksH/5ddGf9yxu3/RMf//0bF//9Gxf//RcX//0PE//9Aw///P8H9/z6+
		+f89uvP/O7Tr/zmt4v8+r9z/ULfM8QUKCoMAAAADAAAAAAAAAD15ZCCp5rlp/9upcP/ZpG
		f/1ZpW/9CPRP/MhTT/RCkM/z7dPv8+3T7/KxkF/4ZPDf++axD/nmUh/3bJ7v9Jyf//S8f/
		/0rG//9Hxf//Q8T//0DC/v8/wPv/Pr33/zy48f87s+r/Oa7j/0q73v8yaG2qAAAAPQAAAA
		AAAAAAAAAAAAAAAEuxk0LJ5blw/9yrcP/Zo2b/1ZpW/9CPRf9FKxH/Pt0+/ywbB/+HVBX/
		vnEa/8d0Gf+jayn/e8rv/07K//9QyP//Tsf//0rG//9DxP//P8H9/z+/+v8+vPb/PLjw/z
		y06f9JvuT/RpijyQAAAEsAAAAAAAAAAAAAAAAAAAAAAAAAFQQDAYGpjj/E5rpp/96sZ//W
		nl3/05VP/0cuFP8xIAz/ilkd/8B3JP/GeiH/yXgf/6VuLv9+zO//Usv//1PJ//9PyP//Sc
		b//0DD//8/wfz/Pr75/z279P9Evu//T8Tp/0WVn8QCBASBAAAAFQAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAAEAAAAEtyXh6m2axD7d+oRP/Wlzr/RywP/5VfGv+/cRj/w3ET/8NvD//FbQ
		3/nmMd/3PH7v9Ex///RMT//0DD//8/wf3/QcL7/0PD+P9IxfT/UMrw/1bE2u0xaGynAAAA
		SwAAABAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADkIBgGCd10JqbaHCt
		HSkwLu25YA+tyXAP/blgD/25YA/9yUAP/Ihhv/n93y/1nd+v9d3Pr/Xdv5/1zZ9/9a0u34
		V8Xc6k6rutE1bnOpBAcHggAAADkAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAAAAAAAAAAIAAAApAAAAUQAAAG4AAAB7AAAAgAAAAIAAAACAAAAAgAAAAIAA
		AACAAAAAgAAAAIAAAACAAAAAgAAAAHgAAABrAAAAUQAAACkAAAACAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAAAA/AAAP/gAAB/gAAAHwAAAA8AAAAOAAAABAAAAAAAAAAAAAAAAAAAAAAAA
		AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
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
		
		hData := 
			( LTrim RTrim0 Join
				DllCall("Kernel32.dll\GlobalAlloc", "UInt", 2, "UPtr", 
				DecLen, "UPtr")
			)
		
		pData := DllCall("Kernel32.dll\GlobalLock", "Ptr", hData, "UPtr")

		DllCall(
			( LTrim RTrim0 Join
				"Kernel32.dll\RtlMoveMemory", "Ptr", pData, "Ptr", &Dec, 
				"UPtr", DecLen
			))

		DllCall(
			(
				"Kernel32.dll\GlobalUnlock", "Ptr", hData
			))

		DllCall(
			( LTrim RTrim0 Join
				"Ole32.dll\CreateStreamOnHGlobal", "Ptr", hData, "Int", True, 
				"PtrP", pStream
			))

		hGdip := DllCall(
					( RTrim0 Join
						"Kernel32.dll\LoadLibrary", "Str", "Gdiplus.dll", 
						"UPtr"
					))

		VarSetCapacity(SI, 16, 0), NumPut(1, SI, 0, "UChar")

		DllCall(
			( LTrim RTrim0 Join
				"Gdiplus.dll\GdiplusStartup", "PtrP", pToken, "Ptr", &SI, 
				"Ptr", 0
			))
			
		DllCall(
			( LTrim RTrim0 Join
				"Gdiplus.dll\GdipCreateBitmapFromStream",  "Ptr", pStream, 
				"PtrP", pBitmap
			))
			
		DllCall(
			( LTrim RTrim0 Join
				"Gdiplus.dll\GdipCreateHICONFromBitmap", "Ptr", pBitmap, 
				"PtrP", hBitmap, "UInt", 0
			))
			
		DllCall("Gdiplus.dll\GdipDisposeImage", "Ptr", pBitmap)
		DllCall("Gdiplus.dll\GdiplusShutdown", "Ptr", pToken)
		DllCall("Kernel32.dll\FreeLibrary", "Ptr", hGdip)

		DllCall(
			( LTrim RTrim0 Join
				NumGet(NumGet(pStream + 0, 0, "UPtr") + (A_PtrSize * 2), 0, 
				"UPtr"), "Ptr", pStream
			))

	Return hBitmap
	}
