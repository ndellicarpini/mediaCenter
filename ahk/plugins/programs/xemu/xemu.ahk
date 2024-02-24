class XemuEmulator extends Emulator {
    _fullscreen() {
        this.send("{Ctrl down}")
        this.send("{Alt down}")
        this.send("f")
        this.send("{Alt up}")
        this.send("{Ctrl up}")
    }

    _pause() {
        this.send("{Ctrl down}")
        this.send("p", 150)
        this.send("{Ctrl up}")
    }

    _resume() {
        this._pause()

        Sleep(100)
        this.send("{Escape}")
    }

    _reset() {
        this.send("{Ctrl down}")
        this.send("r")
        this.send("{Ctrl up}")
    }
}