class DeSmuMEEmulator extends Emulator {
    _fullscreen() {
        Send("{Alt down}")
        SendSafe("{Enter}")
        Send("{Alt up}")
    }

    _pause() {
        SendSafe("{Pause}")
    }

    _resume() {
        this._pause()
    }
    
    _saveState(slot) {
        Send("{Shift down}")
        SendSafe("{F1}")
        Send("{Shift up}")
    }

    _loadState(slot) {
        SendSafe("{F1}")
    }

    _reset() {
        Send("{Ctrl down}")
        SendSafe("r")
        Send("{Ctrl up}")
    }

    _fastForward() {
        if (this.fastForwarding) {
            Send("{Tab up}")
        }
        else {
            Send("{Tab down}")
        }
    }

    ; custom function
    swapScreens() {
        SendSafe("{PgDn}")
    }

    ; custom function
    layoutScreens() {
        SendSafe("{End}")
    }
}