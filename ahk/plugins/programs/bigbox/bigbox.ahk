class BigBoxProgram extends Program {
    _restore() {
        restoreTTM := A_TitleMatchMode
        SetTitleMatchMode(3)

        if (WinShown("LaunchBox Game Startup")) {
            WinActivate("LaunchBox Game Startup")

            SetTitleMatchMode(restoreTTM)
            return
        }

        SetTitleMatchMode(restoreTTM)
        super._restore()
    }
}