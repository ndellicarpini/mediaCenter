#Include std.ahk


class Config {
	; type of file
	type := ""
	; path to the original config file
	path := ""
	; original text of the config file
	original := ""
	; eol character used
	eol := ""
	; parsed data from the config
	data := Map()
	; original parsed data attached to the original text
	; object format
	;  value - value from data (could be subconfig)
	;  text - original text for this key/value pair
	originalData := Map()
	; maximum number of backups that 1 file can have
	maxBackups := 5

	; reads from a file/string and generates a Config object
	;  toRead - string/file to read
	;  type - type of the config file
	;       - ini -> standard config file using bracketed category names 
	;	    - json -> formatted like a json file {...}
	;       - xml -> formatted like an xml document with <x>...</x>
	;       - yaml -> formatted like an yaml document with indents
	;       - [TODO] toml -> why does this format even exist?
	__New(toRead, type := "ini") {
		this.type := type
		this.read(toRead)
	}

	read(toRead) {
		if (FileExist(toRead)) {
			this.path := toRead
			this.original := fileToString(toRead)
		}
		else {
			this.original := toRead
		}

		this.eol := getEOL(this.original)

		switch (StrLower(this.type)) {
			case "ini":
				this.originalData := this._readINI(this.original)
			case "json":
				this.originalData := this._readJSON(this.original)
			case "xml":
				this.originalData := this._readXML(this.original)
			case "yaml", "yml":
				this.originalData := this._readYAML(this.original)
			case "toml":
				this.originalData := this._readTOML(this.original)
		}

		this.data := this._cleanOriginalData(this.originalData)
		return this.data
	}

	write(path := "", backupOriginal := true) {
		readDataArr(item, originalItem) {
			if (Type(originalItem) != "Array" || item.Length != originalItem.Length) {
				return true
			}

			retArr := []
			loop item.Length {
				originalValue := this._cleanOriginalData(originalItem[A_Index])
				if (item[A_Index] != originalValue && Type(item[A_Index]) != Type(originalValue)) {
					retArr.Push(false)
				} else if (Type(item[A_Index]) = "Map") {
					retArr.Push(readDataMap(item[A_Index], originalValue))
				} else if (Type(item[A_Index]) = "Array") {
					retArr.Push(readDataArr(item[A_Index], originalValue))
				} else {
					retArr.Push((item[A_Index] != originalValue))
				}
			}

			return retArr
		}

		readDataMap(item, originalItem) {
			if (Type(originalItem) != "Map") {
				return true
			}

			retMap := Map()
			for key, value in item {
				if (!originalItem.Has(key)) {
					MsgBox("not have" . key)
					return true
				}

				originalValue := this._cleanOriginalData(originalItem[key])
				if (value != originalValue && Type(value) != Type(originalValue)) {
					retMap[key] := true
				}
				else if (Type(value) = "Map") {
					retMap[key] := readDataMap(value, originalValue)
				} 
				else if (Type(value) = "Array") {
					retMap[key] := readDataArr(value, originalValue)
				} 
				else {
					retMap[key] := (value != originalValue)
				}
			}

			return retMap
		}

		writeDataArr(text, diff, item, originalItem) {
			retText := text
			loop item.Length {
				if (diff[A_Index] = false) {
					continue
				}

				currText := originalItem[A_Index]["text"]
				if (!InStr(retText, currText, true)) {
					continue
				}

				newText := ""
				if (Type(item[A_Index]) = "Map" && Type(originalItem[A_Index]["value"]) = "Map") {
					newText := writeDataMap(currText, diff[A_Index], item[A_Index], originalItem[A_Index]["value"])
				} 
				else if (Type(item[A_Index]) = "Array" && Type(originalItem[A_Index]["value"]) = "Array") {
					newText := writeDataArr(currText, diff[A_Index], item[A_Index], originalItem[A_Index]["value"])
				} else {
					newText := StrReplace(currText, originalItem[A_Index]["value"], item[A_Index], true,, 1)
				}

				retText := StrReplace(retText, currText, newText, true,, 1)
			}

			return retText
		}

		writeDataMap(text, diff, item, originalItem) {
			retText := text
			for key, currDiff in diff {
				if (currDiff = false) {
					continue
				}

				currText := originalItem[key]["text"]
				if (!InStr(retText, currText, true)) {
					continue
				}

				newText := ""
				if (Type(item[key]) = "Map" && Type(originalItem[key]["value"]) = "Map") {
					newText := writeDataMap(currText, currDiff, item[key], originalItem[key]["value"])
				} 
				else if (Type(item[key]) = "Array" && Type(originalItem[key]["value"]) = "Array") {
					newText := writeDataArr(currText, currDiff, item[key], originalItem[key]["value"])
				} else {
					newItem := item[key]
					if (InStr(originalItem[key]["value"], "true") && newItem = 0) {
						if (InStr(originalItem[key]["value"], "true", true)) {
							newItem := "false"
						}
						else if (InStr(originalItem[key]["value"], "True", true)) {
							newItem := "False"
						}
						else if (InStr(originalItem[key]["value"], "TRUE", true)) {
							newItem := "FALSE"
						}
					}
					else if (InStr(originalItem[key]["value"], "false") && newItem = 1) {
						if (InStr(originalItem[key]["value"], "false", true)) {
							newItem := "true"
						}
						else if (InStr(originalItem[key]["value"], "False", true)) {
							newItem := "True"
						}
						else if (InStr(originalItem[key]["value"], "FALSE", true)) {
							newItem := "TRUE"
						}
					}

					newText := StrReplace(currText, originalItem[key]["value"], toString(newItem), true,, 1)
				}

				retText := StrReplace(retText, currText, newText, true,, 1)
			}

			return retText
		}

		; TODO - figure out how to handle type changes or array length changes
		diffObj := (Type(this.data) = "Array" ? readDataArr : readDataMap)(this.data, this.originalData)
		newText := (Type(this.data) = "Array" ? writeDataArr : writeDataMap)(this.original, diffObj, this.data, this.originalData)

		writePath := (path != "") ? path : this.path
		if (writePath = "") {
			ErrorMsg("Can't write config file without path")
		}

		encoding := ""
		if (FileExist(writePath)) {
			originalFile := FileOpen(writePath, "r")
			encoding := originalFile.Encoding
			originalFile.Close()

			if (backupOriginal) {
				SplitPath(writePath,,, &ext)
				backupPath := SubStr(writePath, 1, StrLen(writePath) - (StrLen(ext) + 1))
				FileCopy(writePath, backupPath . "." . FormatTime(, "MM-dd-yyyyTHH-mm-ss") . "-backup." . ext)
				
				backupFiles := []
				loop files backupPath . "*-backup." . ext {
					timeStr := FileGetTime(A_LoopFileFullPath, "C")
					fakeTime := (
						((Integer(SubStr(timeStr, 1, 4)) - 1970) * 31557600)
						+ (((Integer(SubStr(timeStr, 5, 2)) * 32) + Integer(SubStr(timeStr, 7, 2))) * 86400)
						+ (Integer(SubStr(timeStr, 9, 2)) * 3600)
						+ (Integer(SubStr(timeStr, 11, 2)) * 60)
					)

					backupFiles.Push(Map(
						"time", fakeTime,
						"path", A_LoopFileFullPath
					))
				}

				numDeleted := 0
				numToDelete := backupFiles.Length - this.maxBackups
				while (numDeleted < numToDelete) {
					minTime := (3025 - 1970) * 31557600
					minPath := ""

					index := 1
					minIndex := 0
					for file in backupFiles {
						if (file["time"] < minTime) {
							minTime := file["time"]
							minPath := file["path"]
							minIndex := index
						}

						index += 1
					}

					if (!minPath || minIndex < 1) {
						break
					}

					FileDelete(minPath)
					backupFiles.RemoveAt(minIndex)
					numDeleted += 1
				}
			}
		}
		
		writeFile := FileOpen(writePath, "w")
		; this works better than setting the encoding when opening?
		if (encoding) {
			writeFile.Encoding := encoding
		}

		writeFile.Write(newText)
		writeFile.Close()

		this.read(writePath)
	}

