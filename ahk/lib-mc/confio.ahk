#Include string.ahk
#Include std.ahk

; class containing configuration data from a file
;  subConfig - map of configs based on groupings from config file
;  items - map of individual settings from config file (left of deliminator = key | right = value)
class Config {
	subConfigs := Map()
	items := Map()

	; convert the items into the proper types
	;
	; returns null
	cleanItems() {
		for key, value in this.items {

			; try to convert the item into a float, if successful save as number
			try {
				this.items[key] := Float(value)
			}
			catch {
				; check if value is a string representing a bool, convert to bool
				if (StrLower(value) = "true") {
					this.items[key] := true
				}
				else if (StrLower(value) = "false") {
					this.items[key] := false
				}
				
				; check if value is an array (contains ","), and convert appropriately
				else if (InStr(value, ",")) {
					tempArr := StrSplit(value, ",")

					this.items[key] := []
					for item in tempArr {
						this.items[key].Push(Trim(item, "`t "))
					}
				}
			}
		}
	}

	; perform cleanItems on subConfigs
	;
	; returns null
	cleanAllItems() {
		this.cleanItems()

		for key, value in this.subConfigs {
			this.subConfigs[key].cleanAllItems()
		}
	}

	; combines a config with this
	;  secondConfig - config to combine with this
	;  override - if this & secondConfig share a key, use secondConfig's
	;
	; returns null
	combineConfig(secondConfig, override) {
		
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
}

; reads from a file/string and generates a Config object
;  toRead - string/file to read
;  deliminator - string containing separator between a setting's key and value
;  subConfigType - how config file is formatted with its categories of configs
;                - brackets -> standard config file using bracketed category names 
;                - [TODO] xml -> formatted like an xml document with <x>...</x>
;                - [TODO] indents_x_y -> using indentation (x = number of indents per level | y = type (spaces/tabs))
;                - none -> config file contains no categories
;  subConfig - list of categories to find, empty = all categories
;
; returns Config object
readConfig(toRead, deliminator := "=", subConfigType := "none", subConfig := "") {
	retConfig := Config.New()
	configString := fileOrString(toRead)

	; clean indents
	indentsNum := 0
	indentsType := ""
	if (InStr(subConfigType, "indents")) {
		temp := StrSplit(subConfigType, "_")

		subConfigType := temp[1]
		indentsNum := Float(temp[2])
		if (InStr(temp[3], "space")) {
			indentsType := " "
		}
		else if (InStr(temp[3], "tab")) {
			indentsType := "`t"
		}
		else {
			MsgBox("
			(
				ERROR
				Invalid indent type for readConfig()
			)")
		}
	}

	; helper
	readConfigLoop(confName) {
		tempConfig := Config.New()

		currentConf := ""
		currentItem := []

		leftItem := ""
		rightItem := ""

		foundConfig := 1 ; 0 -> not found | 1 -> add to generic | 2 -> add to specific
		loop parse configString, "`n", "`r" {
			cleanLine := Trim(A_LoopField, " `t`r`n")
			
			if (cleanLine = "" || RegExMatch(cleanLine, "U)^;")) {
				continue
			}

			; subConfigType
			switch subConfigType {
				case "brackets":
					; find a group 
					if (RegExMatch(cleanLine, "U)^\[.*\]$")) {
						; replace 
						currentConf := RegExReplace(RegExReplace(cleanLine, "U)^\[|\]$"), "U)\] *\[", "-")
			
						if (confName = "") {
							tempConfig.subConfigs[currentConf] := Config.New()
							foundConfig := 2
						}
						else if (confName = currentConf) {
							foundConfig := 1
						}
						else {
							currentConf := ""
							foundConfig := 0
						}

						continue
					}
				
				; TODO - xml
				; TODO - indents
			}
			
			if (foundConfig > 0) {
				; create redundent map if no denominator
				if (deliminator != "") {
					currentItem := StrSplit(A_LoopField, deliminator,, 2)

					leftItem := RTrim(currentItem[1], " `t`r`n")
					rightItem := Trim(currentItem[2], " `t`r`n")
				}
				else {
					leftItem := cleanLine
					rightItem := ""
				}
				
				; add to generic items if no current subConfig
				if (foundConfig = 2) {
					tempConfig.subConfigs[currentConf].items[leftItem] := rightItem
				}
				else {
					tempConfig.items[leftItem] := rightItem
				}
			}
			
		}

		return tempConfig
	}

	if (IsObject(subConfig)) {
		for confIndex, confName in subConfig {
			retConfig.subConfigs[confName] := readConfigLoop(confName)
		}
	}
	else {
		retConfig := readConfigLoop(subConfig)
	}

	return retConfig
}

; reads custom formatted multicfg files with readConfig() on each requested one
;  fileName - multicfg file to read
;  configList - list of configs to find in multicfg
;  configListType - how to handle multiple values in configList (either "and" or "or")
;  perfectMatch - if value in configList needs to perfectly match id
;  checkDefault - check if multicfg contains default values to be overwritten
;  deliminator / subConfigType / subConfig - see readConfig()
; 
; returns Config object generated by readConfig()
readMultiCfg(fileName, configList, configListType := "or", perfectMatch := true, checkDefault := true
, deliminator := "=", subConfigType := "none", subConfig := "") {
	
	retConfig := Config.New()
	muliConfigString := ""

	; check that file exists
	if (FileExist(fileName)) {
		multiConfigString := fileToString(fileName)
	}
	else {
		MsgBox("
			(
				ERROR
				fileName not found when calling findMultiCfg()
			)"
		)

		return
	}

	if (!IsObject(configList)) {
		configList := [configList]
	}

	; to lower all values
	temp := []
	for item in configList {
		temp.Push(StrLower(item))
	}
	configList := temp

	; helper
	addConfigToRet(toRead, foundIDS, override) {
		; if only one major object should return (either because looking for 1 config or "and")
		if (configListType = "and" || configList.Length = 1) {
			retConfig.combineConfig(readConfig(toRead, deliminator, subConfigType, subConfig), override)
		}
		else {
			
			; for each item in foundIDS in this multiconfig 
			for value in foundIDS {
				if (retConfig.subConfigs.Has(value)) {
					retConfig.subConfigs[value].combineConfig(readConfig(toRead, deliminator, subConfigType, subConfig), override)
				}
				else {
					retConfig.subConfigs[value] := readConfig(toRead, deliminator, subConfigType, subConfig)
				}
			}
		}
	}

	inMultiCfg := false
	inIDS      := false
	inConfig   := false
	inDefault  := false

	idList := []
	sharedIDS := []
	idIndent := ""
	validID := false

	cfgBlock := ""
	cfgIndent := ""
	loop parse multiConfigString, "`n", "`r" {
		cleanLine := Trim(A_LoopField, " `t`r`n")

		if (cleanLine = "" || RegExMatch(cleanLine, "U)^;")) {
			continue
		}
		
		; found intial layer of single config
		if (!inMultiCfg && RegExMatch(cleanLine, "U)^START *\{$")) {
			inMultiCfg := true
		}
		; found default config
		else if (!inMultiCfg && RegExMatch(cleanLine, "U)^DEFAULT *\{$")) {
			inDefault := true
		}
		; found ID list in single config
		else if (inMultiCfg && !inIDS && RegExMatch(cleanLine, "U)^IDS *\{$")) {
			inIDS := true
			idIndent := "U)^" . RegExReplace(A_LoopField, "U)IDS *\{$")
		}
		; found config block within single config
		else if ((inMultiCfg || inDefault) && !inConfig && RegExMatch(cleanLine, "U)^CONFIG *\{$")) {
			inConfig := true
			cfgIndent := "U)^" . RegExReplace(A_LoopField, "U)CONFIG *\{$")
		}

		; if found single config & ids -> create a list of ids to check against configList
		else if (inMultiCfg && inIDS) {
			
			; looping until end of ids
			if (!RegExMatch(cleanLine, "U)^\} *END$")) {
				idList.Push(RTrim(RegExReplace(A_LoopField, idIndent), " `t`r`n"))
			}
			else {
				; check each value in configList vs pulled idList
				tempCount := 0
				for value in configList {
					for value2 in idList {
						temp := StrLower(value2)

						if (perfectMatch && value = temp) {
							tempCount += 1
							sharedIDS.Push(value2)
						}
						else if (!perfectMatch && (InStr(value, temp) || InStr(value2, temp))) {
							tempCount += 1
							sharedIDS.Push(value2)
						}
					}
				}

				; check that idList for all items in configList
				if (configListType = "and" && tempCount >= configList.Length) {
					validID := true
				}

				; check that idList contains at least 1 in configList
				else if (configListType = "or" && tempCount > 0) {
					validID := true
				}

				idList := []
				inIDS := false
			}
		}

		; if found a valid config
		else if (inMultiCfg && inConfig && validID) {
			
			; looping until end of config
			if (!RegExMatch(cleanLine, "U)^\} *END$")) {
				cfgBlock .= RegExReplace(A_LoopField, cfgIndent) . "`n"
			}
			else {
				addConfigToRet(cfgBlock, sharedIDS, true)

				sharedIDS := []
				cfgBlock := ""
				inConfig := false
				validID := false
			}
		}

		; if found default & config within
		else if (inDefault && inConfig) {

			; looping until end of config
			if (!RegExMatch(cleanLine, "U)^\} *END$")) {
				cfgBlock .= RegExReplace(A_LoopField, cfgIndent)
			}
			else {
				addConfigToRet(cfgBlock, [], false)

				cfgBlock := ""
				inConfig := false
			}
		}

		; end of config config
		else if (inMultiCfg && inConfig && RegExMatch(cleanLine, "U)^\} *END$")) {
			inConfig := false
		}
		
		; end of single config
		else if (inMultiCfg && !inIDS && !inConfig && RegExMatch(cleanLine, "U)^\} *END$")) {
			inMultiCfg := false
		}

		; end of default config
		else if (inDefault && !inConfig && RegExMatch(cleanLine, "U)^\} *END$")) {
			inDefault := false
		}
	}

	return retConfig
}

; creates the config\global.txt if it doesn't exist (copying global.default.txt), and tells the user to
; fill out the config file. Otherwise returns the cleaned config object
;
; returns an error message or the cleaned config object from global.txt
readGlobalConfig() {
	; first check if global.txt exists
	if (FileExist("config\global.txt")) {
		gConfig := readConfig("config\global.txt", , "brackets")

		; check the required settings from the config file (you bet they're hardcoded)
		if (!gConfig.subConfigs.Has("General") || !gConfig.subConfigs.Has("Display")
		|| !gConfig.subConfigs.Has("LoadScreen") || !gConfig.subConfigs.Has("Pause")
		|| !gConfig.subConfigs.Has("Boot") || !gConfig.subConfigs.Has("Executables")) {
			MsgBox("
				(
					ERROR
					Config global.txt is missing required setting categories
					Please check that all of the required settings exist
				)"
			)

			WinWaitClose()

			ExitApp()
		}
		else if ((!gConfig.subConfigs["Executables"].items.Has("Home")
		|| !gConfig.subConfigs["Executables"].items.Has("HomeDir"))
		|| (gConfig.subConfigs["Executables"].items["Home"] = "" 
		|| gConfig.subConfigs["Executables"].items["HomeDir"] = "")) {
			MsgBox("
				(
					ERROR
					No Home/HomeDir Executables in config\global.txt
					These settings are required to have values for the 
					scripts to function.
				)"
			)

			WinWaitClose()

			ExitApp()
		}

		; if global.txt is valid, return the cleaned copy of it
		gConfig.cleanAllItems()
		return gConfig
	}
	else {
		; if there is no global.txt or global.default.txt, you have to find them
		if (!FileExist("config\global.default.txt")) {
			MsgBox("
				(
					ERROR
					There are literally no config files in config\
					No global.txt & No global.default.txt
					You really screwed the pooch on this one bud
				)"
			)

			WinWaitClose()

			ExitApp()
		}

		defaultGlobal := FileOpen("config\global.default.txt", "r")
		defaultContents := defaultGlobal.Read()
		defaultGlobal.Close()

		newGlobal := FileOpen("config\global.txt", "w")
		newGlobal.Write(defaultContents)
		newGlobal.Close()
		
		MsgBox("
			(
				Welcome to the Media Center AHK Scripts
				A new config file has been generated at config\global.txt
				based on the default settings. Please review the config file
				before trying to run the program again.
			)"
		)

		WinWaitClose()

		ExitApp()
	}
}