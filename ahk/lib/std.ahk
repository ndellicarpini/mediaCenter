; ----- GLOBAL VARIABLES -----
global MAINNAME := "MediaCenterMain"
global MAINLOOP := "MediaCenterLoop"
global SENDNAME := "Send2Main"

global DYNASTART := "; ----- DO NOT EDIT: DYNAMIC INCLUDE START -----"
global DYNAEND   := "; -----  DO NOT EDIT: DYNAMIC INCLUDE END  -----"

; ----- FUNCTIONS -----

; creates & waits for close an error message popup containing message
;  message - message to show in MsgBox
;  exit - boolean if program should exit after error
;
; returns null
ErrorMsg(message, exit := false) {
	MsgBox(
		(
			((exit) ? "FATAL " : "") "ERROR:
			" message "
			"
		),
		"Error"
	)

	WinWaitClose()

	if (exit) {
		ExitApp()
	}
}

; window closes an error message
;  wndwID - ahk_id of error window
;
; returns null
CloseErrorMsg(wndwID) {
	window := "ahk_id " wndwID

	ControlSend "{Enter}",, window
	Sleep(250)

	if (WinShown(window)) {
		WinClose(window)
	}
}

; Runs a program as an admin
;  program - program to run
;  parameters - parameters to pass to the program
;  directory - directory to run in
;
; returns null
RunAsAdmin(program, parameters := "", directory := "") {
	cleanParameters := (Type(parameters) = "Array") ? joinArray(parameters) : parameters
	programString := program . ((Trim(cleanParameters) != "") ? A_Space . cleanParameters : "")

	if (!A_IsAdmin) {
		ErrorMsg("Cannot Run '" . program . "' as Administrator")
		return Run(programString, directory)
	}

	return Run('*RunAs "' . programString . '"', directory)
}

