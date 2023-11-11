class DolphinEmulator extends Emulator {
    ; _getWNDW() {
    ;     try {
    ;         restoreDHW := A_DetectHiddenWindows
    ;         DetectHiddenWindows(this.background)

    ;         exe := this.getEXE()

    ;         retVal := ""
    ;         for item in WinGetList("ahk_exe " exe) {
    ;             currWNDW := WinGetTitle("ahk_id " item)

    ;             if (WinShown("ahk_id " item) && (this.background || (!this.background && WinActivatable("ahk_id " item))) 
    ;                 && InStr(currWNDW, "JIT64") && WinGetProcessName("ahk_id " item) = exe) {
                    
    ;                 retVal := currWNDW
    ;                 break
    ;             }
    ;         }

    ;         DetectHiddenWindows(restoreDHW)
    ;         return retVal
    ;     }

    ;     return ""
    ; }

    _pause() {
        this.send("{F10}")
    }

    _resume() {
        this._pause()
    }
    
    _saveState(slot) {
        this.send("{Shift down}")
        Sleep(100)
        this.send("{F1}")
        Sleep(100)
        this.send("{Shift up}")
    }

    _loadState(slot) {
        this.send("{F1}")
    }

    _reset() {
        this.send("r")
    }

    _fastForward() {
        if (this.fastForwarding) {
            this.send("{Tab up}")
        }
        else {
            this.send("{Tab down}")
        }
    }
}