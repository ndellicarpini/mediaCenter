class Zelda64RecompiledProgram extends WinGameProgram {
    _launch(game, args*) {
        startDelfinovin()
        super._launch(game, args*)
    }

    _postExit() {
        stopDelfinovin()
    }
}
