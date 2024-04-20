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
        this.send("{Alt down}")
        this.send("{Enter}")
        this.send("{Alt up}")
    }

    _pause() {
        this.send("{Space}", 150)
    }

    _resume() {
        this._pause()
    }
    
    _saveState(slot) {
        this.send("{F1}")
    }

    _loadState(slot) {
        this.send("{F3}")
    }

    _reset() {
        this.send("r")
    }

    _fastForward() {
        this.send("{Tab}", 120)
    }
}