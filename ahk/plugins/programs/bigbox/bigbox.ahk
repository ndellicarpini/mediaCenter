class BigBoxProgram extends Program {
    _restoreVolume := 100
    _storedVolume := false
    _unfocusTime := 0
    _lastCheckedVolumeTime := 0

    _launch(args*) {
        global globalStatus

        if (globalStatus["currProgram"]["id"] = this.id && !globalStatus["suspendScript"] && !globalStatus["desktopmode"]) {
            count := 0
            maxCount := 100
            ; make sure LaunchBox is not open while launching bigbox
            while (ProcessExist("LaunchBox.exe") && count < maxCount) {
                count += 1
                Sleep(200)
            }

            if (ProcessExist("LaunchBox.exe")) {
                ProcessClose("LaunchBox.exe")
                Sleep(500)
            }
        }

        ; for some reason BigBox freaks out when using RunAsUser (ShellExecute) 
        Run(this.dir . this.exe . A_Space . joinArray(args), this.dir)
    }

    _exists(args*) {
        global globalRunning
        global globalStatus
        global globalGuis

        retVal := super._exists(args*)
        hwnd := this._currHWND

        ; check and disable bigbox audio if bigbox in background
        if (retVal && hwnd && globalRunning.Has(this.id) && !globalStatus["suspendScript"] && !globalStatus["desktopmode"] && WinShown(hwnd)) {
            currActive := WinActive(hwnd)
            if (currActive || (globalStatus["currProgram"]["id"] = this.id && globalGuis.Has("pause"))) {
                this._unfocusTime := 0
                if (this._storedVolume && currActive) {
                    this.setVolume(this._restoreVolume)
                    this._storedVolume := false
                }
            }
            else {
                if (this._unfocusTime = 0) {
                    this._unfocusTime := A_TickCount
                }
                
                if (((A_TickCount - this._unfocusTime) < 30000 && ((A_TickCount - this._lastCheckedVolumeTime) > 500))) {
                    if (!this._storedVolume) {
                        this._restoreVolume := this.volume
                        this._storedVolume := true
                    }
                    
                    ; bigbox actually just ignores setting its volume sometimes, so just keep doing it
                    this.setVolume(0)
                }
            }
            
            this._lastCheckedVolumeTime := A_TickCount
        }

        return retVal
    }

    _restore() {
        startupHWND := 0
        mainHWND := 0

        for hwnd in this.getHWNDList() {
            title := WinGetTitle(hwnd)
            if (title = "LaunchBox Game Startup") {
                startupHWND := hwnd
                break
            }
            if (title = "LaunchBox Big Box") {
                mainHWND := hwnd
            }
        }

        if (startupHWND != 0 && !WinActive(startupHWND)) {
            WinActivateForeground(startupHWND)
        }
        else if (mainHWND != 0 && !WinActive(mainHWND)) {
            return WinActivateForeground(mainHWND)
        }
    }
}