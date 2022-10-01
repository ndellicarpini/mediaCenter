; --- HELPERS --- 

; send keypress(es) after a short delay
;  key - key to press
;  delay - delay before keypress(es)
;  numPress - number of times to press key
delayedKeypress(key, delay := 2000, numPress := 1) {
    if (delay = 0 && A_Index = 1) {
        SendKey((numPress - 1))
        return
    }

    SetTimer(SendKey.Bind((numPress - 1)), -1 * delay)

    return

    SendKey(repeat) {
        SendSafe(key)

        if (repeat > 0) {
            SetTimer(SendKey.Bind((repeat - 1)), -1 * delay)
        }

        return
    }
}

; find a game launcher executable & press the play button at mousePos
;  gameID - id of program
;  executable - executable name of launcher
;  mousePos - array/double array of x,y mouse position to click at
;           - index = 1 -> x, index = 2 -> y | infinitely
;  delay - delay before mousemoves->mouseclicks
skipLauncherMouse(gameID, executable, mousePos, delay := 1000) {
    global globalConfig
    global globalRunning

    if (Type(mousePos) != "Array") {
        ErrorMsg("Launcher mousePos is invalid")
        return
    }

    ; wait for executable
    while (!WinShown("ahk_exe " executable)) {
        if (globalRunning[gameID].exists()) {
            return
        }

        Sleep(100)
    }

    hideTaskbar := globalConfig["General"].Has("HideTaskbar") && globalConfig["General"]["HideTaskbar"]
    if (hideTaskbar && WinShown("ahk_class Shell_TrayWnd")) {
        WinHide "ahk_class Shell_TrayWnd"
    }

    ; flatten double array
    mouseArr := []
    loop mousePos.Length {
        if (Type(mousePos[A_Index]) = "Array") {
            currIndex := A_Index
            loop mousePos[currIndex].Length {
                mouseArr.Push(mousePos[currIndex][A_Index])
            }
        }
        else {
            mouseArr.Push(mousePos[A_Index])
        }
    }

    if (Mod(mouseArr.Length, 2) != 0) {
        ErrorMsg("Launcher mousePos length must be even")
        return
    }

    ; try to skip launcher as long as exectuable is shown
    while (WinShown("ahk_exe " executable)) {
        if (globalRunning[gameID].exists()) {
            return
        }

        WinActivate("ahk_exe " executable)

        loop (mouseArr.Length / 2) {
            index := ((A_Index - 1) * 2) + 1
    
            Sleep(delay)
            Sleep(75)
            if (globalRunning[gameID].exists() || !WinShown("ahk_exe " executable)) {
                return
            }

            MouseClick("Left", percentWidthRelativeWndw(mouseArr[index], "ahk_exe " executable)
                , percentHeightRelativeWndw(mouseArr[index + 1], "ahk_exe " executable),,, "D")
            Sleep(75)
            MouseClick("Left",,,,, "U")
            Sleep(75)
            MouseMove(percentWidth(1), percentHeight(1))    
        }
    }
}

; --- CONFIG FUNCTIONS ---