; Runs a program as a regular user
; yoinked from https://www.autohotkey.com/boards/viewtopic.php?t=78190
;  program - program to run
;  parameters - parameters to pass to the program
;  directory - directory to run in
;
; returns null
RunAsUser(program, parameters := "", directory := "") {
	cleanProgram := Trim(program, A_Space . "'" . '"')
	cleanParameters := Trim((Type(parameters) = "Array") ? joinArray(parameters) : parameters)
	cleanDirectory := Trim(directory, A_Space . "'" . '"')

	if (!WinHidden("ahk_class Shell_TrayWnd")) {
		if (ProcessExist("explorer.exe")) {
			ProcessClose("explorer.exe")
			Sleep(1000)
		}

		Run("explorer.exe")
		Sleep(5000)
	}

	if (!A_IsAdmin) {
		return Run(program . ((cleanParameters != "") ? A_Space . cleanParameters : ""), directory)
	}

    shellWindows := ComObject("Shell.Application").Windows
    desktop := shellWindows.FindWindowSW(0, 0, 8, 0, 1) ; SWC_DESKTOP, SWFO_NEEDDISPATCH
   
    ; Retrieve top-level browser object.
    tlb := ComObjQuery(desktop,
        "{4C96BE40-915C-11CF-99D3-00AA004AE837}", ; SID_STopLevelBrowser
        "{000214E2-0000-0000-C000-000000000046}"  ; IID_IShellBrowser
	) 
    
    ; IShellBrowser.QueryActiveShellView -> IShellView
	sv := ComValue(13, 0)
    ComCall(15, tlb, "Ptr*", sv) ; VT_UNKNOWN
    
    ; Define IID_IDispatch.
	IID_IDispatch := Buffer(16)
    NumPut("Int64", 0x20400, "Int64", 0x46000000000000C0, IID_IDispatch)
   
    ; IShellView.GetItemObject -> IDispatch (object which implements IShellFolderViewDual)
	sfvd := ComValue(9, 0)
    ComCall(15, sv, "UInt", 0, "Ptr", IID_IDispatch, "Ptr*", sfvd) ; VT_DISPATCH
   
    ; Get Shell object.
    shell := sfvd.Application

	; append args to program string if program is a url
	if (!FileExist(cleanProgram) && !FileExist(((SubStr(cleanDirectory, -1) = "\") ? cleanDirectory : cleanDirectory . "\") . cleanProgram)) {
		cleanProgram := cleanProgram . A_Space . cleanParameters
		cleanParameters := ""
	}
	
    ; IShellDispatch2.ShellExecute
    return shell.ShellExecute(cleanProgram, cleanParameters, cleanDirectory)
}

; closes a window's process based on window
;  window - window whose process to close
;
; return ProcessClose
ProcessWinClose(window) {
	exists := WinHidden(window)
	if (exists) {
		return ProcessClose(WinGetPID(exists))
	}

	return ""
}

; kills a process with extreme prejudice
;  process - process to murder
;  includeChildren - whether or not to kill child processes
;
; returns null
ProcessKill(process, includeChildren := true) {
	PID := 0
	
	if (IsInteger(process)) {
		PID := process
	}
	else if (ProcessExist(process)) {
		PID := ProcessExist(process)
	}
	else {
		PID := WinGetPID(WinHidden(process))
	}

	Run "taskkill " . ((includeChildren) ? "/t" : "") . " /f /pid " . PID,, "Hide"
}

; checks if a process is suspended
;  process - process to check
;
; returns true if process is suspended
ProcessSuspended(process) {
	PID := 0
	
	if (IsInteger(process)) {
		PID := process
	}
	else if (ProcessExist(process)) {
		PID := WinGetPID("ahk_exe " process)
	}
	else {
		PID := WinGetPID(WinHidden(process))
	}

	wmi := ComObjGet("winmgmts:")
	for thread in wmi.ExecQuery("Select * from Win32_Thread WHERE ProcessHandle = " PID) {
		if (thread.ThreadWaitReason != 5) {
			return false
		}
	}

	return true
}

; suspends a running process
;  process - process to suspend
;
; returns null
ProcessSuspend(process) {
	PID := 0
	
	if (IsInteger(process)) {
		PID := process
	}
	else if (ProcessExist(process)) {
		PID := WinGetPID("ahk_exe " process)
	}
	else {
		PID := WinGetPID(WinHidden(process))
	}

	handle := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int", PID)
	if (!handle) {
		return
	}

	DllCall("ntdll\NtSuspendProcess", "Int", handle)
	DllCall("CloseHandle", "Int", handle)
}

; resumes a suspended process
;  process - process to resume
;
; returns null
ProcessResume(process) {
	PID := 0
	
	if (IsInteger(process)) {
		PID := process
	}
	else if (ProcessExist(process)) {
		PID := WinGetPID("ahk_exe " process)
	}
	else {
		PID := WinGetPID(WinHidden(process))
	}

	handle := DllCall("OpenProcess", "UInt", 0x1F0FFF, "Int", 0, "Int", PID)
	if (!handle) {
		return
	}

	DllCall("ntdll\NtResumeProcess", "Int", handle)
	DllCall("CloseHandle", "Int", handle)
}

; gets the name from a pid
;  pid - process to get name of
;
; returns name of process, or "" if not found
ProcessGetName(pid) {
	resetDHW := A_DetectHiddenWindows
	DetectHiddenWindows(true)

	retVal := ""
	if (WinExist("ahk_pid " pid)) {
		retVal := WinGetProcessName("ahk_pid " pid)
	}

	DetectHiddenWindows(resetDHW)
	return retVal
}

; returns the winexist of the window only if the window is not hidden
;  window - window to check based on WinTitle
;
; returns winexist
WinShown(window) {
	resetDHW := A_DetectHiddenWindows

	DetectHiddenWindows(false)
	retVal := WinExist(window)
	DetectHiddenWindows(resetDHW)

	return retVal
}

; returns the winexist of the window even if its hidden
;  window - window to check based on WinTitle
;
; returns winexist
WinHidden(window) {
	resetDHW := A_DetectHiddenWindows

	DetectHiddenWindows(true)
	retVal := WinExist(window)
	DetectHiddenWindows(resetDHW)

	return retVal
}

; returns the parent of the specified window
;  window - window to check based on WinTitle
;
; returns parent window hwnd
WinGetParent(window) {
	hwnd := WinGetID(window)

	retVal := 0
	try {
		retVal := DllCall("GetAncestor", "Ptr", hwnd, "UInt", 3)
	}

	return retVal
}

; returns the min size of the specified window
;  window - window to check based on WinTitle
;
; returns an x, y array
WinGetMinSize(window) {
	waitTime := 1000

	hwnd := WinHidden(window)

	minMaxBuffer := Buffer(40, 0)
	SendMessage(0x24,, minMaxBuffer,, hwnd,,,, waitTime)

	return [NumGet(minMaxBuffer, 24, "Int"), NumGet(minMaxBuffer, 28, "Int")]
}

; returns the max size of the specified window
;  window - window to check based on WinTitle
;
; returns an x, y array
WinGetMaxSize(window) {
	waitTime := 1000

	hwnd := WinHidden(window)

	minMaxBuffer := Buffer(40, 0)
	SendMessage(0x24,, minMaxBuffer,, hwnd,,,, waitTime)

	return [NumGet(minMaxBuffer, 32, "Int"), NumGet(minMaxBuffer, 36, "Int")]
}

; returns if window is activatable (checks !DISABLED && !NOACTIVATE && !(POPUP && TOPMOST))
;  window - window to check based on WinTitle
;
; returns boolean activatable
WinActivatable(window) {
	style := WinGetStyle(window)
	exStyle := WinGetExStyle(window)

	return !(style & 0x08000000) && !(exStyle & 0x08000000)	&& !((style & 0x80000000) && (exStyle & 0x00000008))
}

; ; returns if window is on top
; ;  window - window to check based on WinTitle
; ;
; ; returns boolean topmost
; WinIsTop(window) {
; 	winList := WinGetList(window)
; 	if (winList.Length = 0) {
; 		return false
; 	}


; 	nextWNDW := DllCall("GetTopWindow", "Ptr", 0)
; 	while (1) {
; 			nextWNDW := DllCall("GetWindow", "Ptr", nextWNDW, "UInt", 2)

; 		if (DllCall("IsWindowVisible", "Ptr", nextWNDW)) {
; 			MsgBox(nextWNDW . " " . WinGetTitle(nextWNDW) . " " . WinGetProcessPath(nextWNDW) . " " . WinGetProcessName(nextWNDW))
; 			WinGetPos(&X, &Y, &W, &H, nextWNDW)
; 			MsgBox(X . " " . Y . " " . W . " " . H)
; 		}
; 	}

; 	; MsgBox(WinGetTitle(nextWNDW))
; 	; winNext := DllCall("GetWindow", "Ptr", winTop, "UInt", 2)
; 	; winNooo := DllCall("GetWindow", "Ptr", winNext, "UInt", 2)

; 	; nameArr := []
; 	; for win in winList {
; 	; 	nameArr.Push(WinGetTitle(win))
; 	; }

; 	; MsgBox(toString(nameArr))
; 	; MsgBox(winTop . " " . WinGetTitle(winTop))
; 	; MsgBox(winNext . " " . WinGetTitle(winNext))
; 	; MsgBox(winNooo . " " . WinGetTitle(winNooo))
; 	return inArray(nextWNDW, winList)
; }

; maximizes the window by posting a message to the window, the same message as the maximize button
;  window - window to maximize based on WinTitle
;
; returns result of postmessage
WinMaximizeMessage(window) {
	try {
		return PostMessage(0x0112, 0xF030,,, window)
	}
	catch {
		return false
	}
}

; minimizes the window by posting a message to the window, the same message as the minimize button
;  window - window to minimize based on WinTitle
;
; returns result of postmessage
WinMinimizeMessage(window) {
	try {
		return PostMessage(0x0112, 0xF020,,, window)
	}
	catch {
		return false
	}
}

; restores the window by posting a message to the window
;  window - window to restore based on WinTitle
;
; returns result of postmessage
WinRestoreMessage(window) {
	try {
		return PostMessage(0x0112, 0xF120,,, window)
	}
	catch {
		return false
	}
}

; activates a window using SetForegroundWindow
; https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-setforegroundwindow
;  window - window to restore based on WinTitle
;
; returns null
WinActivateForeground(window) {
	hwnd := WinExist(window)
	if (!hwnd) {
		return
	}

	if (WinGetMinMax(hwnd) = -1) {
		WinRestoreMessage(hwnd)
		Sleep(100)
	}

	maxCount := 5
	count := 0

	while (count < maxCount) {
		if (DllCall("SetForegroundWindow", "Ptr", hwnd) || !WinShown(hwnd)) {
			return
		}

		Sleep(40)
		count += 1
	}
	
	; return fail value
	return false
}

; closes all windows that match the window param
;  window - window to close based on WinTitle
;
; returns null
WinCloseAll(window) {
	resetDHW := A_DetectHiddenWindows
	DetectHiddenWindows(false)

	winList := WinGetList(window)
	loop winList.Length {
		if (WinExist(winList[A_Index])) {
			WinClose(winList[A_Index])

			if (A_Index < winList.Length) {
				Sleep(250)
			}
		} 
    }

	DetectHiddenWindows(resetDHW)
}

; returns the "Responding" state of the window
;  window - window to check based on WinTitle
;
; returns false if the window is "Not Responding"
WinResponsive(window) {
	id := 0
	if (IsInteger(window)) {
		id := window
	}
	else {
		id := WinGetID(window)
	}

	return !DllCall("IsHungAppWindow", "UInt", id)
}

; sets the current script's window title to the string in name
;  name - new window name for current script
;
; returns null
SetCurrentWinTitle(name) {
	resetDHW := A_DetectHiddenWindows

	DetectHiddenWindows(true)
	WinSetTitle(name, "ahk_pid " DllCall("GetCurrentProcessId"))
	DetectHiddenWindows(resetDHW)
}

; wrapper for control send to work in runFunction
;  key - same as ControlSend
;  window - same as ControlSend
;  time - time in ms to hold 
;  async - use timer instead of sleep for "up" press
;
; returns null
WindowSend(key, window, time := -1, async := false) {
	; send the key normally if window is active or doesnt exist
	if (WinActive(window) || !WinExist(window)) {
		SendSafe(key, time)
		return
	}

	; if there's a space, just control send
	if (InStr(key, A_Space)) {
		if (time = -1) {
			ControlSend(key,, window)
		}

		return
	}

	; if its a hold key, just control send 
	if (StrLower(SubStr(key, -4)) = " up}" || StrLower(SubStr(key, -6)) = " down}") {
		ControlSend(key,, window)
		return
	}

	if (time = -1) {
		time := 100
	}

	lastModiferIndex := 0
	loop parse key {
		if (A_LoopField = "^" || A_LoopField = "+" || A_LoopField = "!" || A_LoopField = "#") {
			lastModiferIndex := A_Index + 1
		}
		else {
			break
		}
	}

	newKey := key
	; parse key string so that "down" and "up" can be appended
	if (lastModiferIndex > 0) {
		newKey := SubStr(key, 1, (lastModiferIndex - 1))
		if (SubStr(key, lastModiferIndex, 1) != "{") {
			newKey := newKey . "{"
		}

		newKey := newKey . SubStr(key, lastModiferIndex) 
	}
	else if (SubStr(newKey, 1, 1) != "{") {
		newKey := "{" . newKey
	}

	if (SubStr(newKey, -1, 1) = "}") {
        newKey := SubStr(newKey, 1, StrLen(newKey) - 1)
    }

	ControlSend(newKey . " down}",, window)
	if (!async) {
		Sleep(time)
		ControlSend(newKey . " up}",, window)
	}
	else {
		SetTimer(AsyncRelease.Bind(newKey . " up}", window), Neg(time))
	}

	return

	AsyncRelease(releaseKey, window) {
		if (WinExist(window) && !WinActive(window)) {
			ControlSend(releaseKey,, window)
		}
		else {
			Send(releaseKey)
		}
		
		return
	}
}

; holds a keybinding for x ms
;  key - key to press/hold (must be single key, can't be combo)
;  time - time in ms to hold key
;  async - use timer instead of sleep for "up" press
;
; returns null
SendSafe(key, time := -1, async := false) {
	; if there's a space, just send
	if (InStr(key, A_Space)) {
		if (time = -1) {
			Send(key)
		}

		return
	}

	; if its a hold key, just send 
	if (StrLower(SubStr(key, -4)) = " up}" || StrLower(SubStr(key, -6)) = " down}") {
		Send(key)
		return
	}

	if (time = -1) {
		time := 100
	}

	lastModiferIndex := 0
	loop parse key {
		if (A_LoopField = "^" || A_LoopField = "+" || A_LoopField = "!" || A_LoopField = "#") {
			lastModiferIndex := A_Index + 1
		}
		else {
			break
		}
	}

	newKey := key
	; parse key string so that "down" and "up" can be appended
	if (lastModiferIndex > 0) {
		newKey := SubStr(key, 1, (lastModiferIndex - 1))
		if (SubStr(key, lastModiferIndex, 1) != "{") {
			newKey := newKey . "{"
		}

		newKey := newKey . SubStr(key, lastModiferIndex) 
	}
	else if (SubStr(newKey, 1, 1) != "{") {
		newKey := "{" . newKey
	}

	if (SubStr(newKey, -1, 1) = "}") {
        newKey := SubStr(newKey, 1, StrLen(newKey) - 1)
    }

	Send(newKey . " down}")
	if (!async) {
		Sleep(time)
		Send(newKey . " up}")
	}
	else {
		SetTimer(AsyncRelease.Bind(newKey . " up}"), Neg(time))
	}

	return

	AsyncRelease(releaseKey) {
		Send(releaseKey)
		return
	}
}

; moves the mouse to the position x & y percent across the current monitor
;  x - x percent for mouse pos
;  y - y percent for mouse pos
;  monitorNum - monitor for x & y percents
;
; returns null
MouseMovePercent(x, y, monitorNum) {
	MonitorGet(monitorNum, &ML, &MT, &MR, &MB)

    monitorX := ML
    monitorY := MT
    monitorH := Floor(Abs(MB - MT))
    monitorW := Floor(Abs(MR - ML))

	MouseMove(monitorX + (x * monitorW), monitorY + (y * monitorH))
}

; deep clones an object, supporting Maps & Arrays
; obj - obj to deep clone
;
; returns cloned object
ObjDeepClone(obj) {
	if (!IsObject(obj)) {
		return obj
	}

	retObj := ""
	if (Type(obj) = "Map") {
		retObj := Map()
		for key, value in obj {
			retObj[key] := ObjDeepClone(value)
		}
	}
	else if (Type(obj) = "Array") {
		retObj := []
		loop obj.Length {
			retObj.Push(ObjDeepClone(obj[A_Index]))
		}
	}
	else {
		retObj := {}
		for key, value in obj.OwnProps() {
			retObj.%key% := ObjDeepClone(value)
		}
	}

	return retObj
}

; loads the dll library for access in the script
;  library - string name of library to load
;
; returns the library
DllLoadLib(library) {
	return DllCall("LoadLibrary", "Str", library, "Ptr")
}

; frees the dll library for access in the script
;  library - string name of library to free
;
; returns success state
DllFreeLib(library) {
	if (library = 0) {
        return 0
    }

    return DllCall("FreeLibrary", "uint", library)
}

; forces a number to be negative
;  num - num to neg
;
; returns negative number
Neg(num) {
	return (num > 0) ? (-1 * num) : num
}

; sums all values in each list
;  lists - args lists
;
; returns sum of all values
Sum(lists*) {
	sumHelper(list) {
		helperVal := 0

		if (Type(list) = "Array") {
			for value in list {
				if (IsObject(value)) {
					helperVal += sumHelper(value)
				}
				else {
					helperVal += value
				}
			}
		}
		else if (Type(list) = "Map") {
			for key, value in list {
				if (IsObject(value)) {
					helperVal += sumHelper(value)
				}
				else {
					helperVal += value
				}
			}
		}

		return helperVal
	}

	retVal := 0
	for list in lists {
		retVal += sumHelper(list)
	}

	return retVal
}

; perfoms StrSplit on value but ignores substrings wrapped in quoteChar
;  value - string to split
;  deliminator - deliminator to split the string at [default: Space]
;  startChar - char or array of chars to combine strings (only combines like parts) [default: [", ']]
;  endChar - char or array of chars to combine strings (only combines like parts) [default: [", ']]
;  maxParts - maxParts to split the string into
;
; returns an array of the split substrings
StrSplitIgnoreQuotes(value, deliminator := " ", startChar := "", endChar := "", maxParts := 0) {
	startArr := []
	if (startChar = "") {
		startArr := ['"', "'"]
	}
	else {
		startArr := toArray(startChar)
	}
	
	endArr := []
	if (endArr = "") {
		endArr := ['"', "'"]
	}
	else {
		endArr := toArray(endArr)
	}

	quoteMap := Map()
	loop startArr {
		if (endArr.Length < A_Index) {
			quoteMap[startArr[A_Index] . "-" . startArr[A_Index]] := ""
		}
		else {
			quoteMap[startArr[A_Index] . "-" . endArr[A_Index]] := ""
		}
	}

	retArr := []
	maxString := ""

	stringArr := StrSplit(value, deliminator)
	index := 1
	for item in stringArr {
		if (maxParts != 0 && retArr.Length >= (maxParts - 1)) {
			maxString .= deliminator . item
			continue
		}

		currStart := ""
		currEnd := ""
		appendingChar := ""
		for key, value in quoteMap {
			currStart := StrSplit(key, "-")[1]
			currEnd := StrSplit(key, "-")[2]

			if (value != "") {
				appendingChar := key
				break
			}
			else if (SubStr(item, 1, 1) = currStart) {
				if (SubStr(item, -1, 1) = currEnd) {
					retArr.Push(item)
				}
				else {
					quoteMap[appendingChar] := item
				}

				break
			}
		}

		if (appendingChar != "") {
			if (SubStr(item, -1, 1) = currEnd || index = stringArr.Length) {				
				retArr.Push(LTrim(quoteMap[appendingChar], deliminator) . deliminator . item)
				quoteMap[appendingChar] := ""
			}
			else {
				quoteMap[appendingChar] .= deliminator . item
			}
		}
		else {
			retArr.Push(item)
		}

		index += 1
	}

	if (maxString != "") {
		retArr.Push(LTrim(maxString, deliminator))
	}

	return retArr
}

; converts the value to a string by appending it to empty string
;  value - value to convert to string
; 
; returns string containing value
toString(value, prefix := "") {
	retString := ""
	if (IsObject(value)) {
		if (Type(value) = "Array") {
			retString .= "["
			for item in value {
				if (IsObject(item)) {
					retString .= toString(item, prefix)
				}
				else {
					retString .= item . ", "
				}
			}
	
			retString := RegExReplace(retString, "U), $")
	
			return retString . "]"
		}
		else if (Type(value) = "Map") {
			for key, item in value {
				if (IsObject(item) && Type(item) != "Array") {
					retString .= prefix . key . " : {`n" . toString(item, (prefix . "  ")) . prefix . "}`n"
				}
				else {
					retString .= prefix . key . " : " . toString(item, prefix) . "`n"
				}
			}
	
			return retString
		}
		else {
			for key, item in value.OwnProps() {
				if (IsObject(item) && Type(item) != "Array") {
					retString .= prefix . key . " : {`n" . toString(item, (prefix . "  ")) . prefix . "}`n"
				}
				else {
					retString .= prefix . key . " : " . toString(item, prefix) . "`n"
				}
			}
	
			return retString
		}
	}
	else {
		return (prefix = "") ? Trim(retString . value, " `t`r`n") : RTrim(retString . value, " `t`r`n")
	}
}

; takes a string and attempts to convert it into either a num, bool, or array
;  value - value to convert
;  trimString - if retVal is a string, trimString unwanted chars (whitespace & ")
;
; returns either new value type, or string
fromString(value, trimString := false) {
	retVal := value
	whitespace := " `t`r`n"

	; try to convert the item into a float, if successful save as number
	try {
		retVal := Float(Trim(value, whitespace . "'" . '"'))
		return retVal
	}
	catch {
		; check if value is a string representing a bool, convert to bool
		if (StrLower(Trim(value, whitespace . "'" . '"')) = "true") {
			return true
		}
		else if (StrLower(Trim(value, whitespace . "'" . '"')) = "false") {
			return false
		}
		
		; check if value is an array (contains ","), and convert appropriately
		else if (SubStr(value, 1, 1) = "[" && SubStr(value, -1, 1) = "]") {
			trimmedVal := SubStr(value, 2, StrLen(value) - 2)

			commaPos := InStr(trimmedVal, ",")
			quote1Pos := InStr(trimmedVal, '"')
			quote2Pos := InStr(trimmedVal, "'")
			bracketOpenPos := InStr(trimmedVal, "[")
			bracketClosePos := InStr(trimmedVal, "]")

			inQuote1 := 0
			inQuote2 := 0
			inBracket := 0

			validComma := []
			while (commaPos) {
				checkPos := [commaPos]
				if (quote1Pos != 0) {
					if (inQuote1 && quote1Pos != inQuote1 && commaPos > quote1Pos) {
						inQuote1 := 0
					}
					else if (commaPos > quote1Pos) {
						inQuote1 := quote1Pos
					}

					checkPos.Push(quote1Pos)
				}
				if (quote2Pos != 0) {
					if (inQuote2 && quote2Pos != inQuote2 && commaPos > quote2Pos) {
						inQuote2 := 0
					}
					else if (commaPos > quote2Pos) {
						inQuote2 := quote2Pos
					}

					checkPos.Push(quote2Pos)
				}
				if (bracketClosePos != 0) {
					if (inBracket && bracketClosePos > inBracket && commaPos > bracketClosePos) {
						inBracket := 0
					}

					checkPos.Push(bracketClosePos)
				}
				if (bracketOpenPos != 0) {
					if (commaPos > bracketOpenPos) {
						inBracket := bracketOpenPos
					}

					checkPos.Push(bracketOpenPos)
				}

				nextPos := Min(checkPos*) + 1
				if (!inQuote1 && !inQuote2 && !inBracket) {
					validComma.Push(commaPos)
					nextPos := commaPos + 1
				}

				commaPos := InStr(trimmedVal, ",",, nextPos)
				quote1Pos := InStr(trimmedVal, '"',, nextPos)
				quote2Pos := InStr(trimmedVal, "'",, nextPos)
				bracketOpenPos := InStr(trimmedVal, "[",, nextPos)
				bracketClosePos := InStr(trimmedVal, "]",, nextPos)
			}

			remainingStr := trimmedVal
			prevIndex := 1
			arrayItems := []
			loop validComma.Length {
				splitIndex := validComma[A_Index] - (prevIndex - 1)
				arrayItems.Push(Trim(SubStr(remainingStr, 1, splitIndex), " `t`r`n,"))

				remainingStr := SubStr(remainingStr, splitIndex)
				prevIndex := validComma[A_Index]
			}

			arrayItems.Push(Trim(remainingStr, " `t`r`n,"))
			
			retVal := []
			for item in arrayItems {
				retVal.Push(fromString(item, trimString))
			}
		}

		if (trimString && Type(retVal) = "String") {
			retVal := Trim(retVal, whitespace)
			if ((SubStr(retVal, 1, 1) = '"' && SubStr(retVal, -1, 1) = '"') || (SubStr(retVal, 1, 1) = "'" && SubStr(retVal, -1, 1) = "'")) {
				retVal := SubStr(retVal, 2, StrLen(retVal) - 2)
			}
		}

		return retVal
	}
}

; either returns arr if its a string, or returns a deliminator separated string of arr elements
;  arr - array to join elements of
;  deliminitor - separating string between each element
;
; returns a string containing joined array
joinArray(arr, deliminator := " ") {
	if (!IsObject(arr)) {
		return arr
	}
	
	if (arr.Length = 1) {
		return arr[1]
	}
	
	retString := ""
	for value in arr {
		retString .= value . deliminator
	}

	return RTrim(retString, deliminator)
}

; checks if the given value(s) is in the array
;  value - single value or list to check if in array
;  arr - array to check if value is in
;  mode - either "or" or "and" to handle value lists
;  perfectMatch - only applies to strings -> if value needs to exactly match array
;
; returns boolean if value(s) are in arr
inArray(value, arr, mode := "and", perfectMatch := true) {
	if (Type(value) != "Array") {
		value := [value]
	}

	inCount := 0
	for item in value {
		for arrItem in arr {
			if ((perfectMatch) ? (item = arrItem) : (InStr(arrItem, item) || InStr(item, arrItem))) {
				inCount += 1

				if (mode != "and" || inCount = value.Length) {
					return true
				}
			}
		}
	}

	return false
}

; puts the object into a 1 length array if its not an array
;  obj - to check / put into array
;
; returns array with obj
toArray(obj) {
	return (Type(obj) = "Array") ? obj : [obj]
}

; checks if 2 arrays have the same contents
;  arr1 - first array
;  arr2 - second array
;  checkOrder - requires the arrays contents to be in the same order
;
; returns true if the arrays are equal
arrayEquals(arr1, arr2, checkOrder := true) {
	if (Type(arr1) != "Array" || Type(arr2) != "Array") {
		return false
	}

	if (arr1.Length != arr2.Length) {
		return false
	}

	if (checkOrder) {
		retVal := true
		loop arr1.Length {
			if (arr1[A_Index] != arr2[A_Index] && Type(arr1[A_Index]) != Type(arr2[A_Index])) {
				return false
			} else if (Type(arr1[A_Index]) = "Map") {
				retVal := retVal && mapEquals(arr1[A_Index], arr2[A_Index])
			} else if (Type(arr1[A_Index]) = "Array") {
				retVal := retVal && arrayEquals(arr1[A_Index], arr2[A_Index])
			} else {
				retVal := retVal && (arr1[A_Index] = arr2[A_Index])
			}

			if (!retVal) {
				return false
			}
		}

		return retVal
	}
	
	return inArray(arr1, arr2)
}

; checks if 2 maps have the same contents
;  map1 - first map
;  map2 - second map
;
; returns true if the maps are equal
mapEquals(map1, map2) {
    map1Keys := []
    map1Vals := []
    for key, value in map1 {
        map1Keys.Push(key)
        map1Vals.Push(value)
    }

    map2Keys := []
    map2Vals := []
    for key, value in map2 {
        map2Keys.Push(key)
        map2Vals.Push(value)
    }

    return (arrayEquals(map1Keys, map2Keys) && arrayEquals(map1Vals, map2Vals))
}

; cleans text to have special characters set to match identical in regex
;  text - text to clean for regex
;
; returns text with each character set to match identical in regex
regexClean(text) {
	retString := StrReplace(text, "\", "\\")
	retString := StrReplace(retString, ".", "\.")
	retString := StrReplace(retString, "*", "\*")
	retString := StrReplace(retString, "?", "\?")
	retString := StrReplace(retString, "+", "\+")
	retString := StrReplace(retString, "[", "\[")
	retString := StrReplace(retString, "{", "\{")
	retString := StrReplace(retString, "|", "\|")
	retString := StrReplace(retString, "(", "\(")
	retString := StrReplace(retString, ")", "\)")
	retString := StrReplace(retString, "^", "\^")
	retString := StrReplace(retString, "$", "\$")
	
	return retString
}

; cleans text to have normal special chars from regex chars
;  text - text to clean for string
;
; returns text with each character set to match identical in normal string
reverseRegexClean(text) {
	retString := StrReplace(text, "\\", "\")
	retString := StrReplace(retString, "\.", ".")
	retString := StrReplace(retString, "\*", "*")
	retString := StrReplace(retString, "\?", "?")
	retString := StrReplace(retString, "\+", "+")
	retString := StrReplace(retString, "\[", "[")
	retString := StrReplace(retString, "\{", "{")
	retString := StrReplace(retString, "\|", "|")
	retString := StrReplace(retString, "\(", "(")
	retString := StrReplace(retString, "\)", ")")
	retString := StrReplace(retString, "\^", "^")
	retString := StrReplace(retString, "\$", "$")
	
	return retString
}

; returns all regex matches like the global flag
;  haystack - similar to RegExMatch
;  pattern - similar to RegExMatch
;  &outputVar - similar to RegExMatch
;  startingPos - similar to RegExMatch
;
; returns the leftmost's result's position, or 0
globalRegExMatch(haystack, pattern, &outputVar := "", startingPos := 1) {
	index := 1
	outputVar := {
		__Item: [],
		Pos: [],
		Len: [],
		Name: [],
		Count: 0
	}

	leftMostPos := 0
	while (startingPos > 0 && startingPos < StrLen(haystack) && RegExMatch(haystack, pattern, &currOutput, startingPos)) {
		; i don't know why i have to do this
		if (currOutput.Count = 0) {
			outputVar.__Item.Push(currOutput[0])
			outputVar.Name.Push(currOutput.Name[0])
			outputVar.Len.Push(currOutput.Len[0])
			outputVar.Pos.Push(currOutput.Pos[0])

			outputVar.Count += 1
			index += 1 

			startingPos := currOutput.Pos[0] + currOutput.Len[0]

			if (leftMostPos = 0 || currOutput.Pos[0] < leftMostPos) {
				leftMostPos := currOutput.Pos[0]
			}
		}
		else {
			loop currOutput.Count {
				outputVar.__Item.Push(currOutput[A_Index])
				outputVar.Name.Push(currOutput.Name[A_Index])
				outputVar.Len.Push(currOutput.Len[A_Index])
				outputVar.Pos.Push(currOutput.Pos[A_Index])
	
				outputVar.Count += 1
				index += 1 
	
				startingPos := currOutput.Pos[A_Index] + currOutput.Len[A_Index]
	
				if (leftMostPos = 0 || currOutput.Pos[A_Index] < leftMostPos) {
					leftMostPos := currOutput.Pos[A_Index]
				}
			}
		}
	}

	return leftMostPos
}

; checks whether or not a given subString is within quotation marks in the mainString
;  mainString - string to check for the substring in
;  subString - string to check whether or not surrounded by quotation marks
;  startPos - starting position to check from for subString
;  allowPartial - if true -> returns the position if even if there's no closing quote
;
; returns the position of the first existing subString if it is within quotes
inQuotes(mainString, subString := "", startPos := 1, allowPartial := false) {
	quoteTypes := ['"', "'", "``"]

	if (subString = "") {
		for quote in quoteTypes {
			if (SubStr(mainString, 1, 1) = quote && SubStr(mainString, -1, 1) = quote) {
				return 1
			}
		}

		return 0
	}

	subPos := InStr(mainString, subString,, startPos)
	; substring doesn't exist
	if (!subPos) {
		return 0
	}

	for quote in quoteTypes {
		partialFound  := false
		startQuotePos := 0
		stringPtr := 1

		while (true) {
			if (stringPtr > StrLen(mainString)) {
				break
			}

			quotePos := InStr(mainString, quote,, stringPtr)
			; first quote is after subString or doesn't exist
			if (!quotePos || (startQuotePos = 0 && quotePos > subPos)) {
				break
			}

			; set start pos
			if (startQuotePos = 0) {
				startQuotePos := quotePos
				partialFound := true
			}
			; check end pos
			else {
				; substring is between quotes
				if (quotePos > subPos) {
					return subPos
				}
				else {
					partialFound  := false
					startQuotePos := 0
				}
			}

			stringPtr := quotePos + 1
		}

		if (allowPartial && partialFound) {
			return subPos
		}
	}

	return 0
}

; gets the string's eol setup (either `r, `n, or `r`n)
;  toRead - string to check eol
;
; returns either `r, `n, or `r`n based on string eol
getEOL(toRead) {
	if (InStr(toRead, "`r")) {
		if (InStr(toRead, "`r`n")) {
			return "`r`n"
		}
		else {
			return "`r"
		}
	}
	else {
		return "`n"
	}
}

; masks list with mask (only values in mask show up in retList)
;  list - list to mask
;  mask - list mask
;
; returns list masked with mask
maskList(list, mask) {
	retList := []

	for value in mask {
		for value2 in list {
			if (value = value2) {
				retList.Push(value)
			}
		}
	}

	return retList
}

; reads a file and returns the entire contents as a string
;  toRead - filepath to read
;
; returns string of file contents
fileToString(toRead) {
	fileObj := FileOpen(toRead, "r")
	retString := fileObj.Read()
	fileObj.Close()

	return retString
}

; checks if the toRead string is a file, if not then returns toRead
;  toRead - either filepath string or normal string
;
; returns either file contents of toRead or the original toRead string
fileOrString(toRead) {
    retString := ""

    if (FileExist(toRead)) {
		retString := fileToString(toRead)
	}
	else {
		retString := toRead
	}

    return retString
}

; adds backslash to end of directory string if it does not exist, and validates the directory
;  directory - string to validate backslash
; 
; returns directory string with backslash at the end
validateDir(directory) {
	retString := (RegExMatch(directory, "U).*\\$")) ? directory : directory . "\"

	if (DirExist(retString)) {
		return retString
	}
	else {
		ErrorMsg(retString . " Not Found")
		return retString
	}
}

; takes a directory starting with ..\ and replaces it with the full directory
;  directory - string to expand
;
; returns full directory
expandDir(directory) {
	if (SubStr(directory, 2, 1) = ":") {
		return directory
	}

	backDirs := 1

	while (SubStr(directory, 1, 3) = "..\") {
		backDirs += 1

		directory := RegExReplace(directory, "U)^\.\.\\", "")
	}

	currDirArr := StrSplit(A_ScriptFullPath, "\")

	retString := ""
	loop (currDirArr.Length - backDirs) {
		retString .= currDirArr[A_Index] . "\"
	}

	return retString . directory
}

; gets the raw data from a buffer & puts it into a another buffer
;  getPtr - ptr to the buffer to get the data
;  setPtr - ptr to the buffer to set the data
;  size - amount of data to set
;
; returns null
copyBufferData(getPtr, setPtr, size) {
	ptrOffset := 0
	remainingBytes := size

	while (remainingBytes >= 8) {
		NumPut("UInt64", NumGet(getPtr + ptrOffset, 0, "UInt64"), setPtr + ptrOffset, 0)
		
		remainingBytes -= 8
		ptrOffset += 8
	}

	if (remainingBytes >= 4) {
		NumPut("UInt", NumGet(getPtr + ptrOffset, 0, "UInt"), setPtr + ptrOffset, 0)
		
		remainingBytes -= 4
		ptrOffset += 4
	}

	if (remainingBytes >= 2) {
		NumPut("UShort", NumGet(getPtr + ptrOffset, 0, "UShort"), setPtr + ptrOffset, 0)
		
		remainingBytes -= 2
		ptrOffset += 2
	}

	if (remainingBytes >= 1) {
		NumPut("UChar", NumGet(getPtr + ptrOffset, 0, "UChar"), setPtr + ptrOffset, 0)
		
		remainingBytes -= 1
		ptrOffset += 1
	}
}

; runs a text as a function, seperating by spaces
;  args - string/array to run as function
;  params - additional params to push after string params
;
; return null
runFunction(args, params := "") {
	func := ""
	funcArr := []

	cleanArgs := ObjDeepClone(args)

	; prepend args to func from additional outside args
	if (Type(params) = "Array") {
		for item in params {
			funcArr.Push(item)
		}
	}
	else if (params != "") {
		funcArr.Push(params)
	}

	if (Type(cleanArgs) = "String") {
		textArr := StrSplit(cleanArgs, A_Space)
		func := textArr.RemoveAt(1)

		; set args for func from words in text
		stringType := ""
		tempString := ""
		for item in textArr {
			if (SubStr(item, 1, 1) = "%" && SubStr(item, -1, 1) = "%" && StrLen(item) > 1) {
				funcArr.Push(%Trim(item, "%")%)
				continue
			}
			
			; handle function param strings w/ spaces
			if (!stringType) {
				if (SubStr(item, 1, 1) = '"' && SubStr(item, -1, 1) = '"' && StrLen(item) > 1) {
					funcArr.Push(Trim(item, '"'))
				}
				else if (SubStr(item, 1, 1) = "'" && SubStr(item, -1, 1) = "'" && StrLen(item) > 1) {
					funcArr.Push(Trim(item, "'"))
				}
				else if (SubStr(item, 1, 1) = '"' && StrLen(item) > 1) {
					tempString .= LTrim(item, '"') . A_Space
					stringType := '"'
				}
				else if (SubStr(item, 1, 1) = "'" && StrLen(item) > 1) {
					tempString .= LTrim(item, "'") . A_Space
					stringType := "'"
				}
				else {
					funcArr.Push(item)
				}
			}
			else {
				if (SubStr(item, -1, 1) = '"' && stringType = '"') {
					funcArr.Push(RTrim(tempString . item, '"'))
					tempString := ""
					stringType := ""
				}
				else if (SubStr(item, -1, 1) = "'" && stringType = "'") {
					funcArr.Push(RTrim(tempString . item, "'"))
					tempString := ""
					stringType := ""
				}
				else {
					tempString .= item . A_Space
				}
			}
		}
	}
	else if (Type(cleanArgs) = "Array") {
		func := cleanArgs.RemoveAt(1)
		funcArr := cleanArgs
	}
	else {
		return
	}

	if (funcArr.Length > 0) {
		return %func%(funcArr*)
	}
	else {
		return %func%()
	}
}

; returns the string containing the dynamic includes if it exists
;  toRead - string/file to check for dynamic include section
;
; returns dynamic include string or ""
getDynamicIncludes(toRead) {
	mainString := fileOrString(toRead)
	eol := getEOL(mainString)

	retString := ""
	startReplace := false
	if (InStr(mainString, DYNASTART)) {
		loop parse mainString, eol {
			if (A_LoopField = "") {
				continue
			}

			if (InStr(A_LoopField, DYNASTART)) {
				retString .= A_LoopField . eol
				startReplace := true
			}
			else if (InStr(A_LoopField, DYNAEND)) {
				retString .= A_LoopField . eol
				startReplace := false

				break
			}
			else if (startReplace) {
				retString .= A_LoopField . eol
			}
		}
	}

	return retString
}

; gets size of image in pixels
;  path - image path
;
; returns [width, height]
getImageDimensions(path) {
	fullPath := expandDir(path)
	SplitPath(fullPath, &cleanName, &cleanPath)

	shellObj := ComObject("Shell.Application")
	pathObj  := shellObj.namespace(cleanPath)
	fileObj  := pathObj.parseName(cleanName)

	dims := StrSplit(StrLower(fileObj.extendedProperty("Dimensions")), "x", " ?" chr(8234) chr(8236), 2)
	return [Integer(Trim(dims[1])), Integer(Trim(dims[2]))]
}

; gets the cpu load as a float percentage
;
; returns the cpu load
getCpuLoad() {
    static prevKernelUser := 0
    static prevIdle := 0

    kernel := 0
    user := 0
    idle := 0

    DllCall("GetSystemTimes", "Int64P", &idle, "Int64P", &kernel, "Int64P", &user)

    retVal := 100 * (1 - ((idle - prevIdle) / ((kernel + user) - prevKernelUser)))

    prevKernelUser := kernel + user
    prevIdle := idle

	return retVal
}

; gets the ram load as a int percentage
;
; returns the ram load
getRamLoad() {
    status := Buffer(64)
	NumPut("UInt", status.Size, status)
    
	try {
		if !(DllCall("GlobalMemoryStatusEx", "ptr", status.Ptr)) {
			ErrorMsg("Failed to get memory status")
			return 0
		}

		return NumGet(status, 4, "UInt")
	}

    return 0
}

; gets the gpu usage if the user has a nvidia gpu
; this only works when called from main (has the library initialized)
; this only works for 1 gpu (gpu0=256)
;
; returns the gpu usage
getNvidiaLoad() {
    try {
        static mainGPUPtr := 0
        
        if (mainGPUPtr = 0) {            
            DllCall("nvml\nvmlDeviceGetHandleByIndex_v2", "UInt", 0, "Ptr*", &mainGPUPtr, "CDecl")
        }
        
        usageBuffer := Buffer(8, 0)        
		if (!DllCall("nvml\nvmlDeviceGetUtilizationRates", "Ptr", mainGPUPtr, "Ptr", usageBuffer, "CDecl") ) {
			return NumGet(usageBuffer, 0, "UInt")
		}   

        return 0
    }
    
	return 0
}

; hides the windows taskbar
; 
; returns null
hideTaskbar() {
    try WinHide("ahk_class Shell_TrayWnd")
    try WinHide("ahk_class Shell_SecondaryTrayWnd")
}

; shows the windows taskbar
; 
; returns null
showTaskbar() {
    try WinShow("ahk_class Shell_TrayWnd")
    try WinShow("ahk_class Shell_SecondaryTrayWnd")
}

; returns whether the windows taskbar exists
; 
; returns true if the taskbar exists
taskbarExists() {
    return WinShown("ahk_class Shell_TrayWnd") || WinShown("ahk_class Shell_SecondaryTrayWnd")
}

; gets the current state of the taskbar autohide
; 
; returns true if autohide is enabled
getAutoHideTaskbar() {
	data := Buffer(48, 0)

	return DllCall("Shell32\SHAppBarMessage", "UInt", 4, "Ptr", data, "Int") ? true : false
}

; enables/disables autohiding the taskbar
; NOT WORKING - https://learn.microsoft.com/en-us/answers/questions/1230347/hidden-taskbar-function-is-out-of-work-by-using-sh
;  enable - boolean whether or not to enable autohide
;
; return null
toggleAutoHideTaskbar(enabled) {
	restoreDHW := A_DetectHiddenWindows
	DetectHiddenWindows(true)
	taskbarID := WinExist("ahk_class Shell_TrayWnd")
	DetectHiddenWindows(restoreDHW)

	if (!taskbarID) {
		return
	}

	data := Buffer(48, 0)
	NumPut("UInt", 48, data, 0)
	NumPut("Ptr", taskbarID, data, 8)
	NumPut("UInt", (enabled) ? 1 : 2, data, 40)

	DllCall("Shell32\SHAppBarMessage", "UInt", 10, "Ptr", data)
}