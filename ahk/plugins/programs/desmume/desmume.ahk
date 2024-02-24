class DeSmuMEEmulator extends Emulator {
    _fullscreen() {
        this.send("{Alt down}")
        this.send("{Enter}")
        this.send("{Alt up}")
    }

    _pause() {
        this.send("{Pause}", 150)
    }

    _resume() {
        this._pause()
    }
    
    _saveState(slot) {
        this.send("{Shift down}")
        this.send("{F1}")
        this.send("{Shift up}")
    }

    _loadState(slot) {
        this.send("{F1}")
    }

    _reset() {
        this.send("{Ctrl down}")
        this.send("r")
        this.send("{Ctrl up}")
    }

    _fastForward() {
        if (this.fastForwarding) {
            this.send("{Tab up}")
        }
        else {
            this.send("{Tab down}")
        }
    }

    ; custom function
    swapScreens() {
        this.send("{PgDn}")
    }

    ; custom function
    layoutScreens() {
        this.send("{End}")
    }
}