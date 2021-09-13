; returns the winexist of the window only if the window is not hidden
;  window - window to check
;
; returns winexist
WinShown(window) {
	DetectHiddenWindows(false)
	return WinExist(window)
}

; converts the value to a string by appending it to empty string
;  value - value to convert to string
; 
; returns string containing value
toString(value) {
	return "" . value
}

; converts a list of pointers to a string with each pointer seperated by a period
;  ptrs* - variable amount of pointers
;
; returns string of pointers seperated by periods
ptrListToString(ptrs*) {
	retVal := ""

	for value in ptrs {
		retVal .= value . "."
	}

	return RTrim(retVal, ".")
}

; checks if the toRead string is a file, if not then returns toRead
;  toRead - either filepath string or normal string
;
; returns either file contents of toRead or the original toRead string
fileOrString(toRead) {
    retString := ""

    if (FileExist(toRead)) {
		file := FileOpen(toRead, "r")
		retString := file.Read()
		file.Close()
	}
	else {
		retString := toRead
	}

    return retString
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
		for key, empty in functionList {
			if (WinShown(key)) {
				return key
			}
		}
	}

	return ""
}