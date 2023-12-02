class CannonballProgram extends SteamGameProgram {
    _restore() {
        try {
            restoreTTM := A_TitleMatchMode
            SetTitleMatchMode(3)

            retVal := true
            ; for some reason the launcher cmd is the real exe?
            if (!WinActive("Cannonball")) {
                retVal := WinActivateForeground("Cannonball")
            }

            SetTitleMatchMode(restoreTTM)
            return retVal
        }
    }
}