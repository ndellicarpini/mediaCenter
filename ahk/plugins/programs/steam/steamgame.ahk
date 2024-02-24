; --- DEFAULT STEAM APP ---
class SteamGameProgram extends Program {
    _launch(args*) {
        cleanArgs := ObjDeepClone(args)
        URI := ""

        ; parse args
        loop cleanArgs.Length {
            if (StrLower(SubStr(cleanArgs[A_Index], 1, 8)) = "steam://") {
                URI := cleanArgs.RemoveAt(A_Index)
                break
            }
        }

        ; add // to end of URI for launch args to work (like wtf valve)
        if (SubStr(URI, -2) != "//") {
            URI := RTrim(URI, "/ ") . "//"
        }

        ; checks for common steam windows
        steamShown() {
            for wndw in WinGetList("ahk_exe steamwebhelper.exe") {
                if (!WinShown(wndw)) {
                    continue
                }

                title := WinGetTitle(wndw)
                if (title = "Steam" || title = "Launching...") {
                    return true
                }
            }

            return false
        }
    
        ; checks if the eula is open & accepts it
        checkDialogs() {
            for wndw in WinGetList("ahk_exe steamwebhelper.exe") {
                if (!WinShown(wndw)) {
                    continue
                }

                if (WinGetTitle(wndw) = "Steam") {
                    minSize := WinGetMinSize(wndw)
                    WinMove(,, minSize[1], minSize[2])
                    Sleep(250)
               
                    WinActivateForeground(wndw)
                    Sleep(250)
                    
                    MouseClick("Left"
                        , percentWidthRelativeWndw(0.6, wndw)
                        , percentHeightRelativeWndw(0.85, wndw)
                        ,,, "D"
                    )
                    Sleep(75)
                    MouseClick("Left",,,,, "U")
                    Sleep(75)
                    MouseMove(percentWidth(1), percentHeight(1))
    
                    Sleep(250)
    
                    WinClose(wndw)

                    return
                }
            }
        }

        ; skips all steam dialogs and launches the game
        launchHandler(game, loopCount := 0) {
            global globalStatus
            global globalRunning

            restoreAllowExit := this.allowExit
            restoreLoadText  := globalStatus["loadscreen"]["text"]
        
            ; launch steam if it doesn't exist
            if (!globalRunning.Has("steam") || !globalRunning["steam"].exists()) {
                if (!globalRunning.Has("steam")) {
                    createProgram("steam", true, false)
                }
                else if (!globalRunning["steam"].exists()) {
                    globalRunning["steam"].launch()
                }
            
                ; has carriage return to avoid getting overwritten by previous resetLoadscreen
                ; (resetLoadscreen does a simple check if old text = new text before delayed overwrite)
                setLoadScreen("Waiting for Steam...`r")
        
                this.allowExit := true
                
                count := 0
                maxCount := 150
                ; buffer wait for steam so that the URI works
                while (count < maxCount) {
                    if (this.shouldExit) {    
                        return false
                    }
        
                    count += 1
                    Sleep(100)
                }
        
                this.allowExit := false
            }
            
            setLoadScreen("Waiting for Steam...")
        
            restoreTTMM := A_TitleMatchMode
            SetTitleMatchMode(2)

            ; check that steam window isn't already open
            for wndw in WinGetList("ahk_exe steamwebhelper.exe") {
                if (WinShown(wndw) && WinGetTitle(wndw) = "Steam") {
                    WinClose(wndw)
                    
                    Sleep(500)
                    break
                }
            }

            try {
                RunAsUser(game, cleanArgs)
            }
            catch {
                SetTitleMatchMode(restoreTTMM)
                return false
            }
        
            count := 0
            maxCount := 40
            ; wait for either the game or a common steam window
            while (count < maxCount && !steamShown() && !this.exists()) {
                if (count > 25 && this.shouldExit) {    
                    SetTitleMatchMode(restoreTTMM)
                    return false
                }
        
                count += 1
                Sleep(500)
            }
        
            ; if game -> success
            if (this.exists()) {
                this.allowExit := restoreAllowExit
                SetTitleMatchMode(restoreTTMM)
        
                return
            }
        
            ; if no steam windows shown -> restart steam
            if (!steamShown()) {
                if (loopCount > 2) {
                    SetTitleMatchMode(restoreTTMM)
                    return false
                }
        
                globalRunning["steam"].exit(false)
                
                Sleep(1000)
                return launchHandler(game, loopCount + 1)
            }
        
            globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe steamwebhelper.exe"
            this.allowExit := true
        
            firstShown := false
            ; while launching window is shown, just wait
            while (steamShown()) {
                if (this.exists()) {
                    break
                }

                if (this.shouldExit) { 
                    count := 0
                    maxCount := 20
                    while (WinShown("ahk_exe steamwebhelper.exe") && count < maxCount) {
                        WinClose("ahk_exe steamwebhelper.exe")
                        Sleep(500)
                    }

                    globalStatus["loadscreen"]["overrideWNDW"] := ""
                    SetTitleMatchMode(restoreTTMM)
        
                    return false
                }

                if (!firstShown) {
                    for wndw in WinGetList("ahk_exe steamwebhelper.exe") {
                        if (!WinShown(wndw)) {
                            continue
                        }
        
                        if (WinGetTitle(wndw) = "Launching...") {
                            count := 0
                            maxCount := 10
                            while (count < maxCount) {
                                if (this.exists()) {
                                    firstShown := true
                                    break
                                }

                                count += 1
                                Sleep(100)
                            }
                            
                            ; need to flash alternate window in order to fix stupid steam black screen
                            ; why is everything chromium?
                            if (count = maxCount && WinShown(INTERFACES["loadscreen"]["wndw"]) && WinShown(wndw)) {
                                activateLoadScreen()
                                Sleep(80)
                                WinActivateForeground(wndw)
            
                                firstShown := true
                            }
                        }

                        if (firstShown) {
                            break
                        }
                    }
                }

                checkDialogs()
                Sleep(250)
            }
        
            globalStatus["loadscreen"]["overrideWNDW"] := ""
            this.allowExit := restoreAllowExit
            SetTitleMatchMode(restoreTTMM)
            setLoadScreen(restoreLoadText)
        
            return
        }

        return launchHandler(URI)
    }

