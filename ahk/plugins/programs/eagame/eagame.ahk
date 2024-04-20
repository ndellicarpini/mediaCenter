class EAGameProgram extends WinGameProgram {
    _launch(args*) {
        global globalStatus
        
        if (super._launch(args*) = false) {
            return false
        }

        restoreLoadText := globalStatus["loadscreen"]["text"]
        setLoadScreen("Waiting for EA Games...")
        
        restoreTMM := A_TitleMatchMode
        SetTitleMatchMode(2)
    
        restoreAllowExit := this.allowExit
        this.allowExit := true

        count := 0
        maxCount := 20
        while (!ProcessExist("EALauncher.exe") && !ProcessExist("EALaunchHelper.exe") 
            && !ProcessExist("EADesktop.exe") && !ProcessExist("EABackgroundService.exe") && count < maxCount) {
            count += 1
            Sleep(500)
        }
    
        count := 0
        maxCount := 40
        ; wait for ea to show
        while (!this.exists() && count < maxCount) {
            if (WinShown("ahk_exe EALauncher.exe")) {
                globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe EALauncher.exe"
            }
            else if (WinShown("ahk_exe EALaunchHelper.exe")) {
                globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe EALaunchHelper.exe"
            }
            else if (WinShown("ahk_exe EADesktop.exe")) {
                globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe EADesktop.exe"
            }
    
            if (this.shouldExit) {
                globalStatus["loadscreen"]["overrideWNDW"] := ""
                SetTitleMatchMode(restoreTMM)
                
                return false
            }
    
            if (!ProcessExist("EALauncher.exe") && !ProcessExist("EALaunchHelper.exe") 
                && !ProcessExist("EADesktop.exe") && !ProcessExist("EABackgroundService.exe")) {
                
                count += 1
            }
            else {
                count := 0
            }

            Sleep(500)
        }
    
        setLoadScreen(restoreLoadText)
        SetTitleMatchMode(restoreTMM)

        this.allowExit := restoreAllowExit
        globalStatus["loadscreen"]["overrideWNDW"] := ""
    }

    _postExit() {
        count := 0
        maxCount := 100
        ; wait for ea to show
        while (!WinShown("ahk_exe EADesktop.exe") && count < maxCount) {
            count += 1
            Sleep(500)
        }
    
        count := 0
        maxCount := 20
        ; try to close ea while open
        while (WinShown("ahk_exe EADesktop.exe") && count < maxCount) {
            WinActivateForeground("ahk_exe EADesktop.exe")
            Sleep(100)
    
            SendSafe("{Alt}")
            Sleep(50)
            SendSafe("{Up}")
            Sleep(50)
            SendSafe("{Enter}")
    
            count += 1
            Sleep(500)
        }
    
        ; take drastic measures if ea remains
        if (ProcessExist("EADesktop.exe") && count >= maxCount) {
            ProcessClose("EADesktop.exe")
        }

        ProcessClose("EABackgroundService.exe")
    }
}