; steam launch
steamLaunch() {    
    Run "C:\Steam\steam.exe -silent", "C:\Steam"
    Sleep(5000)
}

; steam exit
steamExit() {
    Run "C:\Steam\steam.exe -shutdown", "C:\Steam"
    Sleep(5000)
}

; checks for common steam windows
steamShown() {
    return WinShown("Install - ") || WinShown("Updating ") || WinShown("Ready - ") 
        || WinShown(" - Steam") || WinShown("Steam Dialog")
}

; try to run a game, handling dialogs / restarting steam where necessary
;  URI - link to steam game to launch
;  loopCount - internal recursion count
;
; returns true if game successfully launches
steamGameLaunchHandler(URI, loopCount := 0) {
    ; checks if the eula is open & accepts it
    checkDialogs() {
        if (WinShown(" Dialog")) {
            WinClose(" Dialog")
        }

        if (WinShown("Install - ")) {
            WinActivate("Install - ")
            Sleep(100)
            Send "{Enter}"
        }
    }

    global globalConfig
    global globalStatus
    global globalRunning

    this := globalRunning["steamgame"]

    restoreLoadText := globalStatus["loadscreen"]["text"]
    restoreAllowExit := this.allowExit
    restoreTTMM := A_TitleMatchMode

    setLoadScreen("Waiting for Steam...")
    loadText := globalStatus["loadscreen"]["text"]

    SetTitleMatchMode 2

    ; launch steam if it doesn't exist
    if (!globalRunning.Has("steam") || !globalRunning["steam"].exists()) {
        if (!globalRunning.Has("steam")) {
            createProgram("steam", true, false)
        }
        else if (!globalRunning["steam"].exists()) {
            globalRunning["steam"].launch()
        }
    
        setLoadScreen("Waiting for Steam...")

        this.allowExit := true
        
        count := 0
        maxCount := 100
        ; buffer wait for steam so that the URI works
        while (count < maxCount) {
            if (this.shouldExit) {    
                SetTitleMatchMode(restoreTTMM)
                return false
            }

            count += 1
            Sleep(100)
        }

        this.allowExit := false
    }

    Run URI

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

        return true
    }

    ; if no steam windows shown -> restart steam
    if (!steamShown()) {
        if (loopCount > 2) {
            SetTitleMatchMode(restoreTTMM)
            return false
        }

        globalRunning["steam"].exit()
        
        Sleep(2000)
        return steamGameLaunchHandler(URI, loopCount + 1)
    }

    this.allowExit := true
    
    setLoadScreen(restoreLoadText)
    globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe steam.exe"

    ; while launching window is shown, just wait
    while (WinShown(" - Steam")) {
        checkDialogs()

        Sleep(250)
    }

    updateWidth := Floor(percentWidth(0.4, false))

    ; while game updating -> resize update windows for funsies
    while (WinShown("Updating ")) {
        try {            
            WinGetPos(&X, &Y, &W, &H, "Updating ")
            if (W != updateWidth) {
                WinMove((Floor(percentWidth(0.5, false)) - Floor(updateWidth / 2)), Y, updateWidth, H)
            }
        }

        if (this.shouldExit) {   
            globalStatus["loadscreen"]["overrideWNDW"] := ""

            WinClose("Updating ")
            SetTitleMatchMode(restoreTTMM)

            return false
        }

        checkDialogs()

        Sleep(500)
    }

    checkDialogs()

    ; if game finishes updating -> click play button
    while (WinShown("Ready - ")) {  
        try {
            WinGetPos(&X, &Y, &W, &H, "Ready - ")
            ; the perfect infinite subpixel
            mouseX := Floor(percentWidthRelativeWndw(0.915, "Ready - "))
            mouseY := Floor(percentHeightRelativeWndw(0.658, "Ready - "))
    
            Sleep(75)
            MouseMove(mouseX, mouseY)
            Sleep(75)
            MouseClick("Left")
            Sleep(75)
            MouseMove(percentWidth(1, false), percentHeight(1, false))
        }

        if (this.shouldExit) {   
            globalStatus["loadscreen"]["overrideWNDW"] := ""

            WinClose("Ready - ")
            SetTitleMatchMode(restoreTTMM)

            return false
        }

        checkDialogs()

        Sleep(2000)
    }   

    globalStatus["loadscreen"]["overrideWNDW"] := ""
    this.allowExit := restoreAllowExit
    SetTitleMatchMode(restoreTTMM)

    return true
}