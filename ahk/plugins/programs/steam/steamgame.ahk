; --- DEFAULT STEAM APP ---
class SteamGameProgram extends Program {
    __New(args*) {
        super.__New(args*)

        pathArr := StrSplit(RegRead("HKEY_CURRENT_USER\Software\Valve\Steam", "SteamPath"), "/")
        steamDir := validateDir(joinArray(pathArr, "\"))
        libraryConfig := steamDir . "config\libraryfolders.vdf"       

        this.dir := []
        if (FileExist(libraryConfig)) {
            libraryStr := fileToString(libraryConfig)
            if (RegExMatch(libraryStr, "misU)`"libraryfolders`"\s*(\r|\n)*\s*\{\s*(\r|\n)*", &library)) {
                libraryPtr := library.Pos[0] + library.Len[0]

                while (libraryPtr < StrLen(libraryStr) && RegExMatch(libraryStr, "misU)\s*`"\d+`"\s*(\r|\n)*\s*\{", &each, libraryPtr)) {
                    currStart := each.Pos[0] + each.Len[0]
                    currStr := SubStr(libraryStr, currStart)

                    openPos := InStr(currStr, "{") 
                    closePos := InStr(currStr, "}") 
                
                    while (openPos < closePos) {            
                        openPos := InStr(currStr, "{",, closePos + 1) 
                        closePos := InStr(currStr, "}",, closePos + 1) 
                    }

                    currLen := closePos - 1
                    currData := SubStr(libraryStr, currStart, currLen)

                    if (RegExMatch(currData, "misU)^\s*`"path`".*$", &currMatch)) {
                        deliminator := "		"
                        dirStr := Trim(StrReplace(StrSplit(Trim(currMatch[0], " `t`r`n"), deliminator)[2], "\\", "\"), "`"")
                        dirStr := (SubStr(dirStr, -1, 1) = "\") ? dirStr : (dirStr . "\") . "steamapps\common\"
                        if (DirExist(dirStr)) {
                            if (!inArray(dirStr, this.dir)) {
                                this.dir.Push(dirStr)
                            }
                        }
                    }

                    libraryPtr := currStart + currLen
                }
            }
        }

        currUser := RegRead("HKEY_CURRENT_USER\Software\Valve\Steam\ActiveProcess", "ActiveUser")
        if (!currUser) {
            return
        }
        
        shortcutsConfig := steamDir . "userdata\" . currUser . "\config\shortcuts.vdf"
        if (FileExist(shortcutsConfig)) {
            fileObj := FileOpen(shortcutsConfig, "r")

            fileLength := fileObj.Length
            fileBuf := Buffer(fileLength, 0)
            fileObj.RawRead(fileBuf)
            fileObj.Close()

            ptr := 0
            prevEXE := false
            while (ptr < fileLength) {
                currStr := StrGet(fileBuf.Ptr + ptr,, "CP0")
                if (prevEXE) {
                    dirStr := Trim(currStr, " `t`r`n`"")
                    dirStr := (SubStr(dirStr, -1, 1) = "\") ? dirStr : (dirStr . "\")
                    if (DirExist(dirStr)) {
                        if (!inArray(dirStr, this.dir)) {
                            this.dir.Push(dirStr)
                        }
                    }
                    
                    prevEXE := false
                }
                if (InStr(StrLower(currStr), Chr(1) . "startdir")) {
                    prevEXE := true
                }
                
                ptr += StrLen(currStr) + 1
            }
        }
    }

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

        if (URI = "") {
            return false
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

                ; if (WinGetTitle(wndw) = "Steam") {
                ;     minSize := WinGetMinSize(wndw)
                ;     WinMove(,, minSize[1], minSize[2])
                ;     Sleep(100)
               
                ;     WinActivateForeground(wndw)
                ;     Sleep(250)
                    
                ;     loop 2 {
                ;         MouseClick("Left"
                ;             , percentWidthRelativeWndw(0.6, wndw)
                ;             , percentHeightRelativeWndw(0.83 + ((A_Index - 1) * 0.05), wndw)
                ;             ,,, "D"
                ;         )
                ;         Sleep(75)
                ;         MouseClick("Left",,,,, "U")
                ;         Sleep(75)
                ;     }

                ;     HideMouseCursor()
                ;     Sleep(250)
                ;     WinClose(wndw)

                ;     return
                ; }

                if (StrLower(WinGetTitle(wndw)) = "eula") {               
                    WinActivateForeground(wndw)
                    Sleep(250)
                    
                    MouseClick("Left"
                        , percentWidthRelativeWndw(0.65, wndw)
                        , percentHeightRelativeWndw(0.93, wndw)
                        ,,, "D"
                    )
                    Sleep(75)
                    MouseClick("Left",,,,, "U")
                    Sleep(75)

                    HideMouseCursor()
                    Sleep(250)

                    return
                }

                if (StrLower(WinGetTitle(wndw)) = "steam dialog") {               
                    WinActivateForeground(wndw)
                    Sleep(250)
                    
                    MouseClick("Left"
                        , percentWidthRelativeWndw(0.667, wndw)
                        , percentHeightRelativeWndw(0.83, wndw)
                        ,,, "D"
                    )
                    Sleep(75)
                    MouseClick("Left",,,,, "U")
                    Sleep(75)

                    HideMouseCursor()
                    Sleep(250)

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

            runWithArgs := true
        
            ; launch steam if it doesn't exist
            ; if (!globalRunning.Has("steam") || !globalRunning["steam"].exists()) {
            ;     if (!globalRunning.Has("steam")) {
            ;         createProgram("steam", true, false)
            ;     }
            ;     else if (!globalRunning["steam"].exists()) {
            ;         globalRunning["steam"].launch()
            ;     }
            
            ;     ; has carriage return to avoid getting overwritten by previous resetLoadscreen
            ;     ; (resetLoadscreen does a simple check if old text = new text before delayed overwrite)
            ;     setLoadScreen("Waiting for Steam...`r")
        
            ;     this.allowExit := true
                
            ;     count := 0
            ;     maxCount := 150
            ;     ; buffer wait for steam so that the URI works
            ;     while (count < maxCount) {
            ;         if (this.shouldExit) {    
            ;             return false
            ;         }
        
            ;         count += 1
            ;         Sleep(100)
            ;     }
        
            ;     this.allowExit := false
            ; }
            
            setLoadScreen("Waiting for Steam...")

            try {
                ; write args to default args of game in steam config file because
                ; I HATE VALVE I HATE VALVE I HATE VALVE I HATE VALVE I HATE VALVE
                if (cleanArgs.Length > 0) {
                    uriArr := StrSplit(Trim(URI, "/"), "/")
                    gameID := uriArr[uriArr.Length]
                    argString := joinArray(cleanArgs)
                    argString := StrReplace(argString, '\', '\\')
                    argString := StrReplace(argString, '"', '\"')

                    userID := RegRead("HKEY_CURRENT_USER\Software\Valve\Steam\ActiveProcess", "ActiveUser")
                    if (userID = 0) {
                        ErrorMsg("Not Logged into Steam")
                        return false
                    }

                    steamDir := validateDir(RegRead("HKEY_CURRENT_USER\Software\Valve\Steam", "SteamPath"))
                    configDir := validateDir(steamDir . "userdata\" . userID . "\config")

                    localConfig := configDir . "localconfig.vdf"
                    if (!FileExist(localConfig)) {
                        ErrorMsg("Missing steam config file?")
                        return false
                    }

                    localConfigStr := fileToString(localConfig)
                    if (RegExMatch(localConfigStr, "misU)`"UserLocalConfigStore`"\s*(\r|\n)*\s*\{.*\s*`"Software`"\s*(\r|\n)*\s*\{.*\s*`"Valve`"\s*(\r|\n)*\s*\{." 
                        . "*\s*`"Steam`"\s*(\r|\n)*\s*\{.*\s*`"apps`"\s*(\r|\n)*\s*\{.*\s*`"" . gameID . "`"\s*(\r|\n)*\s*\{.*", &configMatch)) {
                        
                        runWithArgs := false

                        start := configMatch.Pos[0] + configMatch.Len[0]

                        currData := SubStr(localConfigStr, start)
                        openPos := InStr(currData, "{") 
                        closePos := InStr(currData, "}") 

                        while (openPos < closePos) {            
                            openPos := InStr(currData, "{",, closePos + 1) 
                            closePos := InStr(currData, "}",, closePos + 1) 
                        }
                        
                        gameData := RTrim(SubStr(localConfigStr, start, closePos - 1))

                        RegExMatch(gameData, "^\s*", &whitespaceMatch)
                        whitespace := whitespaceMatch[0]
                        deliminator := "		"

                        eol := "`n"
                        if (InStr(gameData, "`r")) {
                            eol := "`r`n"
                        }
                        
                        oldLaunchString := ""
                        newLaunchString := whitespace . "`"LaunchOptions`"" . deliminator . '"' . argString . '"`n'
                        if (RegExMatch(gameData, "mU)^\s*`"LaunchOptions`".*$", &oldLaunchMatch)) {
                            oldLaunchString := oldLaunchMatch[0]
                        }

                        if (Trim(oldLaunchString, " `t" . eol) != Trim(newLaunchString, " `t" . eol)) {
                            if (globalRunning.Has("steam") && globalRunning["steam"].exists()) {
                                globalRunning["steam"].exit(false)
                                Sleep(1000)
                            }

                            newGameData := RTrim(RegExReplace(gameData, "mU)^\s*`"LaunchOptions`".*$"), " `t" . eol) . whitespace . "`"LaunchOptions`"" . deliminator . '"' . argString . '"' eol
                            localConfigStr := StrReplace(localConfigStr, gameData, newGameData)
            
                            localConfigFile := FileOpen(localConfig, "w")
                            localConfigFile.Write(localConfigStr)
                            localConfigFile.Close()
                        }
                    }
                }
            }
            catch {
                return false
            }

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
                if (runWithArgs) {
                    RunAsUser(game, cleanArgs)
                }
                else {
                    RunAsUser(game)
                }
            }
            catch {
                SetTitleMatchMode(restoreTTMM)
                return false
            }
        
            steamOpen := globalRunning.Has("steam") && globalRunning["steam"].exists()

            count := 0
            maxCount := (!steamOpen) ? 600 : 200
            ; wait for either the game or a common steam window
            while (count < maxCount && !steamShown() && !this.exists() 
                && !((this.launcher.Has("exe") && ProcessExist(this.launcher["exe"]) || (this.launcher.Has("wndw") && WinHidden(this.launcher["wndw"]))))) {
                
                if (count > 25 && this.shouldExit) {    
                    SetTitleMatchMode(restoreTTMM)
                    return false
                }
        
                count += 1
                Sleep(100)
            }
        
            ; if game -> success
            if (this.exists() || (this.launcher.Has("exe") && ProcessExist(this.launcher["exe"])) || (this.launcher.Has("wndw") && WinHidden(this.launcher["wndw"]))) {
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

            ; little buffer to help out a fresh steamer
            if (!steamOpen) {
                Sleep(3000)
            }
        
            globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe steamwebhelper.exe"
            this.allowExit := true

            count := 0
            maxCount := 15
        
            firstShown := false
            ; while launching window is shown, just wait
            while (steamShown()) {
                if (this.exists() || (this.launcher.Has("exe") && ProcessExist(this.launcher["exe"])) || (this.launcher.Has("wndw") && WinHidden(this.launcher["wndw"]))) {
                    break
                }

                if (!steamOpen && count < maxCount) {
                    count += 1

                    Sleep(100)
                    continue
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
                            maxCount := 5
                            while (count < maxCount) {
                                if (this.exists() || (this.launcher.Has("exe") && ProcessExist(this.launcher["exe"])) || (this.launcher.Has("wndw") && WinHidden(this.launcher["wndw"]))) {
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
                Sleep(100)
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
        HideMouseCursor()

        SetTimer(OpenMenu.Bind(0), Neg(100))
        return

        OpenMenu(loopCount) {
            if (loopCount > 100) {
                return
            }

            if (WinShown("A") && WinGetID("A") = this.getHWND()) {
                this.send("{Shift down}")
                Sleep(100)
                this.send("{Tab}")
                Sleep(100)
                this.send("{Shift up}")
        
                Sleep(100)
                HideMouseCursor()
                return
            }

            SetTimer(OpenMenu.Bind(loopCount + 1), Neg(100))
            return
        }
    }
}