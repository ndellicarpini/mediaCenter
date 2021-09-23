; returns the winexist of the window only if the window is not hidden
;  window - window to check
;
; returns winexist
WinShown(window) {
	resetDHW := A_DetectHiddenWindows

	DetectHiddenWindows(false)
	retVal := WinExist(window)
	DetectHiddenWindows(resetDHW)

	return retVal
}

; returns true if media center running, false otherwise
;
; returns boolean
mediaCenterRunning() {
	resetDHW := A_DetectHiddenWindows

	DetectHiddenWindows(true)
	retVal := WinExist("MediaCenterMain")
	DetectHiddenWindows(resetDHW)

	return retVal ? true : false
}

; converts the value to a string by appending it to empty string
;  value - value to convert to string
; 
; returns string containing value
toString(value) {
	return "" . value
}

; reads a file and returns the entire contents as a string
;  toRead - filepath to read
;
; returns string of file contents
fileToString(toRead) {
	file := FileOpen(toRead, "r")
	retString := file.Read()
	file.Close()

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

; converts a list of pointers to a string with each pointer seperated by a period
;  ptrs* - variable amount of pointers
;
; returns string of pointers seperated by periods
ptrListToString(ptrs*) {
	retVal := ""

	for value in ptrs {
		retVal .= value . ","
	}

	return RTrim(retVal, ",")
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
			if (IsObject(value)) {
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