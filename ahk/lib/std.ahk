; ----- GLOBAL VARIABLES -----
global MAINNAME := "MediaCenterMain"
global MAINLOOP := "MediaCenterLoop"

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
		PID := WinGetPID("ahk_exe " process)
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

; returns if window is activatable (checks !DISABLED && !TOOLWINDOW)
;  window - window to check based on WinTitle
;
; returns boolean activatable
WinActivatable(window) {
	style := WinGetStyle(window)
	exStyle := WinGetExStyle(window)

	return !(style & 0x00000080) && !(exStyle & 0x08000000)	
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

	resetDHW := A_DetectHiddenWindows
	DetectHiddenWindows(true)
	
	retVal := DllCall("SendMessageTimeout"
		, "UInt", id
		, "UInt", 0x0000
		, "Int", 0
		, "Int", 0
		, "UInt", 0x0008
		, "UInt", 100
		, "UInt*", 0
	)

	DetectHiddenWindows(resetDHW)
	return (retVal != 0 && A_LastError != 1460)
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

; holds a keybinding for x ms
;  key - key to press/hold (must be single key, can't be combo)
;  time - time in ms to hold key
;
; returns null
SendSafe(key, time := 100) {
	if (StrSplit(key, A_Space).Length > 2) {
		ErrorMsg("Can't SendSafe a multi key bind")
		return
	}

	firstChar := SubStr(key, 1, 1)
    if (firstChar != "{" && firstChar != "^"
		&& firstChar != "+" && firstChar != "!" && firstChar != "#") {
        
		key := "{" . key
    }

	if (SubStr(key, -1, 1) = "}") {
        key := SubStr(key, 1, StrLen(key) - 1)
    }

	Send(key . " down}")
	Sleep(time)
	Send(key . " up}")
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
	return DllCall("LoadLibrary", "Str", library)
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
	for item in stringArr{
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
		else if (Type(value) = "Config") {
			retString .= "`n" . prefix . "INDENT[" . toString(StrLen(value.indent)) . "]`n"
			retString .= RTrim(toString(value.items, prefix . "  "), " `t`r`n") . "`n`n"
			retString .= prefix . RTrim(toString(value.subConfigs, prefix . "  "), " `t`r`n") . "`n"
	
			return RTrim(retString, " `t`r`n") . "`n"
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

	; try to convert the item into a float, if successful save as number
	try {
		retVal := Float(Trim(value, A_Space))
		return retVal
	}
	catch {
		; check if value is a string representing a bool, convert to bool
		if (StrLower(Trim(value, A_Space)) = "true") {
			return true
		}
		else if (StrLower(Trim(value, A_Space)) = "false") {
			return false
		}
		
		; check if value is an array (contains ","), and convert appropriately
		else if (SubStr(value, 1, 1) = "[" && SubStr(value, -1, 1) = "]") {
			tempArr := StrSplit(Trim(value, " `r`n`t[]"), ",")

			retVal := []
			for item in tempArr {
				retVal.Push(fromString(item, trimString))
			}
		}

		return (trimString && Type(retVal) = "String") ? Trim(retVal, ' `t`r`n"') : retVal
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
			retVal := retVal && (arr1[A_Index] = arr2[A_Index])
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

; checks whether or not a given subString is within quotation marks / custom in the mainString
;  mainString - string to check for the substring in
;  subString - string to check whether or not surrounded by quotation marks
;  startChar - a list of starting chars to match with endChar (if no endChar, then match withh startChar)
;  endChar - a list of endChar that is matched 1-to-1 with startChar
;
; returns boolean based on if subString is within quotes
inQuotes(mainString, subString, startChar := "", endChar := "") {
	startChar := (startChar = "") ? ['"', "'"] : toArray(startChar)
	endChar   := (endChar = "")   ? ['"', "'"] : toArray(endChar)

	if (startChar.Length != endChar.Length) {
		ErrorMsg("inQuotes: startChar & endChar have different lengths")
	}

	stringsToCheck := StrSplit(mainString, subString,, 2)
	if (stringsToCheck.Length != 2) {
		return false
	}

	quoteCount := []
	loop startChar.Length {
		tempString := RegExReplace(stringsToCheck[1], regexClean(startChar[A_Index]),, &startCount)
		RegExReplace(tempString, regexClean(endChar[A_Index]),, &endCount)

		tempNum := startCount - endCount
		if (startChar[A_Index] = endChar[A_Index]) {
			tempNum := Mod(tempNum, 2)
		}
		
		quoteCount.Push(tempNum)
	}

	total := 0
	loop quoteCount.Length {
		total += quoteCount[A_Index]
	}

	return (total > 0) ? true : false
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
}

; shows the windows taskbar
; 
; returns null
showTaskbar() {
    try WinShow("ahk_class Shell_TrayWnd")
}

; returns whether the windows taskbar exists
; 
; returns true if the taskbar exists
taskbarExists() {
    return WinShown("ahk_class Shell_TrayWnd")
}