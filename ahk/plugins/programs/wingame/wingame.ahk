; --- DEFAULT WINDOWS GAME ---
class WinGameProgram extends Program {
    _launch(args*) {
        try {
            cleanArgs := ObjDeepClone(args)

            ; re-orders the default args to be after the program filepath
            ; that way the filepath is always the first arg
            if (this.defaultArgs.Length > 0) {
                toReorder := []
                ; parse args
                loop args.Length {
                    if (inArray(args[A_Index], this.defaultArgs)) {
                        toReorder.Push(A_Index)
                    }
                }
                
                tempArgs := []
                loop toReorder.Length {
                    tempArgs.Push(cleanArgs.RemoveAt(toReorder[toReorder.Length - (A_Index - 1)]))
                }

                loop tempArgs.Length {
                    cleanArgs.InsertAt(2, tempArgs[A_Index])
                }
            }

            game := cleanArgs.RemoveAt(1)
            pathArr := StrSplit(game, "\")
        
            exe := pathArr.RemoveAt(pathArr.Length)
            path := LTrim(joinArray(pathArr, "\"), '"' . '"')
        
            RunAsUser(game, cleanArgs, path)
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