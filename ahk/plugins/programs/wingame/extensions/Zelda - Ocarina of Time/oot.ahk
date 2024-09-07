class HarkinianProgram extends WinGameProgram {
    _launch(game, args*) {
        startDelfinovin()
        super._launch(game, args*)
    }

    _postExit() {
        stopDelfinovin()
    }

    _fullscreen() {
        this.send("{F11}")
    }

    saveState() {
        this.send("{F5}")
    }

    loadState() {
        this.send("{F7}")
    }

    reset() {
        this.send("{Ctrl down}")
        this.send("r")
        this.send("{Ctrl up}")
    }
}
