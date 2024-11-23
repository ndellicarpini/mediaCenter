class SteamUbisoftProgram extends SteamGameProgram {
    _launch(args*) {
        global globalStatus

        restoreLoadText := globalStatus["loadscreen"]["text"]
        setLoadScreen("Waiting for Ubisoft Games...")
        
        restoreTMM := A_TitleMatchMode
        SetTitleMatchMode(2)
        
        globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe EALauncher.exe"
        restoreAllowExit := this.allowExit
        this.allowExit := true

        ubisoftArr  := StrSplit(this.ubisoftConnectEXE, "\")
        ubisoftEXE  := ubisoftArr.RemoveAt(ubisoftArr.Length)
        ubisoftPath := LTrim(joinArray(ubisoftArr, "\"), '"' . '"')

        RunAsUser(ubisoftEXE,, ubisoftPath)

        count := 0
        maxCount := 10
        ; wait for base Ubisoft Launcher exe
        while (!ProcessExist("upc.exe") && count < maxCount) {
            if (this.shouldExit) {
                return false
            }

            count += 1
            Sleep(500)
        }
    
        count := 0
        maxCount := 10
        ; wait for base Ubisoft Web Core (which is needed to launch games?)
        while (!ProcessExist("UbisoftWebCore.exe") && !ProcessExist("UplayWebCore.exe") && count < maxCount) {
            if (this.shouldExit) {
                return false
            }

            count += 1
            Sleep(500)
        }
    
        count := 0
        maxCount := 10
        ; buffer
        while (count < maxCount) {
            if (this.shouldExit) {
                return false
            }

            count += 1
            Sleep(500)
        }

        setLoadScreen(restoreLoadText)
        SetTitleMatchMode(restoreTMM)

        this.allowExit := restoreAllowExit
        globalStatus["loadscreen"]["overrideWNDW"] := ""
        
        return super._launch(args*)
    }

    _postExit() {
        count := 0
        maxCount := 20
        ; wait for ubisoft to show
        while (!WinShown("ahk_exe upc.exe") && count < maxCount) {
            count += 1
            Sleep(500)
        }
    
        WinClose("ahk_exe upc.exe")

        count := 0
        maxCount := 20
        ; try to close ubisoft while open
        while (ProcessExist("ahk_exe upc.exe") && count < maxCount) {
            count += 1
            Sleep(500)
        }
    
        ; take drastic measures if ubisoft remains
        if (ProcessExist("upc.exe") && count >= maxCount) {
            ProcessClose("upc.exe")
        }
    }
}