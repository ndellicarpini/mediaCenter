class CemuEmulator extends Emulator {
    _fullscreen() {
        this.send("{Alt down}")
        this.send("{Enter}")
        this.send("{Alt up}")
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