	_readINI(text) {
		whitespace := " `t" . this.eol

		currInQuote := ""
		currCategory := ""
		prevKey := ""

		retData := Map()
		loop parse text, this.eol {
			cleanLine := Trim(A_LoopField, whitespace)
			
			; if in multi-line string, just continue to read
			if (currInQuote != "") {
				if (currCategory != "") {
					retData[currCategory]["value"][prevKey]["value"] .= cleanLine . this.eol
					retData[currCategory]["value"][prevKey]["text"] .= A_LoopField . this.eol
					retData[currCategory]["text"] .= A_LoopField . this.eol
				}
				else {
					retData[prevKey]["value"] .= cleanLine . this.eol
					retData[prevKey]["text"] .= A_LoopField . this.eol
				}

				; check if the closing quotes exist
				if (globalRegExMatch(cleanLine, currInQuote, &quoteResult) && Mod(quoteResult.Count, 2) != 0) {
					currValue := (currCategory != "") 
						? retData[currCategory]["value"][prevKey]["value"] 
						: retData[prevKey]["value"]
						
					; remove comments from end of line
					if (globalRegExMatch(currValue, "U)\s(#|;|\/\/)", &matchResult)) {
						loop matchResult.Count {
							if (!inQuotes(currValue, matchResult[A_Index], matchResult.Pos[A_Index])) {
								currValue := SubStr(currValue, 1, matchResult.Pos[A_Index] - 1)
								break
							}
						}
					}

					if (currCategory != "") {
						retData[currCategory]["value"][prevKey]["value"] := Trim(currValue, whitespace)
					}
					else {
						retData[prevKey]["value"] := Trim(currValue, whitespace)
					}

					currInQuote := ""
				}
				
				continue
			}

			; skip empty lines / comment lines
			if (cleanLine = "" || RegExMatch(cleanLine, "U)^(#|;|\/\/)")) {
				continue
			}

			; remove comments from end of line
			if (globalRegExMatch(cleanLine, "U)\s(#|;|\/\/)", &matchResult)) {
				loop matchResult.Count {
					if (!inQuotes(cleanLine, matchResult[A_Index], matchResult.Pos[A_Index], true)) {
						cleanLine := Trim(SubStr(cleanLine, 1, matchResult.Pos[A_Index] - 1), whitespace)
						break
					}
				}
			}

			; check for category header
			if (SubStr(cleanLine, 1, 1) = "[" && SubStr(cleanLine, -1, 1) = "]") {
				currCategory := SubStr(cleanLine, 2, StrLen(cleanLine) - 2)
				if (inQuotes(currCategory)) {
					currCategory := SubStr(currCategory, 2, StrLen(cleanLine) - 2)
				}

				prevKey := ""
				retData[currCategory] := Map("value", Map(), "text", A_LoopField . this.eol)

				continue
			}
			
			splitPos := 0
			; check if deliminator exists in the line
			if (globalRegExMatch(cleanLine, "=", &matchResult)) {
				loop matchResult.Count {
					if (!inQuotes(cleanLine, matchResult[A_Index], matchResult.Pos[A_Index]) && (splitPos = 0 || matchResult.Pos[A_Index] < splitPos)) {
						splitPos := matchResult.Pos[A_Index]
					}
				}
			}
			
			; if deliminator exists -> add new key
			if (splitPos > 0) {
				currKey := Trim(SubStr(cleanLine, 1, splitPos - 1), whitespace)
				if (inQuotes(currKey)) {
					currKey := SubStr(currKey, 2, StrLen(currKey) - 2)
				}

				currValue := Trim(SubStr(cleanLine, splitPos + 1), whitespace)
				
				if (currCategory != "") {
					retData[currCategory]["value"][currKey] := Map("value", currValue, "text", A_LoopField . this.eol)
					retData[currCategory]["text"] .= A_LoopField . this.eol
				}
				else {
					retData[currKey] := Map("value", currValue, "text", A_LoopField . this.eol)
				}

				; check if any incomplete quotes exist in the string (assumed will be closed on another line) 
				if (globalRegExMatch(currValue, '"', &quoteResult) && Mod(quoteResult.Count, 2) != 0) {
					currInQuote := '"'
				}
				else if (globalRegExMatch(currValue, "'", &quoteResult) && Mod(quoteResult.Count, 2) != 0) {
					currInQuote := "'"
				}
				else if (globalRegExMatch(currValue, "``", &quoteResult) && Mod(quoteResult.Count, 2) != 0) {
					currInQuote := "``"
				}

				prevKey := currKey
			}
			; append contents to last key
			else if (prevKey != "") {
				if (currCategory != "") {
					retData[currCategory]["value"][prevKey]["value"] .= cleanLine
					retData[currCategory]["value"][prevKey]["text"] .= A_LoopField . this.eol
					retData[currCategory]["text"] .= A_LoopField . this.eol
				}
				else {
					retData[prevKey]["value"] .= cleanLine
					retData[prevKey]["text"] .= A_LoopField . this.eol
				}
			}
		}

		return retData
	}

