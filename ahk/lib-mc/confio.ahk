#Include std.ahk

; class containing configuration data from a file
;  subConfig - map of configs based on groupings from config file
;  items - map of individual settings from config file (left of deliminator = key | right = value)
;  indent - prefix of '`t' or ' ' before each item in the config
class Config {
	subConfigs := Map()
	items := Map()
	indent := ""

	; convert the items into the proper types
	;  trim - whether or not to trim from each item
	;
	; returns null
	cleanItems(trim := false) {
		for key, value in this.items {
			this.items[key] := fromString(value, trim)
		}
	}

	; perform cleanItems on subConfigs
	;  trim - see cleanItems()
	;
	; returns null
	cleanAllItems(trim := false) {
		this.cleanItems(trim)

		for key, value in this.subConfigs {
			this.subConfigs[key].cleanAllItems(trim)
		}
	}

	; combines a config with this
	;  secondConfig - config to combine with this
	;  override - if this & secondConfig share a key, use secondConfig's
	;
	; returns null
	combineConfig(secondConfig, override := true) {
		
		; combines for each subConfig 
		for key, value in secondConfig.subConfigs {
			if (this.subConfigs.Has(key)) {
				this.subConfigs[key].combineConfig(value, override)
			}
			else {
				this.subConfigs[key] := value
			}
		}

		; combines for each item
		for key, value in secondConfig.items {
			if (override && this.items.Has(key)) {
				this.items[key] := value
			}
			else {
				this.items[key] := value
			}
		}
	}

	; create map from config
	toMap() {
		retMap := Map()
		for key, value in this.items {
			retMap[key] := value
		}

		for key, value in this.subConfigs {
			retMap[key] := value.toMap()
		}

		return retMap
	}
}

