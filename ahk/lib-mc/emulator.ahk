class Emulator extends Program {
    console := ""

    defaultRom    := ""
    romVersions   := []
    cleanRomNames := ""

    defaultControls := ""
    controlVersions := []

    romDir  := ""
    romExts := []

    numStates         := 0
    customSaveState   := ""
    customLoadState   := ""
    customSwapDisk    := ""
    customReset       := ""
    customRewind      := ""
    customFastForward := ""

    __New(exeConfig) {
        this.console := exeConfig["console"]

        ; control versions of console read from config files
        this.controlVersions := "bruh"

        this.romDir  := (exeConfig.Has("romDir"))  ? exeConfig["romDir"]  : this.romDir
        this.romExts := (exeConfig.Has("romExts")) ? exeConfig["romExts"] : this.romExts
        
        this.numStates         := (exeConfig.Has("numStates"))   ? exeConfig["numStates"]   : this.numStates
        this.customSaveState   := (exeConfig.Has("saveState"))   ? exeConfig["saveState"]   : this.customSaveState
        this.customLoadState   := (exeConfig.Has("loadState"))   ? exeConfig["loadState"]   : this.customLoadState
        this.customSwapDisk    := (exeConfig.Has("swapDisk"))    ? exeConfig["swapDisk"]    : this.customSwapDisk
        this.customReset       := (exeConfig.Has("reset"))       ? exeConfig["reset"]       : this.customReset
        this.customRewind      := (exeConfig.Has("rewind"))      ? exeConfig["rewind"]      : this.customRewind
        this.customFastForward := (exeConfig.Has("fastForward")) ? exeConfig["fastForward"] : this.customFastForward
    
        super(exeConfig)
    }

    launch(args) {
        rom := args[1]

        ; TODO - fill in defaults based on rom
        this.defaultRom := "bruh"
        this.romVersions := "bruh"
        this.defaultControls := "bruh"
        this.cleanRomNames := "bruh"

        newArgs := args

        super(newArgs)
    }

    saveState(slot) {
        if (this.customSaveState != "") {
            return runFunction(this.customSaveState, slot)
        }
    }

    loadState(slot) {
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
        if (this.customFastForward != "") {
            return runFunction(this.customFastForward)
        }
    }

    fastForward() {
        if (this.customFastForward != "") {
            return runFunction(this.customFastForward)
        }
    }
}