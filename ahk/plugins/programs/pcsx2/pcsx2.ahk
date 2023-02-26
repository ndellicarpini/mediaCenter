class PCSX2Emulator extends Emulator {
    ; _exit() {
    ;     hwnd := this.getWNDW()
    ;     if (wndw != "") {
    ;         WinClose(wndw)
    ;     }

    ;     Sleep(100)

    ;     wndw := this.getWNDW()
    ;     if (wndw != "") {
    ;         WinClose(wndw)
    ;     }
    ; }

    _fullscreen() {
        Send("{Alt down}")
        SendSafe("{Enter}")
        Send("{Alt up}")
    }

    _pause() {
        SendSafe("{Space}")
    }

    _resume() {
        this._pause()
    }
    
    _saveState(slot) {
        SendSafe("{F1}")
    }

    _loadState(slot) {
        SendSafe("{F3}")
    }

    _reset() {
        SendSafe("r")
    }

    _fastForward() {
        SendSafe("{Tab}", 120)
    }
}