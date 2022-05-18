steamLaunch() {    
    Run "C:\Steam\steam.exe -silent", "C:\Steam", "Hide"
    Sleep(5000)
}

steamExit() {
    Run "C:\Steam\steam.exe -shutdown", "C:\Steam", "Hide"
    Sleep(5000)
}

steamShown() {
    return WinShown("Install - ") || WinShown("Updating ") || WinShown("Ready - ") || WinShown(" - Steam")
}

steamGameLaunchHandler(programID, URI, overrideLoad := "") {
    global globalRunning

    checkEULA() {
        if (WinShown("Install - ")) {
            Sleep(100)
            WinActivate("Install - ")
            Sleep(100)
            Send "{Enter}"
        }
    }
    
    this := globalRunning[programID]

    loadText := getStatusParam("loadText")
    resetTMM := A_TitleMatchMode

    SetTitleMatchMode 2

    if (!globalRunning.Has("steam")) {
        createProgram("steam")
        setLoadScreen((overrideLoad != "") ? overrideLoad : loadText)
    }
    else if (!globalRunning["steam"].exists()) {
        globalRunning["steam"].launch()
        setLoadScreen((overrideLoad != "") ? overrideLoad : loadText)
    }

    Run URI

    count := 0
    maxCount := 40
    while (count < maxCount && !steamShown() && !this.exists()) {
        count += 1
        Sleep(500)
    }

    if (this.exists()) {
        SetTitleMatchMode(resetTMM)
        return true
    }

    currHotkeys := getStatusParam("currHotkeys")
    setStatusParam("currHotkeys", addHotkeys(currHotkeys, Map("B", "stopWaiting")))

    if (!steamShown()) {
        globalRunning["steam"].exit()
        
        Sleep(2000)
        return steamGameLaunchHandler(programID, URI, loadText)
    }

    updateWidth := Floor(percentWidth(0.4, false))

    while (WinShown(" - Steam")) {
        if (getStatusParam("internalMessage") = "stopWaiting") {
            setStatusParam("currHotkeys", currHotkeys)
            setStatusParam("internalMessage", "")
            WinClose(" - Steam")

            SetTitleMatchMode(resetTMM)
            return false
        }

        checkEULA()

        Sleep(250)
    }
    
    while (WinShown("Updating ")) {
        try {
            WinActivate("Updating ")
            
            WinGetPos(&X, &Y, &W, &H, "Updating ")
            ; HH := Floor(H/2)
            ; HW := Floor(W/2)
            if (W != updateWidth) {
                WinMove (Floor(percentWidth(0.5, false)) - Floor(updateWidth / 2)), Y, updateWidth, H
            }
        }
        
        if (getStatusParam("internalMessage") = "stopWaiting") {
            setStatusParam("currHotkeys", currHotkeys)
            setStatusParam("internalMessage", "")
            WinClose("Updating ")

            SetTitleMatchMode(resetTMM)
            return false
        }

        checkEULA()

        Sleep(500)
    }

    checkEULA()

    while (WinShown("Ready - ")) {  
        try {
            WinActivate("Ready - ")

            WinGetPos(&X, &Y, &W, &H, "Ready - ")
            mouseX := X + W - Floor(percentWidth(0.0484375, false))
            mouseY := Y + Floor(percentHeight(0.14629629629, false))
    
            Sleep(75)
            MouseMove(mouseX, mouseY)
            Sleep(75)
            MouseClick("Left")
            Sleep(75)
            MouseMove(MONITORX + MONITORW, MONITORY + MONITORH)
        }

        if (getStatusParam("internalMessage") = "stopWaiting") {
            setStatusParam("currHotkeys", currHotkeys)
            setStatusParam("internalMessage", "")
            WinClose("Ready - ")
            
            SetTitleMatchMode(resetTMM)
            return false
        }

        checkEULA()

        Sleep(2000)
    }   

    if (getStatusParam("internalMessage") = "stopWaiting") {
        setStatusParam("internalMessage", "")
    }

    setStatusParam("currHotkeys", currHotkeys)
    SetTitleMatchMode(resetTMM)
    return true
}

steamGameLaunch(URI) {
    global globalRunning

    this := globalRunning["steamgame"]

    return (steamGameLaunchHandler("steamgame", URI, "Waiting for Steam Game...")) ? 0 : -1
}