class RyujinxEmulator extends Emulator {
    _fullscreen() {
        Send("{Alt down}")
        SendSafe("{Enter}")
        Send("{Alt up}")
    }

    _pause() {
        SendSafe("{F5}")
    }

    _resume() {
        this._pause()
    }
}