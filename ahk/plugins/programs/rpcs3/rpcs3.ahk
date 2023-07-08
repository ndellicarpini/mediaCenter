class RPCS3Emulator extends Emulator {
    _fullscreen() {
        Send("{Alt down}")
        SendSafe("{Enter}")
        Send("{Alt up}")
    }
    
    _pause() {
        Send("{Ctrl down}")
        SendSafe("p")
        Send("{Ctrl up}")
    }

    _resume() {
        this._pause()
    }
}