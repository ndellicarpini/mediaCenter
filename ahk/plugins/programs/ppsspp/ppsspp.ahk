class PPSSPPEmulator extends Emulator {
    _fullscreen() {
        this.send("{Alt down}")
        this.send("{Enter}")
        this.send("{Alt up}")
    }

    _pause() {
        this.send("{Escape}", 120)
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
        this.send("{Ctrl down}")
        this.send("b")
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
}