; launch a standard windows game from an executable path
;  game - full path of game executable
;  args - args to use when running game
;
; returns null
winGameLaunch(game, args*) {
    global globalRunning

    this := globalRunning["wingame"]

    pathArr := StrSplit(game, "\")
    
    exe := pathArr.RemoveAt(pathArr.Length)
    path := joinArray(pathArr, "\")

    if ((Type(args) = "String" && args != "") || (Type(args) = "Array" && args.Length > 0)) {
        Run game . " " . joinArray(args), path
    }
    else {
        Run game, path
    }

    ; custom actions based on game
    switch(game) {
        case "D:\Rockstar\Grand Theft Auto V\PlayGTAV.exe":
            skipLauncherMouse("wingame", "Launcher.exe", [])
        case "D:\Games\Kingdom Hearts 1.5+2.5\KINGDOM HEARTS HD 1.5+2.5 ReMIX.exe"
            , "D:\Games\Kingdom Hearts 2.8\KINGDOM HEARTS HD 2.8 Final Chapter Prologue.exe"
            , "D:\Games\Kingdom Hearts III\KINGDOM HEARTS III\Binaries\Win64\KINGDOM HEARTS III.exe":
            this.hotkeys := Map("SELECT", Map("up", "Send '{Escape up}'", "down", "Send '{Escape down}'"))
        case "D:\Games\Simpsons Hit & Run\Lucas Simpsons Hit & Run Mod Launcher.exe":
            this.hotkeys := Map("START", Map("up", "Send '{Escape up}'", "down", "Send '{Escape down}'"))
        case "shell:AppsFolder\Microsoft.OpusPG_8wekyb3d8bbwe!OpusReleaseFinal":
            this.wndw := "Forza Horizon 3"
            this.allowPause := false
        case "D:\Games\SORR\SorRFS.exe":
            this.allowPause := false
            this.requireFullscreen := false
            this.customExit := "ProcessClose SorR.exe"
    }
}

; launch game from exectuable path that uses Origin
;  game - full path of game executable
;  args - args to use when running game
;
; returns null
originGameLaunch(game, args*) {
    global globalConfig
    global globalRunning

    this := globalRunning["origingame"]

    pathArr := StrSplit(game, "\")
    
    exe := pathArr.RemoveAt(pathArr.Length)
    path := joinArray(pathArr, "\")

    if ((Type(args) = "String" && args != "") || (Type(args) = "Array" && args.Length > 0)) {
        Run game . " " . joinArray(args), path
    }
    else {
        Run game, path
    }

    count := 0
    maxCount := 40

    hideTaskbar := globalConfig["General"].Has("HideTaskbar") && globalConfig["General"]["HideTaskbar"]

    setLoadScreen("Waiting for Origin...")
    setStatusParam("currHotkeys", addHotkeys(currHotkeys, Map("B", "stopWaiting")))

    ; wait for origin to show
    while (!this.exists(true) && count < maxCount) {
        if (WinShown("Origin")) {
            WinActivate("Origin")

            if (hideTaskbar && WinShown("ahk_class Shell_TrayWnd")) {
                WinHide "ahk_class Shell_TrayWnd"
            }
            
            count := 0
        }

        if (getStatusParam("internalMessage") = "stopWaiting") {
            setStatusParam("currHotkeys", currHotkeys)
            setStatusParam("internalMessage", "")
            originGamePostExit()

            SetTitleMatchMode(resetTMM)
            return -1
        }

        count += 1
        Sleep(500)
    }
}

; run an amazon game from amazon URI
;  URI - link to launch game
;  args - args to use when running game
;
; returns null
amazonGameLaunch(URI, args*) {
    global globalConfig
    global globalRunning

    this := globalRunning["amazongame"]

    Run URI

    count := 0
    maxCount := 40

    hideTaskbar := globalConfig["General"].Has("HideTaskbar") && globalConfig["General"]["HideTaskbar"]

    setLoadScreen("Waiting for Amazon Games...")
    setStatusParam("currHotkeys", addHotkeys(currHotkeys, Map("B", "stopWaiting")))

    ; wait for amazon to show
    while (!this.exists(true) && count < maxCount) {
        if (WinShown("Amazon Games")) {
            WinActivate("Amazon Games")

            if (hideTaskbar && WinShown("ahk_class Shell_TrayWnd")) {
                WinHide "ahk_class Shell_TrayWnd"
            }
            
            count := 0
        }

        if (getStatusParam("internalMessage") = "stopWaiting") {
            setStatusParam("currHotkeys", currHotkeys)
            setStatusParam("internalMessage", "")
            amazonGamePostExit()

            SetTitleMatchMode(resetTMM)
            return -1
        }

        count += 1
        Sleep(500)
    }
}

; run an steam game from steam URI
;  URI - link to launch game
;  args - args to use when running game
;
; returns -1 if launch fails
steamGameLaunch(URI, args*) {    
    global globalRunning

    this := globalRunning["steamgame"]

    steamResult := steamGameLaunchHandler("steamgame", URI)
    if (!steamResult) {
        return -1
    }

    ; custom actions based on game
    switch (URI) {
        case "steam://rungameid/200260": ; Batman Arkham Asylum
            skipLauncherMouse("steamgame", "BmLauncher.exe", [0.5, 0.666])
        case "steam://rungameid/35140": ; Batman Arkham City
            skipLauncherMouse("steamgame", "BmLauncher.exe", [0.5, 0.666])
        case "steam://rungameid/489830": ; Skyrim SE
            skipLauncherMouse("steamgame", "SkyrimSELauncher.exe", [0.925, 0.112])
        case "steam://rungameid/22370": ; Fallout 3
            skipLauncherMouse("steamgame", "FalloutLauncherSteam.exe", [0.922, 0.278])
        case "steam://rungameid/22380": ; Fallout NV
            skipLauncherMouse("steamgame", "FalloutNVLauncher.exe", [0.922, 0.278])
        case "steam://rungameid/377160": ; Fallout 4
            skipLauncherMouse("steamgame", "Fallout4Launcher.exe", [0.922, 0.109])
        case "steam://rungameid/236870": ; HITMAN
            skipLauncherMouse("steamgame", "Launcher.exe", [0.128, 0.621])
        case "steam://rungameid/55230": ; Saints Row 3
            skipLauncherMouse("steamgame", "game_launcher.exe", [0.25, 0.441])
        case "steam://rungameid/20920": ; Witcher 2
            skipLauncherMouse("steamgame", "Launcher.exe", [0.585, 0.875])
        case "steam://rungameid/22330": ; Oblivion
            skipLauncherMouse("steamgame", "OblivionLauncher.exe", [0.664, 0.25])
        case "steam://rungameid/219150": ; Hotline Miami
            skipLauncherMouse("steamgame", "HotlineMiami.exe", [0.216, 0.948])
        case "steam://rungameid/322500": ; SUPERHOT
            skipLauncherMouse("steamgame", "SUPERHOT.exe", [[0.205, 0.5], [0.373, 0.833]])
        case "steam://rungameid/690040": ; SUPERHOT 2
            skipLauncherMouse("steamgame", "SUPERHOTMCD.exe", [[0.497, 0.5], [0.373, 0.833]])
        case "steam://rungameid/1174180": ; Red Dead Redemption 2
            skipLauncherMouse("steamgame", "Launcher.exe", [])
        case "steam://rungameid/758330": ; Shenmue 1 & 2
            if (Integer(args[1]) = 1) {
                skipLauncherMouse("steamgame", "SteamLauncher.exe", [0.25, 0.5])
            }
            else if (Integer(args[1]) = 2) {
                skipLauncherMouse("steamgame", "SteamLauncher.exe", [0.75, 0.5])
            }
        case "steam://rungameid/107100": ; Bastion
            this.requireFullscreen := false
        case "steam://rungameid/374320": ; Dark Souls III
            this.requireFullscreen := false
        case "steam://rungameid/12140", "steam://rungameid/12150", "steam://rungameid/400", "steam://rungameid/220":
            ; Max Payne / Max Payne 2 / Portal / HL2
            this.mouse := Map("initialPos", [0.5, 0.5])
    }
}

; launch steam games using steam launcher
;  version - which jackbox to launch (1/2/3)
;
; returns -1 if lauch fails
jackboxLaunch(version) {
    global globalRunning

    this := globalRunning["jackbox"]

    retVal := 0
    if (version = 1) {
        retVal := steamGameLaunchHandler("jackbox", "steam://rungameid/331670")
    }
    else if (version = 2) {
        retVal := steamGameLaunchHandler("jackbox", "steam://rungameid/397460")
    }
    else if (version = 3) {
        retVal := steamGameLaunchHandler("jackbox", "steam://rungameid/434170")
    }

    return (retVal) ? 0 : -1
}

; custom post launch action for all flavors of windows game
winGamePostLaunch() {
    DelayCheckFullscreen(program) {
        if (!program.checkFullscreen()) {
            program.fullscreen()
        }
    }

    global globalRunning

    for id, program in globalRunning {
        ; only steamgame | wingame | origingame are supported
        if (id != "steamgame" && id != "wingame" && id != "origingame") {
            continue
        }

        ; custom action based on which executable is open
        switch(program.currEXE) {
            case "BioshockHD.exe", "Bioshock2HD.exe": ; Bioshock HD & Bioshock 2 HD
                delayedKeypress("{Enter}")
            case "gta3.exe": ; GTA 3
                delayedKeypress("{Enter}",, 2)
            case "gta-vc.exe": ; GTA VC
                delayedKeypress("{Enter}")
            case "gta-sa.exe": ; GTA SA
                delayedKeypress("^{Enter}")
            case "Shenmue.exe", "Shenmue2.exe": ; Shenmue 1 & 2
                delayedKeypress("{Enter}", 500)
            case "MBAA.exe": ; Melty Blood
                delayedKeypress("{Enter}", 500)
            case "Clustertruck.exe": ; Clustertruck
                delayedKeypress("{Enter}", 500)
            case "Madden19.exe": ; Madden 19
                SetTimer(MouseMove.Bind(percentWidth(1, false), percentHeight(1, false)), -10000)
                delayedKeypress("{Enter}", 500)
            case "TestDriveUnlimited.exe": ; Test Drive Unlimited
                SetTimer(MouseMove.Bind(percentWidth(1, false), percentHeight(1, false)), -20000)
            case "openmw.exe": ; Madden 19
                SetTimer(MouseMove.Bind(percentWidth(0.5, false), percentHeight(0.5, false)), -2000)
            case "PROA34-Win64-Shipping.exe": ; Blue Fire                
                SetTimer(DelayCheckFullscreen.Bind(program), -6500)  
            case "DarkSoulsIII.exe": ; Dark Souls III                
                SetTimer(DelayCheckFullscreen.Bind(program), -6500)  
            case "braid.exe": ; Braid
                if (program.checkFullscreen()) {
                    Send("!{Enter}")
                    Sleep(500)
                    program.fullscreen()
                }
            case "UNDERTALE.exe": ; Undertale
                while (!program.checkFullscreen()) {
                    Send("{F4}")
                    Sleep(500)
                    Send("{F4}")
                    Sleep(500)
                }          
        }
    }
}

; custom post executable close action for all flavors of windows game
winGamePostExit() {
    global globalRunning

    for id, program in globalRunning {
        ; only steamgame | wingame | origingame are supported
        if (id != "steamgame" && id != "wingame" && id != "origingame") {
            continue
        }

        ; custom action based on which executable is open
        switch (program.currEXE) {
            case "SorR.exe":
                ProcessClose("SorRFS.exe")
            case "GTA5.exe": ; GTA 5
                count := 0
                maxCount := 100

                while (!WinShown("Rockstar Games Launcher") && count < maxCount) {
                    count += 1
                    Sleep(100)
                }

                if (WinShown("Rockstar Games Launcher")) {
                    WinClose("Rockstar Games Launcher")
                    Sleep(500)
                }
            case "Shenmue.exe", "Shenmue2.exe": ; Shenmue 1 & 2
                count := 0
                maxCount := 100

                while (!WinShown("Shenmue Launcher") && count < maxCount) {
                    count += 1
                    Sleep(100)
                }

                if (WinShown("Shenmue Launcher")) {
                    WinClose("Shenmue Launcher")
                    Sleep(500)
                }
        }
    }
}

; close origin after game exits
originGamePostExit() {
    count := 0
    maxCount := 100
    ; wait for origin to show
    while (!WinShown("Origin") && count < maxCount) {
        count += 1
        Sleep(100)
    }

    count := 0
    maxCount := 20
    ; try to close origin while open
    while (WinShown("Origin") && count < maxCount) {
        WinActivate("Origin")
        Sleep(100)

        Send("{Alt down}")
        Sleep(50)
        Send("o")
        Sleep(50)
        Send("{Alt up}")
        Sleep(50)
        Send("{Up}")
        Sleep(50)
        Send("{Enter}")

        count += 1
        Sleep(500)
    }

    ; take drastic measures if origin remains
    if (ProcessExist("Origin.exe") && count >= maxCount) {
        ProcessClose("Origin.exe")
    }
}

; close amazon game launcher after game exits
amazonGamePostExit() {
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

; winGamePause() {
;     global globalRunning

;     for id, program in globalRunning {
;         ; only steamgame | wingame | origingame are supported
;         if (id != "steamgame" && id != "wingame" && id != "origingame") {
;             continue
;         }

;         ProcessSuspend(program.getPID())
;     }
; }

; winGameResume() {
;     global globalRunning

;     for id, program in globalRunning {
;         ; only steamgame | wingame | origingame are supported
;         if (id != "steamgame" && id != "wingame" && id != "origingame") {
;             continue
;         }

;         ProcessResume(program.getPID())
;     }
; }