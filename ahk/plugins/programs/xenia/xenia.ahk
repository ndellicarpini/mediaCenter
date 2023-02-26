class XeniaEmulator extends Emulator {      
    _fullscreen() {
        SendSafe("{F11}")
    }

    _pause() {
        ProcessSuspend(this.getPID())
    }

    _resume() {
        ProcessResume(this.getPID())
    }
}