    ; custom function
    menu() {
        MouseMove(percentWidth(1, false), percentHeight(1, false))

        SetTimer(OpenMenu.Bind(0), Neg(100))
        return

        OpenMenu(loopCount) {
            if (loopCount > 100) {
                return
            }

            if (WinGetID("A") = this.getHWND()) {
                this.send("{Shift down}")
                Sleep(100)
                this.send("{Tab}")
                Sleep(100)
                this.send("{Shift up}")
        
                Sleep(100)
                MouseMove(percentWidth(1), percentHeight(1))
                return
            }

            SetTimer(OpenMenu.Bind(loopCount + 1), Neg(100))
            return
        }
    }
}

; --- STEAM APPS W/ REQUIRED LAUNCHER TO SKIP ---
class SteamGameProgramWithLauncher extends SteamGameProgram {
    _launcherEXE      := ""   ; exe of launcher application
    _launcherMousePos := []   ; array of positions to click as a double array
    _launcherDelay    := 1000 ; delay before clicking
    
    _launch(URI, args*) {
        global globalStatus

        if (super._launch(URI, args*) = false) {
            return false
        }

        if (this._launcherEXE = "") {
            return
        }

        restoreAllowExit := this.allowExit
        this.allowExit   := true

        count := 0
        maxCount := 30
        ; wait for executable
        while (!WinShown("ahk_exe " this._launcherEXE) && count < maxCount) {
            if (this.exists()) {
                return
            }
            else if (this.shouldExit) {
                return false
            }

            Sleep(100)
            count += 1
        }

        if (count >= maxCount) {
            return false
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

        hiddenCount := 0
        maxCount := 3
        ; try to skip launcher as long as exectuable is shown
        while (hiddenCount < maxCount) {
            if (this.exists()) {
                this.allowExit := restoreAllowExit
                globalStatus["loadscreen"]["overrideWNDW"] := ""

                return
            }
            else if (this.shouldExit) {
                globalStatus["loadscreen"]["overrideWNDW"] := ""
                return false
            }

            loop (mouseArr.Length / 2) {
                index := ((A_Index - 1) * 2) + 1

                Sleep(this._launcherDelay)

                if (this.exists()) {
                    this.allowExit := restoreAllowExit
                    globalStatus["loadscreen"]["overrideWNDW"] := ""

                    return
                }
                else if (this.shouldExit) {
                    globalStatus["loadscreen"]["overrideWNDW"] := ""
                    return false
                }

                if (!WinShown("ahk_exe " this._launcherEXE)) {
                    hiddenCount += 1
                    continue
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