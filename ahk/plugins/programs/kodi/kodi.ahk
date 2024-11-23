class KodiProgram extends Program {
    _fullscreen() {
        this.send("\")
    }

    ; custom function
    reload() {
        restoreCritical := A_IsCritical
        Critical("On")

        this.exit(false)
        Sleep(500)
        this.launch(ObjDeepClone(this._launchArgs))

        Critical(restoreCritical)
    }
}