; reads from a file/string and generates a Config object
;  toRead - string/file to read
;  deliminator - string containing separator between a setting's key and value
;  subConfigType - how config file is formatted with its categories of configs
;                - brackets -> standard config file using bracketed category names 
;				 - json -> formatted like a json file {...}
;                - [TODO] xml -> formatted like an xml document with <x>...</x>
;                - [TODO] indents_x_y -> using indentation (x = number of indents per level | y = type (spaces/tabs))
;                - none -> config file contains no categories
;  subConfig - list of categories to find, empty = all categories
;
; returns Config object
readConfig(toRead, deliminator := "=", subConfigType := "none", subConfig := "") {
	; --- INTERNAL HELPERS ---
	
	; converts a list of items with no subconfigs into the config's item map of key, value (as strings) pairs
	addItemsToConfig(configObj, itemString) {
		leftItem  := ""
		rightItem := ""
		
		inMultiLine := 0
		cringyJSONIndentationFix := false

		loop parse itemString, "`n", "`r" {
			cleanLine := Trim(A_LoopField, " `t`r`n")

			; skip empty lines / comment lines
			if (cleanLine = "" || RegExMatch(cleanLine, "U)^;")) {
				continue
			}

			; if no deliminator -> just add all values to items as keys
			if (deliminator = "") {
				configObj.items[cleanLine] := ""
			}

			else if (subConfigType = "brackets" || subConfigType = "none") {
				; if line contains valid deliminator to set leftItem
				if (!inQuotes(cleanLine, deliminator) && InStr(cleanLine, deliminator)) {
					; save previous left=right to configObj after finding next line withh valid deliminator
					if (leftItem != "") {
						configObj.items[leftItem] := Trim(rightItem, " `t`r`n")
					}

					currentItem := StrSplit(cleanLine, deliminator,, 2)

					leftItem  := Trim(currentItem[1], " `t`r`n")
					rightItem := Trim(currentItem[2], " `t`r`n")
				}
				; add lines to right item for multiline right item values
				else if (leftItem != "") {
					rightItem .= cleanLine . "`n"
				}
			}

			else if (subConfigType = "json") {
				; this is some stupid cringe code to fix a json's identation value, dont know if useful
				if (!(inMultiLine > 0 || inQuotes(cleanLine, deliminator)) && !cringyJSONIndentationFix
					&& InStr(cleanLine, deliminator) && configObj.indent = "") {

					configObj.indent := StrSplit(A_LoopField, cleanLine)[1]
					cringyJSONIndentationFix := true
				}

				; if line contains valid deliminator to set leftItem
				if (!(inMultiLine > 0 || inQuotes(cleanLine, deliminator)) && InStr(cleanLine, deliminator)) {
					; save previous left=right to configObj after finding next line withh valid deliminator
					if (leftItem != "") {
						configObj.items[leftItem] := Trim(rightItem, ' `t`r`n[],')
					}

					currentItem := StrSplit(cleanLine, deliminator,, 2)

					leftItem  := Trim(currentItem[1], ' `t`r`n,"')
					rightItem := currentItem[2]
				}
				; add lines to right item for multiline right item values
				else if (leftItem != "") {
					rightItem .= cleanLine . "`n"
				}


				; check if opening list
				if (!inQuotes(rightItem, "[")) {
					inMultiLine += 1
				}

				; check if closing list
				if (inMultiLine > 0 && !inQuotes(rightItem, "]")) {
					inMultiLine -= 1
				}
			}

			else if (subConfigType = "xml") {
				; TODO
			}

			else if (subConfigType = "indents") {
				; TODO
			}

		}

		; save final left=right items if last item was not saved
		if (leftItem != "" && !configObj.items.Has(leftItem)) {
			if (subConfigType = "json") {
				rightItem := Trim(rightItem, ' `t`r`n[],')
			}

			configObj.items[leftItem] := rightItem
		}

		return configObj
	}

	; seperate each subconfig recursively & feed them to addItemsToConfig
	subConfigHelper(subToRead) {
		retConfig := Config.New()

		subConfigLevel := 0
		currentSubConfig := ""
		currentString := ""
		
		; clean parameters & subToRead for json settings
		if (subConfigType = "json") {
			deliminator := ":"

			subToRead := Trim(subToRead, " `t`r`n")

			if (SubStr(subToRead, 1, 1) = "{" && SubStr(subToRead, -1, 1) = "}") {
				subToRead := SubStr(subToRead, 2, StrLen(subToRead) - 2)
			}
		}

		; string that is passed to addItemsToConfig
		; each subconfig section of the string is dropped from itemString
		itemString := subToRead
	
		loop parse subToRead, "`n", "`r" {
			cleanLine := Trim(A_LoopField, " `t`r`n")
	
			; skip empty lines / comment lines
			if (cleanLine = "" || RegExMatch(cleanLine, "U)^;")) {
				itemString := StrReplace(itemString, A_LoopField,, true,, 1) 

				continue
			}

			; check if config's indent needs to be updated
			if (subConfigType != "none" && subConfigLevel = 0 && (deliminator = "" || !inQuotes(cleanLine, deliminator))) {
				newIndent := StrSplit(A_LoopField, cleanLine)[1]
				if (newIndent != "" && (retConfig.indent = "" || StrLen(retConfig.indent) > StrLen(newIndent))) {
					retConfig.indent := newIndent
				}
			}
			
			if (subConfigType = "brackets") {
				; if line contains valid subconfig title
				if (!(inQuotes(cleanLine, "[") || inQuotes(cleanLine, "]")) && RegExMatch(cleanLine, "U)^\[.*\]$")) {			
					; set currentString as sub config & recursively send it to subConfigHelper
					if (currentString != "") {
						currentString := RTrim(currentString, " `n")

						retConfig.subConfigs[currentSubConfig] := subConfigHelper(currentString)

						currentString := ""
					}

					itemString := StrReplace(itemString, A_LoopField,, true,, 1) 
					currentSubConfig := RegExReplace(RegExReplace(cleanLine, "U)^\[|\]$"), "U)\] *\[", "-")

					continue
				}

				; add subconfig lines to currentString & remove them from itemString
				if (currentSubConfig != "") {
					itemString := StrReplace(itemString, A_LoopField,, true,, 1)
					currentString .= cleanLine . "`n"
				}
			}

			else if (subConfigType = "json") {
				; if line contains valid subconfig title
				if (!(inQuotes(cleanLine, deliminator) || inQuotes(cleanLine, "{")) && RegExMatch(cleanLine, "U)^.*" . deliminator . " *\{")) {
					
					; set currentSubConfig if subconfig title is direct subconfig to current config
					if (subConfigLevel = 0) {
						currentSubConfig := Trim(StrSplit(cleanLine, deliminator,, 2)[1], ' "')
					}

					subConfigLevel += 1
				}

				; add subconfig lines to currentString & remove them from itemString
				if (currentSubConfig != "") {
					itemString := StrReplace(itemString, A_LoopField,, true,, 1) 
					currentString .= RTrim(A_LoopField, " `t`r`n") . "`n"

					; if line contains valid end of subconfig
					if (!inQuotes(cleanLine, "}") && RegExMatch(cleanLine, "U)^.*\}")) {
						subConfigLevel -= 1

						; if end of subconfig is direct under current config - set currentString as sub config & recursively send it to subConfigHelper
						if (subConfigLevel = 0) {
							currentString := RegExReplace(currentString, "U)^\s*" . '"' . regexClean(currentSubConfig) . '"' . " *" . deliminator . "\s*") 
							currentString := RTrim(currentString, " `t`r`n,")

							retConfig.subConfigs[currentSubConfig] := subConfigHelper(currentString)

							currentString := ""
							currentSubConfig := ""
						}
					}
				}
			}

			else if (subConfigType = "xml") {
				; TODO
			}

			else if (subConfigType = "indents") {
				; TODO
			}
			
		}

		; saves final subconfig if currentString has content
		if (currentString && currentSubConfig && subConfigType != "json") {
			currentString := RTrim(currentString, " `n")

			retConfig.subConfigs[currentSubConfig] := subConfigHelper(currentString)
		}

		; format each as config's items
		return addItemsToConfig(retConfig, itemString)
	}

	; --- EXECUTION BEGINS ---

	configString := fileOrString(toRead)

	; just add items to config if there are no subconfigs in file
	if (subConfigType = "none") {
		return addItemsToConfig(Config.New(), configString)
	}

	retObj := subConfigHelper(configString)

	; if looking for multiple subconfigs
	if (IsObject(subConfig)) {
		loopObj := Config.New()

		for item in subConfig {
			for key, value in retObj.subConfigs {
				if (key = item) {
					loopObj.subConfig[key] := value
				}
			}
		}

		return loopObj
	}
	; if looking for 1 subconfig
	else if (subConfig != "") {
		return retObj.subConfigs[subConfig]
	}
	else {
		return retObj
	} 
}

