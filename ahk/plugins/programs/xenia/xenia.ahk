class XeniaEmulator extends Emulator {      
    _fullscreen() {
        this.send("{F11}")
    }

    _pause() {
        ProcessSuspend(this.getPID())
    }

    _resume() {
        ProcessResume(this.getPID())
    }
}