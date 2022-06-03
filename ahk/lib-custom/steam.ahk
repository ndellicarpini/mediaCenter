; steam launch
steamLaunch() {    
    Run "C:\Steam\steam.exe -silent", "C:\Steam", "Hide"
    Sleep(5000)
}

; steam exit
steamExit() {
    Run "C:\Steam\steam.exe -shutdown", "C:\Steam", "Hide"
    Sleep(5000)
}

; checks for common steam windows
steamShown() {
    return WinShown("Install - ") || WinShown("Updating ") || WinShown("Ready - ") 
        || WinShown(" - Steam") || WinShown("Steam Dialog")
}

; try to run a game, handling dialogs / restarting steam where necessary
;  programID - id of game's program
;  URI - link to steam game to launch
;  loopCount - internal recursion count
;
; returns true if game successfully launches
steamGameLaunchHandler(programID, URI, loopCount := 0) {
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

    global globalRunning

    this := globalRunning[programID]

    currLoadScreen := getStatusParam("loadText")
    setLoadScreen("Waiting for Steam...")

    currHotkeys := getStatusParam("currHotkeys")
    setStatusParam("currHotkeys", addHotkeys(currHotkeys, Map("B", "stopWaiting")))

    loadText := getStatusParam("loadText")
    resetTMM := A_TitleMatchMode

    SetTitleMatchMode 2

    ; launch steam if it doesn't exist
    if (!globalRunning.Has("steam") || !globalRunning["steam"].exists()) {
        if (!globalRunning.Has("steam")) {
            createProgram("steam")
        }
        else if (!globalRunning["steam"].exists()) {
            globalRunning["steam"].launch()
        }
    
        setLoadScreen("Waiting for Steam...")
        
        count := 0
        maxCount := 100
        ; buffer wait for steam so that the URI works
        while (count < maxCount) {
            if (getStatusParam("internalMessage") = "stopWaiting") {
                setStatusParam("currHotkeys", currHotkeys)
                setStatusParam("internalMessage", "")
    
                SetTitleMatchMode(resetTMM)
                return false
            }

            count += 1
            Sleep(100)
        }
    }

    Run URI

    count := 0
    maxCount := 40
    ; wait for either the game or a common steam window
    while (count < maxCount && !steamShown() && !this.exists()) {
        count += 1
        Sleep(500)
    }

    ; if game -> success
    if (this.exists()) {
        SetTitleMatchMode(resetTMM)
        return true
    }

    ; if no steam windows shown -> restart steam
    if (!steamShown()) {
        if (loopCount > 2) {
            SetTitleMatchMode(resetTMM)
            return false
        }

        globalRunning["steam"].exit()
        
        Sleep(2000)
        return steamGameLaunchHandler(programID, URI, loopCount + 1)
    }

    updateWidth := Floor(percentWidth(0.4, false))

    ; while launching window is shown, just wait
    while (WinShown(" - Steam")) {
        setLoadScreen(currLoadScreen)

        if (getStatusParam("internalMessage") = "stopWaiting") {
            setStatusParam("currHotkeys", currHotkeys)
            setStatusParam("internalMessage", "")
            WinClose(" - Steam")

            SetTitleMatchMode(resetTMM)
            return false
        }

        checkDialogs()

        Sleep(250)
    }

    ; while game updating -> resize update windows for funsies
    while (WinShown("Updating ")) {
        try {
            WinActivate("Updating ")
            
            WinGetPos(&X, &Y, &W, &H, "Updating ")
            if (W != updateWidth) {
                WinMove((Floor(percentWidth(0.5, false)) - Floor(updateWidth / 2)), Y, updateWidth, H)
            }
        }
        
        if (getStatusParam("internalMessage") = "stopWaiting") {
            setStatusParam("currHotkeys", currHotkeys)
            setStatusParam("internalMessage", "")
            WinClose("Updating ")

            SetTitleMatchMode(resetTMM)
            return false
        }

        checkDialogs()

        Sleep(500)
    }

    checkDialogs()

    ; if game finishes updating -> click play button
    while (WinShown("Ready - ")) {  
        try {
            WinActivate("Ready - ")

            WinGetPos(&X, &Y, &W, &H, "Ready - ")
            ; the perfect infinite subpixel
            mouseX := X + W - Floor(percentWidth(0.0484375, false))
            mouseY := Y + Floor(percentHeight(0.14629629629, false))
    
            Sleep(75)
            MouseMove(mouseX, mouseY)
            Sleep(75)
            MouseClick("Left")
            Sleep(75)
            MouseMove(percentWidth(1, false), percentHeight(1, false))
        }

        if (getStatusParam("internalMessage") = "stopWaiting") {
            setStatusParam("currHotkeys", currHotkeys)
            setStatusParam("internalMessage", "")
            WinClose("Ready - ")
            
            SetTitleMatchMode(resetTMM)
            return false
        }

        checkDialogs()

        Sleep(2000)
    }   

    if (getStatusParam("internalMessage") = "stopWaiting") {
        setStatusParam("internalMessage", "")
    }

    setStatusParam("currHotkeys", currHotkeys)
    SetTitleMatchMode(resetTMM)
    return true
}