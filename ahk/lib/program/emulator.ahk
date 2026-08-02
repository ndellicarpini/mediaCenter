class Emulator extends Program {
    console := ""

    rom := ""
    romVersions   := []
    cleanRomNames := []

    defaultControls := ""
    controlVersions := ["Xbox Controller"]

    numStates := 0
    ffSupport     := false
    rewindSupport := false
    resetSupport  := false

    romDir  := ""
    romNameIndex  := 0
    emulators     := []
    emulatorIndex := 1
    extensions    := []

    rewinding := false
    fastForwarding := false

    __New(console, exeConfigRef, consoleConfigRef) {
        exeConfig := ObjDeepClone(exeConfigRef)
        consoleConfig := ObjDeepClone(consoleConfigRef)

        this.console := console

        ; control versions of console read from config files
        this.controlVersions := (exeConfig.Has("controls")) ? exeConfig["controls"] : this.controlVersions
        
        this.numStates     := (exeConfig.Has("numStates"))   ? exeConfig["numStates"]   : this.numStates
        this.ffSupport     := (exeConfig.Has("fastForward")) ? exeConfig["fastForward"] : this.ffSupport
        this.rewindSupport := (exeConfig.Has("rewind"))      ? exeConfig["rewind"]      : this.rewindSupport
        this.resetSupport  := (exeConfig.Has("reset"))       ? exeConfig["reset"]       : this.resetSupport
  
        dirFound        := false
        nameIndexFound  := false
        emulatorsFound  := false
        extensionsFound := false

        ; try to find required config values from console and save other values to custom config
        for key, value in consoleConfig {
            ; needs to be a try bc functions arent included in HasOwnProp??
            try this.%key% := value

            if (key = "romDir") {
                dirFound := true
            }
            else if (key = "romNameIndex") {
                nameIndexFound := true
            }
            else if (key = "emulators") {
                emulatorsFound := true
            }
            else if (key = "extensions") {
                extensionsFound := true
            }
        }

        if (!dirFound || !nameIndexFound || !emulatorsFound || !extensionsFound) {
            ErrorMsg("Console " . this.console . " does not have a valid config", true)
        }

        if (this.numStates > 0) {
            this.pauseOptions["Save State"] := "program.saveState"
            this.pauseOptions["Load State"] := "program.loadState"
            this.pauseOrder.Push("Save State", "Load State")
        }

        ; TODO - check number of rom disks/m3u for swap disk menu

        if (this.resetSupport) {
            this.pauseOptions["Reset Game"] := "program.reset"
            this.pauseOrder.Push("Reset Game")
        }

        super.__New(exeConfig)
    }

    launch(args*) {
        ; rom is always the first arg
        this.rom := args[1]

        ; TODO - fill in defaults based on rom
        this.defaultRom := "bruh"   
        this.romVersions := "bruh"
        this.defaultControls := "bruh"
        this.cleanRomNames := "bruh"

        super.launch(this.rom)
    }

    postExit() {
        if (this.rewinding) {
            this.rewind()
        }

        if (this.fastForwarding) {
            this.fastForward()
        }

        this._postExit()
    }
    _postExit() {
        super._postExit()
    }

    saveState(slot := 0) {
        if (this.numStates = 0) {
            return
        }

        this._saveState(slot)
    }
    _saveState(slot) {
        return
    }

    loadState(slot := 0) {
        if (this.numStates = 0) {
            return
        }

        this._loadState(slot)
    }
    _loadState(slot) {
        return
    }

    swapDisk() {
        ; TODO - check swap disk support

        if (this.fastForwarding) {
            this.fastForward()
            Sleep(100)
        }
        if (this.rewinding) {
            this.rewind()
            Sleep(100)
        }

        this._swapDisk()
    }
    _swapDisk() {
        return
    }

    reset() {
        if (!this.resetSupport) {
            return
        }

        if (this.fastForwarding) {
            this.fastForward()
            Sleep(100)
        }
        if (this.rewinding) {
            this.rewind()
            Sleep(100)
        }

        this._reset()
    }
    _reset() {
        return
    }

    rewind() {
        if (!this.rewindSupport) {
            return
        }

        if (this.fastForwarding) {
            this.fastForward()
            Sleep(100)
        }

        this._rewind()
        this.rewinding := !this.rewinding
    }
    _rewind() {
        return
    }

    fastForward() {
        if (!this.ffSupport) {
            return
        }

        if (this.rewinding) {
            this.rewind()
            Sleep(100)
        }

        this._fastForward()
        this.fastForwarding := !this.fastForwarding
    }
    _fastForward() {
        return
    }
}

