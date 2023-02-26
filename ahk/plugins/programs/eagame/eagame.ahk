class EAGameProgram extends Program {
    _launch(game, args*) {
        pathArr := StrSplit(game, "\")
    
        exe := pathArr.RemoveAt(pathArr.Length)
        path := LTrim(joinArray(pathArr, "\"), '"' . "'")
    
        Run(RTrim(game . A_Space . joinArray(args), A_Space), path)

        restoreLoadText := globalStatus["loadscreen"]["text"]
        setLoadScreen("Waiting for EA Games...")
        
        restoreTMM := A_TitleMatchMode
        SetTitleMatchMode(2)
    
        restoreAllowExit := this.allowExit
        this.allowExit := true
    
        count := 0
        maxCount := 40
        ; wait for ea to show
        while (!this.exists() && count < maxCount) {
            if (ProcessExist("EALauncher.exe")) {
                globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe EALauncher.exe"
                count := 0
            }
            else if (ProcessExist("EALaunchHelper.exe")) {
                globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe EALaunchHelper.exe"
                count := 0
            }
            else if (ProcessExist("EADesktop.exe")) {
                globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe EADesktop.exe"
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

    _postExit() {
        count := 0
        maxCount := 100
        ; wait for ea to show
        while (!WinShown("ahk_exe EADesktop.exe") && count < maxCount) {
            count += 1
            Sleep(100)
        }
    
        count := 0
        maxCount := 20
        ; try to close ea while open
        while (WinShown("ahk_exe EADesktop.exe") && count < maxCount) {
            WinActivate("ahk_exe EADesktop.exe")
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

class Madden19Program extends EAGameProgram {
    _postLaunchDelay := 1500
    _mouseMoveDelay  := 20000

    _postLaunch() {
        SendSafe("{Enter}")
    }
}