class RyujinxEmulator extends Emulator {
    _fullscreen() {
        this.send("{Alt down}")
        this.send("{Enter}")
        this.send("{Alt up}")
    }

    _pause() {
        this.send("{F5}", 150)
    }

    _resume() {
        this._pause()
    }
}