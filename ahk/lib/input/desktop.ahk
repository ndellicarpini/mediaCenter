global GUIKBMMODETITLE := "AHKKBMMODE"
global GUIDESKTOPTITLE := "AHKDESKTOPMODE"

; enables kbbmode & displays info splash
;  showDialog - whether or not to show the info splash
;
; returns null
enableKBMMode(showDialog := true) {
    global globalStatus
    global globalRunning

    if (globalStatus["desktopmode"]) {
        return
    }

    currProgram := globalStatus["currProgram"]["id"] 

    monitorNum := MONITOR_N
    if (currProgram != "" && globalRunning.Has(currProgram)) {
        monitorNum := globalRunning[currProgram].monitorNum
    }

    globalStatus["kbmmode"] := true
    MouseMovePercent(0.5, 0.5, monitorNum)

    ; create basic gui dialog showing kb & mouse mode on
    ; TODO - add tooltip for keyboard button
    if (showDialog) {
        createInterface("notification", false,, "KB && Mouse Mode")
    }
}

; disables kbbmode & destroys info splash
;
; returns null
disableKBMMode() {
    global globalStatus
    global globalGuis

    ; close the keyboard if open
    if (keyboardExists()) {
        closeKeyboard()
    }
    
    globalStatus["kbmmode"] := false
    HideMouseCursor()

    if (globalGuis.Has("notification")) {
        globalGuis["notification"].Destroy()
    }
}

; enables desktop & displays info splash
;  showDialog - whether or not to show the info splash
;  minimizePrograms - whether or not to minimize all running programs
;
; returns null
enableDesktopMode(minimizePrograms := false, showDialog := false) {
    global globalConfig
    global globalStatus
    global globalRunning

    if (globalStatus["kbmmode"]) {
        disableKBMMode()
    }

    if (minimizePrograms) {
        for key, value in globalRunning {
            if (value.background || value.minimized) {
                continue
            }
    
            value.minimize()
            Sleep(100)
        }
    }

    globalStatus["desktopmode"] := true
    MouseMovePercent(0.5, 0.5, MONITOR_N)

    ; create basic gui dialog showing kb & mouse mode on
    ; TODO - add tooltip for keyboard button
    if (showDialog) {
        createInterface("notification", false,, "Desktop Mode")
    }

    globalStatus["loadscreen"]["enable"] := false
}

; disables desktop & destroys info splash
;
; returns null
disableDesktopMode() {
    global globalStatus
    global globalGuis

    ; close the keyboard if open
    if (keyboardExists()) {
        closeKeyboard()
    }
    
    globalStatus["desktopmode"]   := false
    HideMouseCursor()

    if (globalGuis.Has("notification")) {
        globalGuis["notification"].Destroy()
    }

    ; force rebuild loadscreen
    setLoadScreen()
    Sleep(500)
    resetLoadScreen()
}

; checks whether the keyboard is open
;
; returns true if the keyboard is visible
keyboardExists() {
    ; global globalGuis

    ; return globalGuis.Has("keyboard")

    ; return ProcessExist("osk.exe")

    if (!ProcessExist("TabTip.exe")) {
        return false
    }

    CLSID_FrameworkInputPane := "{D5120AA3-46BA-44C5-822D-CA8092C1FC72}"
    IID_IFrameworkInputPane  := "{5752238B-24F0-495A-82F1-2FD593056796}"

    try {
        buf := Buffer(32, 0)
        frameworkCOM := ComObject(CLSID_FrameworkInputPane, IID_IFrameworkInputPane)
        ; IFrameworkInputPane -> Location
        ComCall(6, frameworkCOM, "Ptr", buf)

        return (StrGet(buf.Ptr, 32) != "")
    }
    catch {
        return false
    }
}

; turns off gui keyboard
;
; returns null
openKeyboard() {
    ; global globalGuis

    ; if (!globalGuis.Has("keyboard")) {
    ;     createInterface("keyboard")
    ; }

    ; Run "osk.exe"

    restoreWNDW := 0
    if (WinExist("A")) {
        restoreWNDW := WinGetID("A")
    }

    if (!ProcessExist("TabTip.exe")) {
        Run "C:\Program Files\Common Files\microsoft shared\ink\TabTip.exe"
        Sleep(50)
    }

    CLSID_UIHostNoLaunch := "{4CE576FA-83DC-4F88-951C-9D0782B4E376}"
    IID_ITipInvocation   := "{37C994E7-432B-4834-A2F7-DCE1F13B834B}"

    try {
        invocationCOM := ComObject(CLSID_UIHostNoLaunch, IID_ITipInvocation)
        ; ITipInvocation -> Toggle
        ComCall(3, invocationCOM, "Ptr", DllCall("GetDesktopWindow"))
    
        if (restoreWNDW != 0 && WinShown(restoreWNDW)) {
            WinActivateForeground(restoreWNDW)
        }
    
        Hotkey("Enter", EnterOverrideHotkey)
    }
} 

; turns off gui keyboard
;
; returns null
closeKeyboard() {
    ; global globalGuis

    ; if (globalGuis.Has("keyboard")) {
    ;     globalGuis["keyboard"].Destroy()
    ; }

    ; ProcessClose("osk.exe")

    if (!ProcessExist("TabTip.exe")) {
        return
    }

    CLSID_UIHostNoLaunch := "{4CE576FA-83DC-4F88-951C-9D0782B4E376}"
    IID_ITipInvocation   := "{37C994E7-432B-4834-A2F7-DCE1F13B834B}"

    try {
        invocationCOM := ComObject(CLSID_UIHostNoLaunch, IID_ITipInvocation)
        ; ITipInvocation -> Toggle
        ComCall(3, invocationCOM, "Ptr", DllCall("GetDesktopWindow"))
    
        Hotkey("Enter", "Off")
    }
}

; turns on & off gui keyboard
;
; returns null
toggleKeyboard() {
    if (keyboardExists()) {
        closeKeyboard()
    }
    else {
        openKeyboard()
    }
}

; presses alt-tab with appropriate timing not to break start menu
; windows 11 is just weird man
;
; returns null
desktopAltTab() {
    Send("{Alt down}")
    Sleep(85)
    Send("{Tab}")
    Sleep(85)
    Send("{Alt up}")
}

; holds the alt key down & presses tab to show Alt+Tab menu
;
; returns null
desktopAltDown() {
    Send("{Alt down}")
    Send("{Tab}")
}

; releases the alt key from desktopAltDown
;
; returns null
desktopAltUp() {
    Send("{Alt up}")
}

; check if keyboard is open when pressing enter to properly close it
EnterOverrideHotkey(*) { 
    Send("{Enter}")
    Sleep(50)

    if (keyboardExists()) {
        closeKeyboard()
    }
}