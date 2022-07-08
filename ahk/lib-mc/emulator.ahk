class Emulator extends Program {
    console := ""

    rom := ""
    romVersions   := []
    cleanRomNames := []

    defaultControls := ""
    controlVersions := ["Xbox Controller"]

    numStates         := 0
    customSaveState   := ""
    customLoadState   := ""
    customSwapDisk    := ""
    customReset       := ""
    customRewind      := ""
    customFastForward := ""

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
        
        this.numStates         := (exeConfig.Has("numStates"))   ? exeConfig["numStates"]   : this.numStates
        this.customSaveState   := (exeConfig.Has("saveState"))   ? exeConfig["saveState"]   : this.customSaveState
        this.customLoadState   := (exeConfig.Has("loadState"))   ? exeConfig["loadState"]   : this.customLoadState
        this.customSwapDisk    := (exeConfig.Has("swapDisk"))    ? exeConfig["swapDisk"]    : this.customSwapDisk
        this.customReset       := (exeConfig.Has("reset"))       ? exeConfig["reset"]       : this.customReset
        this.customRewind      := (exeConfig.Has("rewind"))      ? exeConfig["rewind"]      : this.customRewind
        this.customFastForward := (exeConfig.Has("fastForward")) ? exeConfig["fastForward"] : this.customFastForward

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

        if (this.numStates > 0 && this.customSaveState != "") {
            this.pauseOptions["Save State"] := "setStatusParam internalMessage 'program.saveState 0'"
            this.pauseOptions["Load State"] := "setStatusParam internalMessage 'program.loadState 0'"
            this.pauseOrder.Push("Save State", "Load State")
        }

        if (this.customReset != "") {
            this.pauseOptions["Reset Game"] := "setStatusParam internalMessage program.reset"
            this.pauseOrder.Push("Reset Game")
        }

        super.__New(exeConfig)
    }

    launch(rom) {
        this.rom := rom

        ; TODO - fill in defaults based on rom
        this.defaultRom := "bruh"   
        this.romVersions := "bruh"
        this.defaultControls := "bruh"
        this.cleanRomNames := "bruh"

        super.launch([rom])
    }

    postExit() {
        if (this.rewinding) {
            this.rewind()
        }

        if (this.fastForwarding) {
            this.fastForward()
        }

        super.postExit()
    }

    saveState(slot := 0) {
        if (this.customSaveState != "") {
            return runFunction(this.customSaveState, slot)
        }
    }

    loadState(slot := 0) {
        if (this.customLoadState != "") {
            return runFunction(this.customLoadState, slot)
        }
    }

    swapDisk() {
        if (this.customSwapDisk != "") {
            return runFunction(this.customSwapDisk)
        }
    }

    reset() {
        if (this.customReset != "") {
            return runFunction(this.customReset)
        }
    }

    rewind() {
        if (this.fastForwarding) {
            this.fastForward()
        }

        if (this.customRewind != "") {
            retVal := runFunction(this.customRewind)

            this.rewinding := !this.rewinding
            return retVal
        }
    }

    fastForward() {
        if (this.rewinding) {
            this.rewind()
        }

        if (this.customFastForward != "") {
            retVal := runFunction(this.customFastForward)

            this.fastForwarding := !this.fastForwarding
            return retVal
        }
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
        cleanParams := StrSplit(params, A_Space,, 2)
        console := cleanParams[1]
        rom := cleanParams[2]
    }
    
    for key, value in globalConsoles {
        ; find console config from id
        if (StrLower(key) = StrLower(console)) {
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
                if (StrLower(key2) = StrLower(emuProgram)) {
                    ; check if program or program w/ same name exists
                    for key3, value3 in globalRunning {
                        if (key2 = key3 || value2["name"] = value3.name) {
                            ; just set the running program as current
                            if (setCurrent || launchProgram) {
                                ; reset game if different rom requested
                                if (rom != value3.rom) {
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

                    globalRunning[emuProgram] := Emulator(console, value2, value)

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
            }

            ErrorMsg("Emulator " . emuProgram . " was not found")
        }
    }

    ErrorMsg("Console " . console . " was not found")
}