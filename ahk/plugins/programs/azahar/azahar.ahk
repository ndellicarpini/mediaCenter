class AzaharEmulator extends Emulator {
    _fullscreen() {
        this.send("{F11}")
    }

    _pause() {
        this.send("{F4}", 150)
    }

    _resume() {
        this._pause()
    }
    
    _saveState(slot) {
        this.send("{Ctrl down}")
        this.send("c")
        this.send("{Ctrl up}")
    }

    _loadState(slot) {
        this.send("{Ctrl down}")
        this.send("v")
        this.send("{Ctrl up}")
    }

    _reset() {
        this.send("{F6}")
    }

    _fastForward() {
         if (this.fastForwarding) {
            loop 40 {
                this.send("-")
            }
        }
        else {
            loop 40 {
                this.send("{Shift down}")
                this.send("=")
                this.send("{Shift up}")
            }
        }
    }

    ; custom function
    swapScreens() {
        this.send("{F9}")
    }

    ; custom function
    layoutScreens() {
        this.send("{F10}")
    }
}