; reads custom formatted multicfg files with readConfig() on each requested one
;  toRead - string/file to read
;  configList - list of configs to find in multicfg
;  configListType - how to handle multiple values in configList (either "and" or "or")
;  subConfig - string or list of subConfigs to return from each config
;  perfectMatch - if value in configList needs to perfectly match id
; 
; returns Config object generated by readConfig()
readMultiCfg(toRead, configList, configListType := "or", subConfig := "", perfectMatch := true, enableDefault := true) {
	mConfigString := fileOrString(toRead)
	configString := ""

	inConfig := true
	configs := []
	loop parse mConfigString, "`n", "`r" {
		cleanLine := Trim(A_LoopField, " `t`r`n")

		; skip empty lines / comment lines
		if (cleanLine = "" || RegExMatch(cleanLine, "U)^;")) {
			continue
		}

		; check for opening bracket for config in mconfig
		if (!inConfig && RegExMatch(A_LoopField, "U)^\{\s*$")) {
			inConfig := true
			configString .= A_LoopField . "`n"
			
			continue
		}
		; check for closing bracket for config
		else if (inConfig && RegExMatch(A_LoopField, "U)^\}\s*$")) {
			inConfig := false
			configString .= A_LoopField

			; add cleaned config to config list
			tempConfig := readConfig(configString,, "json")
			tempConfig.cleanAllItems()
			configs.Push(tempConfig)
			
			configString := ""
			continue
		}

		; append to configString
		if (inConfig) {
			configString .= A_LoopField . "`n"
		}
	}

	retConfig := Config.New()
	retIndent := ""
	for item in configs {
		; clean ids
		if (Type(item.items["id"]) = "Array") {
			tempArr := []

			for value in item.items["id"] {
				tempArr.Push(Trim(value, ' `t`r`n"' . "'"))
			}

			item.items["id"] := tempArr
			
		}
		else {
			item.items["id"] := [Trim(item.items["id"], ' `t`r`n"' . "'")]
		}

		; check for default config
		if (enableDefault && StrLower(item.items["id"]) = "default") {
			retConfig.combineConfig(item.subConfigs["config"], false)
		}

		; check each config if contains configList
		if (inArray(configList, item.items["id"], configListType, perfectMatch)) {
			retIndent := item.indent . item.indent

			; check for subconfigs in returning configs
			if (subConfig = "") {
				retConfig.combineConfig(item.subConfigs["config"])
			}
			else if (IsObject(subConfig)) {
				for sub, value in subConfig {
					if (item.subConfigs["config"].subConfigs.Has(sub)) {
						retConfig.combineConfig(value)
					}
				}
			}
			else if (item.subConfigs["config"].subConfigs.Has(subConfig)) {
				retConfig.combineConfig(item.subConfigs["config"].subConfigs[subConfig])
			}
		}
	}

	retConfig.indent := retIndent
	return retConfig
}

; creates the config\global.txt if it doesn't exist (copying global.default.txt), and tells the user to
; fill out the config file. Otherwise returns the cleaned config object
;
; returns an error message or the cleaned config object from global.txt
readGlobalConfig() {
	; first check if global.txt exists
	if (FileExist("config\global.txt")) {
		gConfig := readConfig("config\global.txt",, "brackets")

		; check the required settings from the config file (you bet they're hardcoded)
		if (!gConfig.subConfigs.Has("General") || !gConfig.subConfigs.Has("Display")
		|| !gConfig.subConfigs.Has("Boot")) {
			ErrorMsg(
				(
					"
					Config global.txt is missing required setting categories
					Please check that all of the required settings exist
					"
				),
				true
			)
		}

		; if global.txt is valid, return the cleaned copy of it
		gConfig.cleanAllItems()
		return gConfig
	}
	else {
		; if there is no global.txt or global.default.txt, you have to find them
		if (!FileExist("config\global.default.txt")) {
			ErrorMsg(
				(
					"
					There are literally no config files in config\
					No global.txt & No global.default.txt
					You really screwed the pooch on this one bud
					"
				)
			)
		}

		defaultGlobal := FileOpen("config\global.default.txt", "r")
		defaultContents := defaultGlobal.Read()
		defaultGlobal.Close()

		newGlobal := FileOpen("config\global.txt", "w")
		newGlobal.Write(defaultContents)
		newGlobal.Close()

		MsgBox(
			(
				"
				Welcome to the Media Center AHK Scripts
				A new config file has been generated at config\global.txt
				based on the default settings. Please review the config file
				before trying to run the program again.
				"
			)
		)

		WinWaitClose()

		ExitApp()
	}
}