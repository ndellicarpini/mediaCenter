; ----- GLOBAL VARIABLES -----
global MAINNAME := "MediaCenterMain"
global MAINLOOP := "MediaCenterLoop"

global DYNASTART := "; ----- DO NOT EDIT: DYNAMIC INCLUDE START -----"
global DYNAEND   := "; ----- DO NOT EDIT: DYNAMIC INCLUDE END   -----"

; ----- FUNCTIONS -----

; closes a window's process based on window
;  window - window whose process to close
;
; return ProcessClose
ProcessWinClose(window) {
	return ProcessClose(WinGetPID(WinHidden(window)))
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

; converts the value to a string by appending it to empty string
;  value - value to convert to string
; 
; returns string containing value
toString(value, prefix := "") {
	retString := ""

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
			if (Type(item) = "Map") {
				retString .= prefix . key . " : {`n" . toString(item, (prefix . "`t")) . prefix . "}`n"
			}
			else {
				retString .= prefix . key . " : " . toString(item, prefix) . "`n"
			}
		}

		return retString
	}
	else {
		return retString . value
	}
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

; adds a new member to an object called "keys" that contains a comma-deliminated string with all
; of the keys in the object (specifically for ComObject as it cannot enumerate through its keys)
;  obj - the map object to be given the member "keys"
;
; returns the obj with the new member
addKeyListString(obj) {
	tempString := ""
	newObj := Map()

	; if the obj is a map, just add the "keys" to the map
	if (Type(obj) = "Map") {
		newObj := obj

		for key, value in newObj {
			if (key != "keys") {
				tempString .= key . ","
			}

			; apply to all sub-objs in the object as well
			if (Type(value) = "Map" || Type(value) = "Array") {
				newObj[key] := addKeyListString(value)
			}
		}
	}

	; if the obj is not a map, convert the obj to a map and add the "keys" key
	else {
		loop obj.Length {
			tempString .= toString(A_Index) . ","
			newObj[toString(A_Index)] := obj[A_Index]
		} 
	}

	newObj["keys"] := RTrim(tempString, ",")
	return newObj
}

; sets the current script's window title to the string in name
;  name - new window name for current script
;
; returns null
setCurrentWinTitle(name) {
	resetDHW := A_DetectHiddenWindows

	DetectHiddenWindows(true)
	WinSetTitle(name, "ahk_pid" . DllCall("GetCurrentProcessId"))
	DetectHiddenWindows(resetDHW)
}

; takes a variable amount of exe maps (key=exe) and returns the process exe if its running
;  lists* - any amount of exe lists
;
; return either "" if the process is not running, or the name of the process
checkEXEList(lists*) {
    for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process") {
        for exeList in lists {
            if (exeList.Has(process.Name)) {
                return process.Name
            }
        }
    }

    return ""
}

; takes a variable of window maps (key=window) and returns true if any of the functions return
;  lists* - any amount of window lists
;
; return either "" if the process is not running, or the name of the process
checkWNDWList(lists*) {
	for functionList in lists {
		
		if (functionList.Has("keys")) {
			for key in StrSplit(functionList["keys"], ",") {
				if (WinShown(key)) {
					return key
				}
			}
		}
		else {
			for key, empty in functionList {
				if (WinShown(key)) {
					return key
				}
			}
		}
	}

	return ""
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