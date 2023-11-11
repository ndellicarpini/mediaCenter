class RPCS3Emulator extends Emulator {
    _fullscreen() {
        this.send("{Alt down}")
        this.send("{Enter}")
        this.send("{Alt up}")
    }
    
    _pause() {
        this.send("{Ctrl down}")
        this.send("p")
        this.send("{Ctrl up}")
    }

    _resume() {
        this._pause()
    }
}