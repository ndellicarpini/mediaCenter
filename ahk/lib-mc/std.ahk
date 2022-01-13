; ----- GLOBAL VARIABLES -----
global MAINNAME := "MediaCenterMain"
global MAINLOOP := "MediaCenterLoop"

global DYNASTART := "; ----- DO NOT EDIT: DYNAMIC INCLUDE START -----"
global DYNAEND   := "; ----- DO NOT EDIT: DYNAMIC INCLUDE END   -----"

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
;  PID - pid of process to murder
;
; returns null
ProcessKill(PID) {
	Run 'taskkill /t /f /pid ' . PID,, 'Hide'
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
		return (prefix = "") ? Trim(retString . value, " `t`r`n") : RTrim(retString . value, " `t`r`n")
	}
}

; takes a string and attempts to convert it into either a num, bool, or array
;  value - value to convert
;  trim - if retVal is a string, trim unwanted chars (whitespace & ")
;
; returns either new value type, or string
fromString(value, trim := false) {
	retVal := value

	; try to convert the item into a float, if successful save as number
	try {
		retVal := Float(value)
		return retVal
	}
	catch {
		; check if value is a string representing a bool, convert to bool
		if (StrLower(value) = "true") {
			return true
		}
		else if (StrLower(value) = "false") {
			return false
		}
		
		; check if value is an array (contains ","), and convert appropriately
		else if (InStr(value, ",") && (SubStr(value, 1, 1) = "[" && SubStr(value, -1, 1) = "]")) {
			tempArr := StrSplit(Trim(value, " `r`n`t[]"), ",")

			retVal := []
			for item in tempArr {
				retVal.Push(fromString(item, trim))
			}
		}

		return (trim && Type(retVal) = "String") ? Trim(retVal, ' `t`r`n"') : retVal
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

				if (mode != "and" || inCount = arr.Length) {
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
		tempString := RegExReplace(stringsToCheck[1], regexClean(startChar[A_Index]),, startCount)
		RegExReplace(tempString, regexClean(endChar[A_Index]),, endCount)

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

; gets an asset's path based on the name of the asset & the current AssetDir
;  asset - asset name / path to get (path=subfolders in assets folder)
;
; returns asset's full path 
getAssetPath(asset) {
	if (!globalConfig["General"].Has("AssetDir") || globalConfig["General"]["AssetDir"] = "") {
		ErrorMsg("Cannot get AssetDir when it does not exist in in global.cfg")
		return
	}

	assetPath := globalConfig["General"]["AssetDir"] . asset

	if (!FileExist(assetPath)) {
		ErrorMsg("Requested asset [" . asset . "] does not exist")
		return
	}

    return assetPath
}

; adds a new member to an object called "keys" that contains a comma-deliminated string with all
; of the keys in the object (specifically for ComObject as it cannot enumerate through its keys)
;  obj - the map object to be given the member "keys"
;  addKeys - array of keys to append to keys string
;
; returns the obj with the new member
addKeyListString(obj, addKeys := "") {
	tempString := ""
	newObj := Map()

	; if obj is comobj, just update "keys"
	if (Type(obj) = "ComObject" && obj.Has("keys")) {
		for key in StrSplit(obj["keys"], ",") {
			if (obj.Has(key)) {
				tempString .= key . ","
			}
		}
	}

	; if the obj is a map, just add the "keys" to the map
	else if (Type(obj) = "Map") {
		newObj := obj

		for key, value in newObj {
			if (key != "keys") {
				tempString .= key . ","
			}

			; apply to all sub-objs in the object as well
			if (Type(value) = "Map" || Type(value) = "Array" || Type(value) = "ComObject") {
				newObj[key] := addKeyListString(value)
			}
		}
	}

	; if the obj is not a map, convert the obj to a map and add the "keys" key
	else if (Type(obj) = "Array") {
		loop obj.Length {
			tempString .= toString(A_Index) . ","
			newObj[toString(A_Index)] := obj[A_Index]
		} 
	}

	if (addKeys != "") {
		for key in toArray(addKeys) {
			tempString .= key . ","
		}
	}

	if (Type(obj) = "ComObject") {
		obj["keys"] := RTrim(tempString, ",")
		return
	}
	else {
		newObj["keys"] := RTrim(tempString, ",")
		return newObj
	}
}

; this helps reduce a memory leak for objects that are shared between threads
; no i will not elaborate
;  obj - object to clean
;
; returns cleaned object
cleanComMap(obj) {
	retMap := Map()
	retMap["keys"] := obj["keys"]
	
	for key in StrSplit(obj["keys"], ",") {
		try key := Integer(key)

		currObj := obj[key]

		if (IsObject(currObj)) {
			retMap[key] := ObjFromPtrAddRef(ObjPtrAddRef(currObj))
		}
		else {
			retMap[key] := currObj
		}
	}

	return retMap
}

; runs a text as a function, seperating by spaces
;  text - string to run as function
;  params - additional params to push after string params
;
; return null
runFunction(text, params := "") {
	textArr := StrSplit(text, A_Space)
	func := textArr.RemoveAt(1)
	
	funcArr := []

	; set args for func from words in text
	for item in textArr {
		if (SubStr(item, 1, 1) = "%" && SubStr(item, -1, 1) = "%") {
			funcArr.Push(%Trim(item, "%")%)
		}
		else {
			funcArr.Push(item)
		}
	}

	; append args to func from additional outside args
	if (Type(params) = "Array") {
		for item in params {
			funcArr.Push(item)
		}
	}
	else if (params != "") {
		funcArr.Push(params)
	}

	; this is kinda annoying, TODO - maybe figure out how to deconstruct array
	if (funcArr.Length > 0) {
		return %func%(funcArr)
	}
	else {
		return %func%()
	}
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