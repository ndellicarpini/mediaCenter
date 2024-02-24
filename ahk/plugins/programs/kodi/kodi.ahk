class KodiProgram extends Program {
    _fullscreen() {
        this.send("\")
    }

    ; custom function
    reload() {
        this.exit(false)
        Sleep(500)
        this.launch(ObjDeepClone(this._launchArgs))
    }
}