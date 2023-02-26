class CemuEmulator extends Emulator {
    _fullscreen() {
        Send("{Alt down}")
        SendSafe("{Enter}")
        Send("{Alt up}")
    }

    _pause() {
        this.fullscreen()
        Sleep(100)

        ProcessSuspend(this.getPID())
    }

    _resume() {
        ProcessResume(this.getPID())

        Sleep(100)
        this.fullscreen()
    }
}