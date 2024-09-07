class RockstarProgram extends SteamGameProgram {
    _launch(game, args*) {
        global globalStatus

        if (super._launch(game, args*) = false) {
            return false
        }

        restoreAllowExit := this.allowExit
        this.allowExit   := true

        count := 0
        maxCount := 20
        while (!ProcessExist("SocialClubHelper.exe") && !ProcessExist("Launcher.exe") && !ProcessExist("RockstarService.exe") && count < maxCount) {
            count += 1
            Sleep(500)
        }

        count := 0
        maxCount := 40
        ; wait for ea to show
        while (!this.exists() && count < maxCount) {
            if (WinShown("ahk_exe SocialClubHelper.exe")) {
                globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe SocialClubHelper.exe"
            }
            else if (WinShown("ahk_exe Launcher.exe")) {
                globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe Launcher.exe"
            }
    
            if (this.shouldExit) {
                globalStatus["loadscreen"]["overrideWNDW"] := ""                
                return false
            }
    
            if (!ProcessExist("SocialClubHelper.exe") && !ProcessExist("Launcher.exe") && !ProcessExist("RockstarService.exe")) {
                count += 1
            }
            else {
                count := 0
            }

            Sleep(500)
        }

        this.allowExit := restoreAllowExit
        globalStatus["loadscreen"]["overrideWNDW"] := ""
    }

    _postExit() {
        count := 0
        maxCount := 100
        while (!WinShown("ahk_exe Launcher.exe") && !WinShown("ahk_exe SocialClubHelper.exe") && ProcessExist("Launcher.exe") && count < maxCount) {
            count += 1
            Sleep(500)
        }

        if (WinShown("ahk_exe SocialClubHelper.exe")) {
            WinClose("ahk_exe SocialClubHelper.exe")
            Sleep(500)
        } 
        else if (WinShown("ahk_exe Launcher.exe")) {
            WinClose("ahk_exe Launcher.exe")
            Sleep(500)
        }
    }
}