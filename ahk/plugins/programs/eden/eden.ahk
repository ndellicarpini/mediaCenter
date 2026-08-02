class EdenEmulator extends Emulator {
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
        this.send("{F11}")
    }

    _pause() {
        this.send("{F4}", 150)
    }

    _resume() {
        this._pause()
    }
}