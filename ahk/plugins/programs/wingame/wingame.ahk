; --- DEFAULT WINDOWS GAME ---
class WinGameProgram extends Program {
    _launch(game, args*) {
        try {
            pathArr := StrSplit(game, "\")
        
            exe := pathArr.RemoveAt(pathArr.Length)
            path := LTrim(joinArray(pathArr, "\"), '"' . '"')
        
            Run(RTrim(game . " " . joinArray(args), A_Space), path)
        }
        catch {
            return false
        }
    }
}

; --- WINDOWS GAME W/ REQUIRED LAUNCHER TO SKIP ---
class WinGameProgramWithLauncher extends WinGameProgram {
    _launcherEXE      := ""   ; exe of launcher application
    _launcherMousePos := []   ; array of positions to click as a double array
    _launcherDelay    := 1000 ; delay before clicking
    
    _launch(game, args*) {
        global globalStatus

        if (super._launch(game, args*) = false) {
            return false
        }

        if (this._launcherEXE = "") {
            return
        }

        restoreAllowExit := this.allowExit
        this.allowExit   := true

        ; wait for executable
        while (!WinShown("ahk_exe " this._launcherEXE)) {
            if (this.exists()) {
                return
            }
            else if (this.shouldExit) {
                return false
            }

            Sleep(100)
        }

        ; flatten double array
        mouseArr := []
        loop this._launcherMousePos.Length {
            if (Type(this._launcherMousePos[A_Index]) = "Array") {
                currIndex := A_Index
                loop this._launcherMousePos[currIndex].Length {
                    mouseArr.Push(this._launcherMousePos[currIndex][A_Index])
                }
            }
            else {
                mouseArr.Push(this._launcherMousePos[A_Index])
            }
        }

        globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe " this._launcherEXE

        ; try to skip launcher as long as exectuable is shown
        while (WinShown("ahk_exe " this._launcherEXE)) {
            if (this.exists()) {
                return
            }
            else if (this.shouldExit) {
                return false
            }

            loop (mouseArr.Length / 2) {
                index := ((A_Index - 1) * 2) + 1

                Sleep(this._launcherDelay)

                if (this.exists() || !WinShown("ahk_exe " this._launcherEXE)) {
                    return
                }
                else if (this.shouldExit) {
                    return false
                }

                MouseClick("Left"
                    , percentWidthRelativeWndw(mouseArr[index], "ahk_exe " this._launcherEXE)
                    , percentHeightRelativeWndw(mouseArr[index + 1], "ahk_exe " this._launcherEXE)
                    ,,, "D"
                )
                Sleep(75)
                MouseClick("Left",,,,, "U")
                Sleep(75)
                MouseMove(percentWidth(1), percentHeight(1))    
            }
        }

        this.allowExit := restoreAllowExit
        globalStatus["loadscreen"]["overrideWNDW"] := ""
    }

    ; dank ass bad practice
    exit() {
        if (this._launcherEXE != "" && ProcessExist(this._launcherEXE)) {
            ProcessClose(this._launcherEXE)
        }

        super.exit()
    }    
}

; --- OVERRIDES --- 
class MBAAProgram extends WinGameProgram {
    _postLaunchDelay := 500

    _postLaunch() {
        SendSafe("{Enter}")
    }
}

class TestDriveUnlimitedProgram extends WinGameProgram {
    _mouseMoveDelay := 18000
}

class MorrowindProgram extends WinGameProgram {
    _mouseMoveDelay := 5000
}

class HarkinianProgram extends WinGameProgram {
    _launch(game, args*) {
        pathArr := StrSplit(game, "\")
        
        exe := pathArr.RemoveAt(pathArr.Length)
        path := LTrim(joinArray(pathArr, "\"), '"' . "'")

        gcnAdapterPath := path . "\GCN XInput Adapter"

        if (DirExist(gcnAdapterPath)) {
            Run('"' . gcnAdapterPath .  "\DelfinovinUI.exe" . '"', gcnAdapterPath)

            count := 0
            maxCount := 100
            while (!WinShown("MainWindow") && count < maxCount) {
                Sleep(100)
                count += 1
            }
    
            if (count < maxCount) {
                Sleep(2000)
            }
            else {
                return false
            }
        }

        super._launch(game, args*)
    }

    _postExit() {
        count := 0
        maxCount := 5
        while (ProcessExist("DelfinovinUI.exe") && count < maxCount) {
            if (WinShown("MainWindow")) {
                WinActivate("MainWindow")
                Sleep(75)

                MouseClick("Left"
                    , percentWidthRelativeWndw(0.96, "MainWindow")
                    , percentHeightRelativeWndw(0.04, "MainWindow")
                    ,,, "D"
                )
                Sleep(75)
                MouseClick("Left",,,,, "U")
                Sleep(75)
                MouseMove(percentWidth(1), percentHeight(1))    
            }

            Sleep(3000)
            count += 1
        }
    }

    _fullscreen() {
        SendSafe("!{Enter}")
    }

    saveState() {
        SendSafe("{F5}")
    }

    loadState() {
        SendSafe("{F7}")
    }

    reset() {
        Send("{Ctrl down}")
        SendSafe("r")
        Send("{Ctrl up}")
    }
}

; --- OVERRIDES W/ LAUNCHERS --- 
class GTA5Program extends WinGameProgramWithLauncher {
    _launcherEXE := "Launcher.exe"

    _postExit() {
        count := 0
        maxCount := 100
        while (!WinShown("ahk_exe " this._launcherEXE) && count < maxCount) {
            count += 1
            Sleep(100)
        }

        if (WinShown("ahk_exe " this._launcherEXE)) {
            WinClose("ahk_exe " this._launcherEXE)
            Sleep(500)
        }
    }
}