	_readJSON(text) {
		whitespace := " `t" . this.eol

		if (RegExMatch(text, "^\s*\{") && RegExMatch(text, "\},*\s*$")) {
			if (RegExMatch(text, "^\s*\{", &matchResult)) {
				text := SubStr(text, matchResult.Pos + matchResult.Len)
			}
			if (RegExMatch(text, "\},*\s*$", &matchResult)) {
				text := SubStr(text, 1, matchResult.Pos - 1)
			}
	
			textLength := StrLen(text)
	
			objectPosArr := []
			arrayPosArr  := []
			quotePosArr  := this._getQuotePositions(text, [['"', '"']])
	
			stringPtr := 1
			; loop through text to find all sub items (arrays & objects)
			while (textLength > stringPtr) {
				objectOpen := InStr(text, "{",, stringPtr)
				objectClose := InStr(text, "}",, stringPtr)
				arrayOpen := InStr(text, "[",, stringPtr)
				arrayClose := InStr(text, "]",, stringPtr)
	
				if (!objectOpen && !objectClose && !arrayOpen && !arrayClose) {
					break
				}
	
				objectOpenValid  := true
				objectCloseValid := true
				arrayOpenValid   := true
				arrayCloseValid  := true
				; check that none of the found deliminators are in a string
				for quoteGroup in quotePosArr {
					for quoteEnds in quoteGroup {
						if (objectOpenValid && quoteEnds[1] < objectOpen && quoteEnds[2] > objectOpen) {
							objectOpenValid := false
						}
						if (objectCloseValid && quoteEnds[1] < objectClose && quoteEnds[2] > objectClose) {
							objectCloseValid := false
						}
						if (arrayOpenValid && quoteEnds[1] < arrayOpen && quoteEnds[2] > arrayOpen) {
							arrayOpenValid := false
						}
						if (arrayCloseValid && quoteEnds[1] < arrayClose && quoteEnds[2] > arrayClose) {
							arrayCloseValid := false
						}
					}
				}
	
				nextPos := 0
				minValidValue := 0
				; find the deliminator with the lowest position
				if (objectOpen > 0) {
					if (objectOpenValid) {
						minValidValue := objectOpen
					}
	
					nextPos := objectOpen
				}
				if (objectClose > 0) {
					if (objectCloseValid && (minValidValue = 0 || objectClose < minValidValue)) {
						minValidValue := objectClose
					}
					if (nextPos = 0 || nextPos > objectClose) {
						nextPos := objectClose
					}
				}
				if (arrayOpen > 0) {
					if (arrayOpenValid && (minValidValue = 0 || arrayOpen < minValidValue)) {
						minValidValue := arrayOpen
					}
					if (nextPos = 0 || nextPos > arrayOpen) {
						nextPos := arrayOpen
					}
				}
				if (arrayClose > 0) {
					if (arrayCloseValid && (minValidValue = 0 || arrayClose < minValidValue)) {
						minValidValue := arrayClose
					}
					if (nextPos = 0 || nextPos > arrayClose) {
						nextPos := arrayClose
					}
				}
	
				; no valid deliminator was found
				if (nextPos = 0) {
					break
				}
	
				if (minValidValue > 0) {
					; add a new object pos to the array if it doesn't already exist
					if (minValidValue = objectOpen) {
						skip := false
						loop objectPosArr.Length {
							if (objectPosArr[objectPosArr.Length - (A_Index - 1)][1] = objectOpen) {
								skip := true
								break
							}
						}
	
						; only add to position array if doesn't already exist
						if (!skip) {
							objectPosArr.Push([objectOpen, 0])
						}
					}
					; close the last open object
					else if (minValidValue = objectClose) {
						skip := false
						loop objectPosArr.Length {
							if (objectPosArr[objectPosArr.Length - (A_Index - 1)][2] = objectClose) {
								skip := true
								break
							}
						}
	
						; only add to position array if doesn't already exist
						if (!skip) {
							loop objectPosArr.Length {
								if (objectPosArr[objectPosArr.Length - (A_Index - 1)][1] < objectClose
									&& objectPosArr[objectPosArr.Length - (A_Index - 1)][2] = 0) {
									
									objectPosArr[objectPosArr.Length - (A_Index - 1)][2] := objectClose
									break
								}
							}						
						}
					}
					; add a new array pos to the array if it doesn't already exist
					else if (minValidValue = arrayOpen) {
						skip := false
						loop arrayPosArr.Length {
							if (arrayPosArr[arrayPosArr.Length - (A_Index - 1)][1] = arrayOpen) {
								skip := true
								break
							}
						}
	
						; only add to position array if doesn't already exist
						if (!skip) {
							arrayPosArr.Push([arrayOpen, 0])
						}
					}
					; close the last open array
					else if (minValidValue = arrayClose) {
						skip := false
						loop arrayPosArr.Length {
							if (arrayPosArr[arrayPosArr.Length - (A_Index - 1)][2] = arrayClose) {
								skip := true
								break
							}
						}
	
						; only add to position array if doesn't already exist
						if (!skip) {
							loop arrayPosArr.Length {
								if (arrayPosArr[arrayPosArr.Length - (A_Index - 1)][1] < arrayClose 
									&& arrayPosArr[arrayPosArr.Length - (A_Index - 1)][2] = 0) {
									
									arrayPosArr[arrayPosArr.Length - (A_Index - 1)][2] := arrayClose
									break
								}
							}
						}
					}
				}
	
				stringPtr := nextPos + 1
			}
	
			jsonElements := [1]
			stringPtr := 1
			; loop through text and find all outer level commas
			while (textLength > stringPtr) {
				commaPos := InStr(text, ",",, stringPtr)
				if (!commaPos) {
					jsonElements.Push(textLength)
					break
				}
	
				validComma := true
				; check that comma is not in string
				for group in quotePosArr {
					for pos in group {
						if (pos[1] < commaPos && pos[2] > commaPos) {
							validComma := false
							break
						}
					}
	
					if (!validComma) {
						break
					}
				}
	
				if (validComma) {
					; check that comma is not in object
					for pos in objectPosArr {
						if (pos[1] < commaPos && pos[2] > commaPos) {
							validComma := false
							break
						}
					}
				}
				if (validComma) {
					; check that comma is not in array
					for pos in arrayPosArr {
						if (pos[1] < commaPos && pos[2] > commaPos) {
							validComma := false
							break
						}
					}
				}
				
				; add new commas pos to element pos array
				if (validComma) {
					jsonElements.Push(commaPos)
				}
	
				stringPtr := commaPos + 1
			}
	
			retData := Map()
			; loop through all json element breakpoints
			loop jsonElements.Length - 1 {
				element := SubStr(text, jsonElements[A_Index], (jsonElements[A_Index + 1] + 1) - jsonElements[A_Index])
	
				cleanElement := Trim(element, whitespace . ",")
				if (cleanElement = "") {
					continue
				}
	
				stringPtr := 1
				; loop through current element and find first ":" not in string
				while(stringPtr <= StrLen(cleanElement)) {
					colonPos := InStr(cleanElement, ":",, stringPtr)
					if (!colonPos) {
						break
					}
	
					; valid ":" found -> parse key / value
					if (!inQuotes(cleanElement, ":", stringPtr)) {
						currKey := Trim(StrReplace(SubStr(cleanElement, 1, colonPos - 1), "\\", "\"), whitespace . '"')
						currValue := Trim(SubStr(cleanElement, colonPos + 1), whitespace)
	
						if ((SubStr(currValue, 1, 1) = "{" && SubStr(currValue, -1, 1) = "}") 
							|| (SubStr(currValue, 1, 1) = "[" && SubStr(currValue, -1, 1) = "]")) {
							currValue := this._readJSON(currValue)
						}
						else {
							currValue := StrReplace(Trim(currValue, '"'), "\\", "\")
						}
	
						retData[currKey] := Map("value", currValue, "text", element)
						break
					}
	
					stringPtr := colonPos + 1
				}
			}
	
			return retData
		}
		else if (RegExMatch(text, "^\s*\[") && RegExMatch(text, "\],*\s*$")) {
			if (RegExMatch(text, "^\s*\[", &matchResult)) {
				text := SubStr(text, matchResult.Pos + matchResult.Len)
			}
			if (RegExMatch(text, "\],*\s*$", &matchResult)) {
				text := SubStr(text, 1, matchResult.Pos - 1)
			}
	
			textLength := StrLen(text)
	
			objectPosArr := []
			arrayPosArr  := []
			quotePosArr  := this._getQuotePositions(text, [['"', '"']])
	
			stringPtr := 1
			; loop through text to find all sub items (arrays & objects)
			while (textLength > stringPtr) {
				objectOpen := InStr(text, "{",, stringPtr)
				objectClose := InStr(text, "}",, stringPtr)
				arrayOpen := InStr(text, "[",, stringPtr)
				arrayClose := InStr(text, "]",, stringPtr)
	
				if (!objectOpen && !objectClose && !arrayOpen && !arrayClose) {
					break
				}
	
				objectOpenValid  := true
				objectCloseValid := true
				arrayOpenValid   := true
				arrayCloseValid  := true
				; check that none of the found deliminators are in a string
				for quoteGroup in quotePosArr {
					for quoteEnds in quoteGroup {
						if (objectOpenValid && quoteEnds[1] < objectOpen && quoteEnds[2] > objectOpen) {
							objectOpenValid := false
						}
						if (objectCloseValid && quoteEnds[1] < objectClose && quoteEnds[2] > objectClose) {
							objectCloseValid := false
						}
						if (arrayOpenValid && quoteEnds[1] < arrayOpen && quoteEnds[2] > arrayOpen) {
							arrayOpenValid := false
						}
						if (arrayCloseValid && quoteEnds[1] < arrayClose && quoteEnds[2] > arrayClose) {
							arrayCloseValid := false
						}
					}
				}
	
				nextPos := 0
				minValidValue := 0
				; find the deliminator with the lowest position
				if (objectOpen > 0) {
					if (objectOpenValid) {
						minValidValue := objectOpen
					}
	
					nextPos := objectOpen
				}
				if (objectClose > 0) {
					if (objectCloseValid && (minValidValue = 0 || objectClose < minValidValue)) {
						minValidValue := objectClose
					}
					if (nextPos = 0 || nextPos > objectClose) {
						nextPos := objectClose
					}
				}
				if (arrayOpen > 0) {
					if (arrayOpenValid && (minValidValue = 0 || arrayOpen < minValidValue)) {
						minValidValue := arrayOpen
					}
					if (nextPos = 0 || nextPos > arrayOpen) {
						nextPos := arrayOpen
					}
				}
				if (arrayClose > 0) {
					if (arrayCloseValid && (minValidValue = 0 || arrayClose < minValidValue)) {
						minValidValue := arrayClose
					}
					if (nextPos = 0 || nextPos > arrayClose) {
						nextPos := arrayClose
					}
				}
	
				; no valid deliminator was found
				if (nextPos = 0) {
					break
				}
	
				if (minValidValue > 0) {
					; add a new object pos to the array if it doesn't already exist
					if (minValidValue = objectOpen) {
						skip := false
						loop objectPosArr.Length {
							if (objectPosArr[objectPosArr.Length - (A_Index - 1)][1] = objectOpen) {
								skip := true
								break
							}
						}
	
						; only add to position array if doesn't already exist
						if (!skip) {
							objectPosArr.Push([objectOpen, 0])
						}
					}
					; close the last open object
					else if (minValidValue = objectClose) {
						skip := false
						loop objectPosArr.Length {
							if (objectPosArr[objectPosArr.Length - (A_Index - 1)][2] = objectClose) {
								skip := true
								break
							}
						}
	
						; only add to position array if doesn't already exist
						if (!skip) {
							loop objectPosArr.Length {
								if (objectPosArr[objectPosArr.Length - (A_Index - 1)][1] < objectClose
									&& objectPosArr[objectPosArr.Length - (A_Index - 1)][2] = 0) {
									
									objectPosArr[objectPosArr.Length - (A_Index - 1)][2] := objectClose
									break
								}
							}						
						}
					}
					; add a new array pos to the array if it doesn't already exist
					else if (minValidValue = arrayOpen) {
						skip := false
						loop arrayPosArr.Length {
							if (arrayPosArr[arrayPosArr.Length - (A_Index - 1)][1] = arrayOpen) {
								skip := true
								break
							}
						}
	
						; only add to position array if doesn't already exist
						if (!skip) {
							arrayPosArr.Push([arrayOpen, 0])
						}
					}
					; close the last open array
					else if (minValidValue = arrayClose) {
						skip := false
						loop arrayPosArr.Length {
							if (arrayPosArr[arrayPosArr.Length - (A_Index - 1)][2] = arrayClose) {
								skip := true
								break
							}
						}
	
						; only add to position array if doesn't already exist
						if (!skip) {
							loop arrayPosArr.Length {
								if (arrayPosArr[arrayPosArr.Length - (A_Index - 1)][1] < arrayClose 
									&& arrayPosArr[arrayPosArr.Length - (A_Index - 1)][2] = 0) {
									
									arrayPosArr[arrayPosArr.Length - (A_Index - 1)][2] := arrayClose
									break
								}
							}
						}
					}
				}
	
				stringPtr := nextPos + 1
			}
	
			jsonElements := [1]
			stringPtr := 1
			; loop through text and find all outer level commas
			while (textLength > stringPtr) {
				commaPos := InStr(text, ",",, stringPtr)
				if (!commaPos) {
					jsonElements.Push(textLength)
					break
				}
	
				validComma := true
				; check that comma is not in string
				for group in quotePosArr {
					for pos in group {
						if (pos[1] < commaPos && pos[2] > commaPos) {
							validComma := false
							break
						}
					}
	
					if (!validComma) {
						break
					}
				}
	
				if (validComma) {
					; check that comma is not in object
					for pos in objectPosArr {
						if (pos[1] < commaPos && pos[2] > commaPos) {
							validComma := false
							break
						}
					}
				}
				if (validComma) {
					; check that comma is not in array
					for pos in arrayPosArr {
						if (pos[1] < commaPos && pos[2] > commaPos) {
							validComma := false
							break
						}
					}
				}
				
				; add new commas pos to element pos array
				if (validComma) {
					jsonElements.Push(commaPos)
				}
	
				stringPtr := commaPos + 1
			}

			retData := []
			; loop through all json element breakpoints
			loop jsonElements.Length - 1 {
				element := SubStr(text, jsonElements[A_Index], (jsonElements[A_Index + 1] + 1) - jsonElements[A_Index])
	
				cleanElement := Trim(element, whitespace . ",")
				if ((SubStr(cleanElement, 1, 1) = "{" && SubStr(cleanElement, -1, 1) = "}") 
					|| (SubStr(cleanElement, 1, 1) = "[" && SubStr(cleanElement, -1, 1) = "]")) {

					retData.Push(Map("value", this._readJSON(cleanElement), "text", element))
				}
				else {
					retData.Push(Map("value", StrReplace(Trim(cleanElement, '"'), "\\", "\"), "text", element))
				}
			}

			return retData
		}
	}

	_readXML(text) {
		parseAttribute(attribText) {
			keyValueArr := StrSplit(attribText, "=",, 2)
			attribKey := Trim(keyValueArr[1], this.eol . " `t")
			attribValue := Trim(keyValueArr[2], this.eol . " `t")

			if ((SubStr(attribValue, 1, 1) = '"' && SubStr(attribValue, -1) = '"')
				|| (SubStr(attribValue, 1, 1) = "'" && SubStr(attribValue, -1) = '"')) {

				attribValue := SubStr(attribValue, 2, StrLen(attribValue) - 2)
			}

			return Map(
				"key", attribKey,
				"value", attribValue
			)
		}

		textLength := StrLen(text)

		tags := []

		stringPtr := 1
		while (stringPtr && stringPtr < textLength) {
			openTagPtr := stringPtr
			openTagPos := InStr(text, "<",, openTagPtr)
			while (openTagPos && openTagPos < textLength) {
				if (!inQuotes(text, "<", openTagPtr)) {
					break
				}

				openTagPtr := openTagPos + 1
				openTagPos := InStr(text, "<",, openTagPtr)
			}
		
			closeTagPtr := stringPtr
			closeTagPos := InStr(text, ">",, closeTagPtr)
			while (closeTagPos && closeTagPos < textLength) {
				if (!inQuotes(text, ">", closeTagPtr)) {
					break
				}

				closeTagPtr := closeTagPos + 1
				closeTagPos := InStr(text, ">",, closeTagPtr)
			}

			if (!openTagPos || !closeTagPos) {
				break
			}
			if (openTagPos > closeTagPos) {
				ErrorMsg("XML Parsing Error: beans (" . closeTagPos . ") over the frank (" . openTagPos . ")")
				break
			}

			tags.Push([openTagPos, closeTagPos])
			stringPtr := closeTagPos + 1
		}
		
		inComment := false
		inSubLayer := 0
		retArray := []

		currTag := Map()
		currTagText := ""
		currValueText := ""
		currAttributes := Map()
		hasChildren := false

		lastCloseTag := 1
		for tagIndex in tags {
			currElementText := SubStr(text, lastCloseTag, tagIndex[2] - lastCloseTag + 1)
			currElement := SubStr(text, tagIndex[1], tagIndex[2] - tagIndex[1] + 1)
			; skip declaration
			if (StrLower(SubStr(currElement, 1, 5)) = "<?xml") {
				continue
			}

			; set for starting string of comment
			if (!inComment && SubStr(currElement, 1, 4) = "<!--") {
				inComment := true
			}
			; if in comment, check if comment is closed
			if (inComment) {
				inComment := SubStr(currElement, -3) != "-->"
				continue
			}

			; check for open tag
			if (globalRegExMatch(currElement, "^<(?!\/)[^>\s]+", &openTagObj)) {
				tagClosed := SubStr(currElement, -2) = "/>"

				if (currTag.Count = 0) {
					currTag := Map(
						"value", SubStr(currElement, openTagObj.Pos[1] + 1, openTagObj.Len[1] - 1),
						"text", SubStr(currElement, openTagObj.Pos[1], openTagObj.Len[1])
					)

					currAttributesText := SubStr(currElement, openTagObj.Pos[1] + openTagObj.Len[1])
					currAttributesValueStr := Trim(currAttributesText, this.eol . " `t/<>")
					; parse attributes in tag and add them to currAttributes
					if (currAttributesValueStr) {
						currAttributes := Map(
							"value", Map(),
							"text", currAttributesText
						)

						currIndex := 1
						if (globalRegExMatch(currAttributesValueStr, "\s+", &whitespaceObj)) {
							loop whitespaceObj.Count {
								whitespaceStr := SubStr(currAttributesValueStr, whitespaceObj.Pos[A_Index], whitespaceObj.Len[A_Index])
								if (inQuotes(currAttributesValueStr, whitespaceStr, whitespaceObj.Pos[A_Index])) {
									continue
								}

								attribText := SubStr(currAttributesValueStr, currIndex, whitespaceObj.Pos[A_Index] - currIndex + 1)
								if (Trim(attribText, this.eol . " `t")) {
									attrib := parseAttribute(attribText)
									currAttributes["value"][attrib["key"]] := Map(
										"value", attrib["value"],
										"text", attribText
									)
								}
								
								currIndex := whitespaceObj.Pos[A_Index] + whitespaceObj.Len[A_Index]
							}
						}

						; add any remaining attributes
						attribText := SubStr(currAttributesValueStr, currIndex)
						if (Trim(attribText, this.eol . " `t")) {
							attrib := parseAttribute(attribText)
							currAttributes["value"][attrib["key"]] := Map(
								"value", attrib["value"],
								"text", attribText
							)
						}
					}
					; clear currAttributes
					else {
						currAttributes := Map("value", "", "text", SubStr(currElement, -2) = "/>" ? "/>" : ">")
					}
					
					; if tag closes right away -> add to retArray
					if (tagClosed) {
						retArray.Push(Map(
							"value", Map(
								"openTag", currTag,
								"closeTag", Map("value", "", "text", ""),
								"attributes", currAttributes,
								"value", Map("value", "", "text", "")
							),
							"text", currElementText
						))

						currTag := Map()
						currTagText := ""
						currValueText := ""
						currAttributes := Map()
						hasChildren := false
						inSubLayer := 0
					}
					; else 
					else {
						currTagText := currElementText
					}
				}
				else {
					currValueText .= currElementText
					hasChildren := true
				}
				
				if (!tagClosed) {
					inSubLayer += 1
				}
			}
			else if (currTag.Has("value")) {
				; move up a sub layer
				if (inSubLayer && SubStr(currElement, 1, 2) = "</") {
					inSubLayer -= 1
				}

				; check for closing tag to currTag
				if (!inSubLayer && (StrLower(SubStr(currElement, 1, StrLen(currTag["value"]) + 2)) = "</" . StrLower(currTag["value"]))) {
					closeTagIndex := InStr(currElementText, SubStr(currElement, 1, StrLen(currTag["value"]) + 2))
					currValueText .= SubStr(currElementText, 1, closeTagIndex - 1)
					closeTag := Map(
						"value", currTag["value"],
						"text", SubStr(currElementText, closeTagIndex)
					)

					retArray.Push(Map(
						"value", Map(
							"openTag", currTag,
							"closeTag", closeTag,
							"attributes", currAttributes,
							"value", Map(
								"value", hasChildren ? this._readXML(currValueText) : currValueText, 
								"text", currValueText
							)
						),
						"text", currTagText . currValueText . SubStr(currElementText, closeTagIndex)
					))

					currTag := Map()
					currTagText := ""
					currValueText := ""
					currAttributes := Map()
					hasChildren := false
					inSubLayer := 0
				}
				; else -> current xml element added to parse for later
				else {
					currValueText .= currElementText
					hasChildren := true
				}
			}

			lastCloseTag := tagIndex[2] + 1
		}

		return retArray
	}

	_readYAML(text, overrideBaseIndent := -1) {		
		if ((RegExMatch(text, "^\s*\{") && RegExMatch(text, "\},*\s*$")) 
			|| (RegExMatch(text, "^\s*\[") && RegExMatch(text, "\],*\s*$"))) {

			return this._readJSON(text)
		}

		retType := ""
		retValue := ""
		baseIndent := overrideBaseIndent

		currKey := ""
		currText := ""
		currValue := ""
		currValueIndent := -1
		lineIndex := 1

		parseCurrValue() {
			if (retType = "map") {
				retValue[currKey] := Map(
					"value", this._readYAML(currValue, currValueIndent),
					"text", currText,
				)
			} else if (retType = "array") {
				retValue.Push(Map(
					"value", this._readYAML(currValue, currValueIndent),
					"text", currText,
				))
			} else if (retType = "string") {
				retValue .= Trim(currValue, this.eol . " `t")
			}
		}

		loop parse, text, this.eol  {
			rawLine := A_LoopField
			; strip comments from end of line
			if (globalRegExMatch(A_LoopField, "(?:^|\s)(#|;|%|\/\/)", &commentMatchObj)) {
				loop commentMatchObj.Count {
					foundChar := Trim(commentMatchObj[A_Index])
					if (!inQuotes(
						A_LoopField,
						foundChar, 
						commentMatchObj.Pos[A_Index] + commentMatchObj.Len[A_Index] - (StrLen(foundChar) + 1)
					)) {
						rawLine := SubStr(rawLine, 1, commentMatchObj.Pos[1] - 1)
						break
					}
				}
			}
			; skip line if empty
			if (!rawLine || !globalRegExMatch(rawLine, "\S+")) {
				continue
			}

			currIndent := 0
			if (globalRegExMatch(rawLine, "^\s+", &indentMatchObj)) {
				currIndent := indentMatchObj.Len[1]
			}

			; set up the base indent for identifying children items
			if (lineIndex = 1) {
				baseIndent := Max(baseIndent, currIndent)
			}
			; add children items to currValue
			else if (currIndent > baseIndent) {
				currText .= A_LoopField . this.eol
				currValue .= rawLine . this.eol

				continue
			}

			; parse current value
			if (currValue && currIndent = baseIndent) {
				parseCurrValue()
			}
			
			currText := A_LoopField . this.eol
			foundMatch := false
			if (globalRegExMatch(rawLine, "^.+:(?!\S)", &mapMatchObj)) {
				loop mapMatchObj.Count {
					trailingChars := 1
					if (globalRegExMatch(mapMatchObj[A_Index], "\s+$", &trailingObj)) {
						trailingChars += StrLen(trailingObj[1])
					}
					
					if (!inQuotes(rawLine,	":", mapMatchObj.Pos[A_Index] + mapMatchObj.Len[A_Index] - trailingChars)) {
						if (!retType) {
							retType := "map"
							retValue := Map()
						}

						currKey := Trim(SubStr(rawLine, 1, mapMatchObj.Len[A_Index] - 1))
						currValue := SubStr(rawLine, mapMatchObj.Len[A_Index] + 1) . this.eol
						currValueIndent := StrLen(StrSplit(rawLine, currKey,, 2)[1])

						foundMatch := true
						break
					}
				}
			}
			if (!foundMatch && globalRegExMatch(rawLine, "^\s*-\s", &listMatchObj)) {
				loop listMatchObj.Count {
					trailingChars := 1
					if (globalRegExMatch(listMatchObj[A_Index], "\s+$", &trailingObj)) {
						trailingChars += StrLen(trailingObj[1])
					}

					if (!inQuotes(rawLine, "-", listMatchObj.Pos[A_Index] + listMatchObj.Len[A_Index] - trailingChars)) {
						; initialize retValue on first loop
						if (!retType) {
							retType := "array"
							retValue := []
						}

						currValue := SubStr(rawLine, listMatchObj.Len[A_Index] + 1) . this.eol
						currValueIndent := listMatchObj.Len[A_Index]

						foundMatch := true
						break
					}
				}
			}
			if (!foundMatch) {
				; initialize retValue on first loop
				if (!retType) {
					retType := "string"
				}

				currValue := rawLine . this.eol
				currvalueIndent := baseIndent
			}

			lineIndex += 1
		}
		
		; parse any remaining current value
		if (currValue) {
			parseCurrValue()
		}

		return retValue
	}

	_readTOML(text) {
		; TODO
		return Map()
	}

	_getQuotePositions(text, customQuotes := "") {
		cleanQuotes := [['"', '"'], ["'", "'"]]
		if (customQuotes != "") {
			cleanQuotes := customQuotes
		}

		quotePosArr := []
		; add position arrays for bookends
		loop cleanQuotes.Length {
			quotePosArr.Push([])
		}

		textLen := StrLen(text)
		stringPtr := 1
		while (textLen >= stringPtr) {
			nextPos := textLen
			loop cleanQuotes.Length {
				currIndex := A_Index
				currLength := quotePosArr[currIndex].Length
		
				if (cleanQuotes[currIndex][1] = cleanQuotes[currIndex][2]) {
					currPos := InStr(text, cleanQuotes[currIndex][1],, stringPtr)
					if (currPos > 0) {
						skip := false
						loop currLength {
							if (quotePosArr[currIndex][currLength - (A_Index - 1)][1] = currPos 
								|| quotePosArr[currIndex][currLength - (A_Index - 1)][2] = currPos) {

								skip := true
								break
							}
						}

						if (!skip) {
							if (quotePosArr[currIndex].Length = 0 || quotePosArr[currIndex][quotePosArr[currIndex].Length][2] > 0) {
								quotePosArr[currIndex].Push([currPos, 0])
							}
							else {
								quotePosArr[currIndex][quotePosArr[currIndex].Length][2] := currPos
							}
						}					

						if (currPos >= stringPtr && currPos < nextPos) {
							nextPos := currPos
						}
					}
				}
				else {
					openPos := InStr(text, cleanQuotes[currIndex][1],, stringPtr)	
					closePos := InStr(text, cleanQuotes[currIndex][2],, stringPtr)

					if ((openPos && (openPos < closePos || !closePos))) {
						skip := false
						loop currLength {
							if (quotePosArr[currIndex][currLength - (A_Index - 1)][1] = openPos) {
								skip := true
								break
							}
						}

						if (!skip) {
							quotePosArr[currIndex].Push([openPos, 0])
						}
							
						if (openPos >= stringPtr && openPos < nextPos) {
							nextPos := openPos
						}
					}
					else if ((closePos && (closePos < openPos || !openPos))) {
						skip := false
						loop currLength {
							if (quotePosArr[currIndex][currLength - (A_Index - 1)][1] = openPos) {
								skip := true
								break
							}
						}

						if (!skip) {
							currLength := quotePosArr[currIndex].Length
							loop currLength {
								if (quotePosArr[currIndex][currLength - (A_Index - 1)][2] < closePos
									&& quotePosArr[currIndex][currLength - (A_Index - 1)][2] = 0) {
									
									quotePosArr[currIndex][currLength - (A_Index - 1)][2] := closePos
									break
								}
							}
						}
						
						if (closePos >= stringPtr && closePos < nextPos) {
							nextPos := closePos
						}
					}
				}
			}

			stringPtr := nextPos + 1
		}

		return quotePosArr
	}
	
	_cleanOriginalData(data) {
		dataType := Type(data)
		if (dataType = "Map" && data.Count = 2 && data.Has("value") && data.Has("text")) {
			return this._cleanOriginalData(data["value"])
		}

		if (dataType = "Map") {
			retData := Map()
			for key, value in data {
				retData[key] := this._cleanOriginalData(value)
			}
	
			return retData
		}
		else if (dataType = "Array") {
			retData := []
			for item in data {
				retData.Push(this._cleanOriginalData(item))
			}

			return retData
		}
		else {
			currValue := data
			if (inQuotes(data)) {
				currValue := SubStr(currValue, 2, StrLen(currValue) - 2)
			}

			return fromString(currValue, true)
		}
	}
}


class GlobalCfg extends Config {
	__New() {
		this.type := "ini"
		this.path := "global.cfg"

		defaultCfg := Map()
		if (FileExist("global.default.cfg")) {
			this.original := fileToString("global.default.cfg")
			this.eol := getEOL(this.original)
			defaultCfg := this._readINI(this.original)
		}

		userCfg := Map()
		if (FileExist(this.path)) {
			this.original := fileToString(this.path)
			this.eol := getEOL(this.original)
			userCfg := this._readINI(this.original)
		}

		this.originalData := this._combineConfig(userCfg, defaultCfg)
		this.data := this._cleanOriginalData(this.originalData)
	}

	_combineConfig(userCfg, defaultCfg) {
		retMap := ObjDeepClone(userCfg)

		for key, value in defaultCfg {
			if (!retMap.Has(key)) {
				retMap[key] := value
			}
			else if (Type(value["value"]) = "Map") {
				retMap[key]["value"] := this._combineConfig(retMap[key]["value"], value["value"])
				retMap[key]["text"] := retMap[key]["text"]
			}
		}

		return retMap
	}
}