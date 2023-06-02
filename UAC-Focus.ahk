Loop
{

	WinWait, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe
	
	ifWinNotActive, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe
	{
		WinActivate
		; TrayTip, UAC-Focus, Window focused, 3, 1
	}
	else
	{
		; TrayTip, UAC-Focus, Already in focus, 3, 1
	}
	
	WinWaitClose, ahk_class Credential Dialog Xaml Host ahk_exe consent.exe
	
}
