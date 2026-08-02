class MelonDSEmulator extends Emulator {
    _fullscreen() {
        this.send("{F11}")
    }

    _pause() {
        this.send("p")
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
        this.send("r")
    }

    _fastForward() {
        this.send("{Space}")
    }

    ; custom function
    swapScreenPos() {
        this.send("n")
    }

    ; custom function
    swapScreenSize() {
        this.send("m")
    }
}