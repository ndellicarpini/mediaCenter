class KodiProgram extends Program {
    _fullscreen() {
        this.send("\")
    }

    ; custom function
    reload() {
        this.exit()
        Sleep(500)
    }
}