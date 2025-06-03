class BigBoxProgram extends Program {
    _restoreVolume := 100
    _storedVolume := false
    _waitingVolumeTimer := false
    
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

        if (startupHWND != 0) {
            ; mute bigbox when launching game
            if (!this._storedVolume && !this._waitingVolumeTimer) {
                SetTimer(MuteTimer, Neg(650))
                this._waitingVolumeTimer := true
            }

            if (!WinActive(startupHWND)) {
                WinActivateForeground(startupHWND)
            }
        }
        else if (mainHWND != 0) {
            ; unmute bigbox after restore
            if (this._storedVolume) {
                this.checkVolume()

                if (!this.background && this.volume > -1) {
                    this.setVolume(this._restoreVolume)
                    this._storedVolume := false
                }
            }

            if (!WinActive(mainHWND)) {
                return WinActivateForeground(mainHWND)
            }
        }

        return

        MuteTimer() {
            this.checkVolume()

            if (!this.background && this.volume > -1) {
                this._restoreVolume := this.volume
                this._storedVolume := true
                this.setVolume(0)
            }

            this._waitingVolumeTimer := false
            return
        }
    }
}