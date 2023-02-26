class PPSSPPEmulator extends Emulator {
    _fullscreen() {
        Send("{Alt down}")
        SendSafe("{Enter}")
        Send("{Alt up}")
    }

    _pause() {
        SendSafe("{Escape}", 120)
    }

    _resume() {
        this._pause()
    }
    
    _saveState(slot) {
        SendSafe("{F1}")
    }

    _loadState(slot) {
        SendSafe("{F3}")
    }

    _reset() {
        Send("{Ctrl down}")
        SendSafe("b")
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
}