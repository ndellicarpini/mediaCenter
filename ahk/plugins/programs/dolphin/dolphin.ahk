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
        SendSafe("{F10}")
    }

    _resume() {
        this._pause()
    }
    
    _saveState(slot) {
        Send("{Shift down}")
        Sleep(100)
        SendSafe("{F1}")
        Sleep(100)
        Send("{Shift up}")
    }

    _loadState(slot) {
        SendSafe("{F1}")
    }

    _reset() {
        SendSafe("r")
    }

    _fastForward() {
        if (this.fastForwarding) {
            Send("{Tab up}")
        }
        else {
            Send("{Tab down}")
        }
    }
}