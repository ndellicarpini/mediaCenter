class XemuEmulator extends Emulator {
    _fullscreen() {
        Send("{Ctrl down}")
        Send("{Alt down}")
        SendSafe("f")
        Send("{Alt up}")
        Send("{Ctrl up}")
    }

    _pause() {
        Send("{Ctrl down}")
        SendSafe("p")
        Send("{Ctrl up}")
    }

    _resume() {
        this._pause()

        Sleep(85)
        SendSafe("{Escape}")
    }

    _reset() {
        Send("{Ctrl down}")
        SendSafe("r")
        Send("{Ctrl up}")
    }
}