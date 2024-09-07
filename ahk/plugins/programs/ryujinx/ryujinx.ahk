class RyujinxEmulator extends Emulator {
    _launch(rom, args*) {
        if (InStr(StrLower(rom), "super smash bros")) {
            startDelfinovin()
        }

        super._launch(rom, args*)
    }

    _postExit() {
        stopDelfinovin()
    }

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