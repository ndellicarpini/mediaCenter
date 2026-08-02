class RPCS3Emulator extends Emulator {
    _fullscreen() {
        this.send("{Alt down}")
        this.send("{Enter}")
        this.send("{Alt up}")
    }
    
    _pause() {
        this.send("{Ctrl down}")
        this.send("p", 150)
        this.send("{Ctrl up}")
    }

    _resume() {
        this._pause()
    }

    ; custom function
    menu() {
        Sleep(50)
        this.send("{Shift down}")
        this.send("{F10}", 150)
        this.send("{Shift up}")
    }
}