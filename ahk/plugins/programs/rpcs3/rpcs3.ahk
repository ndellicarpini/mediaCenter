class RPCS3Emulator extends Emulator {
    _fullscreen() {
        Send("{Alt down}")
        SendSafe("{Enter}")
        Send("{Alt up}")
    }

    ; _getWNDW() {
    ;     try {
    ;         restoreDHW := A_DetectHiddenWindows
    ;         DetectHiddenWindows(this.background)

    ;         retVal := ""
    ;         for item in WinGetList("ahk_exe " this.exe) {
    ;             if (WinShown("ahk_id " item) && (this.background || (!this.background && WinActivatable("ahk_id " item))) 
    ;                 && InStr(WinGetTitle("ahk_id " item), "FPS:")) {
                    
    ;                 retVal := "ahk_id " item
    ;                 break
    ;             }
    ;         }

    ;         DetectHiddenWindows(restoreDHW)
    ;         return retVal
    ;     }

    ;     return ""
    ; }

    _pause() {
        Send("{Ctrl down}")
        SendSafe("p")
        Send("{Ctrl up}")
    }

    _resume() {
        this._pause()
    }
}