createConsole(params, launchProgram := true, setCurrent := true, customAttributes := "") {
    global globalRunning
    global globalPrograms
    global globalConsoles

    console := ""
    rom := ""

    if (IsObject(params)) {
        console := params[1]
        rom := params[2]
    }
    else {
        cleanParams := StrSplitIgnoreQuotes(params,,,, 2)
        console := cleanParams[1]
        rom := cleanParams[2]
    }
    
    for key, value in globalConsoles {
        ; find console config from id
        if (StrLower(key) != StrLower(console)) {
            continue
        }

        ; if config missing required values
        if (!value.Has("id")) {
            ErrorMsg("Tried to create console " . console . " missing required fields id/name", true)
            return
        }
        
        ; TODO - PARSE ROM & GET SPECIFIC EMULATOR
        
        configData := getExtendedRomConfig(Map(), value, rom)
        emuProgram := ""
        if (configData["console"].Has("emulators")) {
            emulatorIndex := 1
            if (configData["console"].Has("emulatorIndex")) {
                emulatorIndex := Integer(configData["console"]["emulatorIndex"])
            }

            emuProgram := configData["console"]["emulators"][emulatorIndex]
        }

        for key2, value2 in globalPrograms {
            ; find program config from emuProgram
            if (StrLower(key2) != StrLower(emuProgram)) {
                continue
            }

            ; check if program or program w/ same name exists
            for key3, value3 in globalRunning {
                if ((key2 = key3 || value2["name"] = value3.name) && value3.exists()) {
                    ; just set the running program as current
                    if (setCurrent) {
                        ; reset game if different rom requested
                        if (value3.HasOwnProp("rom") && rom != value3.rom) {
                            value3.exit()
                            break
                        }
                        else {
                            setCurrentProgram(key3)
                            resetLoadScreen()
                            return
                        }
                    }
                }
            }

            configData := getExtendedRomConfig(
                getExtendedProgramConfig(value2, console . " " . rom),
                value,
                rom
            )

            ; create program class if has custom class
            if (configData["program"].Has("className")) {
                globalRunning[emuProgram] := %configData["program"]["className"]%(console, configData["program"], configData["console"])
                writeLog(emuProgram . " created (class: " . configData["program"]["className"] . ")", "PROGRAM")
            }
            ; create generic program
            else {
                globalRunning[emuProgram] := Emulator(console, configData["program"], configData["console"])   
                writeLog(emuProgram . " created (class: Program)", "PROGRAM")
            }

            ; set new program as current
            if (setCurrent) {
                setCurrentProgram(emuProgram)
            }

            ; launch new program
            if (launchProgram) {
                globalRunning[emuProgram].launch(rom)
            }

            ; set attributes of program (basically only done from backup.bin)
            if (customAttributes != "") {                
                for key, value in customAttributes {
                    globalRunning[emuProgram].%key% := value
                }
            }

            return
        }

        ErrorMsg("Emulator " . emuProgram . " was not found")
        return
    }

    ErrorMsg("Console " . console . " was not found")
    return
}

; merges rom override data with the main config of the program if rom matches
;  programConfig - base config of the program
;  consoleConfig - base config of the console
;  rom - rom path that the console is running
;
; returns appropriate config for program
getExtendedRomConfig(programConfig, consoleConfig, rom) {
    internalProgramConfig := ObjDeepClone(programConfig)
    internalConsoleConfig := ObjDeepClone(consoleConfig)

    consoleOverride := ""
    if (internalConsoleConfig.Has("consoleOverride")) {
        consoleOverride := internalConsoleConfig["consoleOverride"]
    }
    else if (internalConsoleConfig.Has("consoleOverrides")) {
        consoleOverride := internalConsoleConfig["consoleOverrides"]
    }

    if (consoleOverride != "") {
        for key, value in consoleOverride {
            internalProgramConfig[key] := value
        }
    }

    romOverride := ""
    if (internalConsoleConfig.Has("romOverride")) {
        romOverride := internalConsoleConfig["romOverride"]
    }
    else if (internalConsoleConfig.Has("romOverrides")) {
        romOverride := internalConsoleConfig["romOverrides"]
    }

    if (romOverride = "") {
        return Map("program", internalProgramConfig, "console", internalConsoleConfig)
    }

    for item in romOverride {
        if(!item.Has("romMatch")) {
            continue
        }

        argCheck := ""
        if (item["romMatch"].Has("arg")) {
            argCheck := item["romMatch"]["arg"]
        }
        else if (item["romMatch"].Has("args")) {
            argCheck := item["romMatch"]["args"]
        }

        if (argCheck = "") {
            continue
        }
        
        matchType := (item["romMatch"].Has("matchType")) ? StrLower(Trim(item["romMatch"]["matchType"])) : "full"
        matchResult := false
        if (!IsObject(argCheck)) {
            switch (matchType) {
                case "full":
                    matchResult := (StrLower(Trim(rom)) = StrLower(argCheck))
                case "partial":
                    matchResult := InStr(StrLower(rom), StrLower(argCheck))
                case "start":
                    matchResult := SubStr(StrLower(Trim(rom)), 1, StrLen(argCheck)) = StrLower(argCheck)
                case "end":
                    matchResult := SubStr(StrLower(Trim(rom)), -StrLen(argCheck)) = StrLower(argCheck)
            }
        } else {
            multiType := (item["romMatch"].Has("multiType")) ? StrLower(Trim(item["romMatch"]["multiType"])) : "and"
            multiResult := (multiType = "and") ? true : false
            for arg in argCheck {
                currSolution := false
                switch (matchType) {
                    case "full":
                        currSolution := (StrLower(Trim(rom)) = StrLower(arg))
                    case "partial":
                        currSolution := InStr(StrLower(rom), StrLower(arg))
                    case "start":
                        currSolution := SubStr(StrLower(Trim(rom)), 1, StrLen(arg)) = StrLower(arg)
                    case "end":
                        currSolution := SubStr(StrLower(Trim(rom)), -StrLen(arg)) = StrLower(arg)
                }

                if (multiType = "and") {
                    multiResult := multiResult && currSolution
                }
                else if (multiType = "or") {
                    multiResult := multiResult || currSolution
                }
            }

            matchResult := multiResult
        }

        if (matchResult) {
            for key, value in item {
                if (key = "romMatch") {
                    continue
                }

                internalProgramConfig[key] := value
                internalConsoleConfig[key] := value
            }
        }
    }

    return Map("program", internalProgramConfig, "console", internalConsoleConfig)
}