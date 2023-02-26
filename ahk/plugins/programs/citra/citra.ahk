class CitraEmulator extends Emulator {
    _fullscreen() {
        SendSafe("{F11}")
    }

    _pause() {
        SendSafe("{F4}")
    }

    _resume() {
        this._pause()
    }
    
    _saveState(slot) {
        Send("{Ctrl down}")
        SendSafe("c")
        Send("{Ctrl up}")
    }

    _loadState(slot) {
        Send("{Ctrl down}")
        SendSafe("v")
        Send("{Ctrl up}")
    }

    _reset() {
        SendSafe("{F6}")
    }

    _fastForward() {
        Send("{Ctrl down}")
        SendSafe("z")
        Send("{Ctrl up}")
    }

    ; custom function
    swapScreens() {
        SendSafe("{F9}")
    }

    ; custom function
    layoutScreens() {
        SendSafe("{F10}")
    }
}