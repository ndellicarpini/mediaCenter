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
    romNameIndex := 0
    emulators    := []
    extensions   := []

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
            this.%key% := value

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

        emuProgram := ""
        if (value.Has("emulators")) {
            emuProgram := IsObject(value["emulators"]) ? value["emulators"][1] : value["emulators"]
        }
        else if (value.Has("emulator")) {
            emuProgram := IsObject(value["emulator"]) ? value["emulator"][1] : value["emulator"]
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

            programConfig := ObjDeepClone(value2)
            paramString := console . " " . rom

            ; replace config options specified in the overrides
            if (paramString != "" && programConfig.Has("overrides") && Type(programConfig["overrides"]) = "Map") {  
                for key3, value3 in programConfig["overrides"] {
                    if (key3 = "" || !RegExMatch(paramString, "U)" . key3)) {
                        continue
                    }

                    ; replace config fields w/ override
                    if (IsObject(value3)) {
                        for key4, value4 in value3 {
                            programConfig[key4] := value4
                        }
                    }
                    ; assume className is replaced
                    else {
                        programConfig["className"] := value2
                    }

                    break
                }
            }

            ; create program class if has custom class
            if (programConfig.Has("className")) {
                globalRunning[emuProgram] := %programConfig["className"]%(console, programConfig, value)
            }
            ; create generic program
            else {
                globalRunning[emuProgram] := Emulator(console, programConfig, value)   
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