class AmazonGameProgram extends Program {
    _launch(URI, args*) {
        global globalStatus

        Run(RTrim(URI . A_Space . joinArray(args), A_Space))
        
        restoreLoadText := globalStatus["loadscreen"]["text"]
        setLoadScreen("Waiting for Amazon Games...")
        
        restoreTMM := A_TitleMatchMode
        SetTitleMatchMode(2)
    
        restoreAllowExit := this.allowExit
        this.allowExit   := true
    
        globalStatus["loadscreen"]["overrideWNDW"] := "Amazon Games"

        count := 0
        maxCount := 40
        ; wait for amazon to show
        while (!this.exists() && count < maxCount) {
            if (WinShown("Amazon Games")) {            
                count := 0
            }
    
            if (this.shouldExit) {
                globalStatus["loadscreen"]["overrideWNDW"] := ""
                SetTitleMatchMode(restoreTMM)

                this.postExit()
                return false
            }
    
            count += 1
            Sleep(500)
        }
    
        setLoadScreen(restoreLoadText)
        SetTitleMatchMode(restoreTMM)

        this.allowExit := restoreAllowExit
        globalStatus["loadscreen"]["overrideWNDW"] := ""
    }

    ; close amazon game launcher after game exits
    _postExit() {
        count := 0
        maxCount := 100
        ; wait for amazon game launcher to show
        while (!WinShown("Amazon Games") && count < maxCount) {
            count += 1
            Sleep(100)
        }

        count := 0
        maxCount := 20
        ; try to close amazon game launcher while open
        while (WinShown("Amazon Games") && count < maxCount) {
            WinActivate("Amazon Games")
            Sleep(100)
            WinClose("Amazon Games")

            count += 1
            Sleep(500)
        }

        if (ProcessExist("Amazon Games.exe") && count >= maxCount) {
            ProcessClose("Amazon Games.exe")
        }
    }
}