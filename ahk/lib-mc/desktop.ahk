global GUIKBMMODETITLE := "AHKKBMMODE"
global GUIDESKTOPTITLE := "AHKDESKTOPMODE"

; hotkeys for keyboard & mouse mode
;
; returns map of hotkeys
kbmmodeHotkeys() {
    setStatusParam("buttonTime", 0)

    ; TODO - button for keyboard
    return Map(
        "SELECT", "toggleKeyboard",
        "[REPEAT]B", "Send {Backspace}"
    )
}

; mouse config for keyboard & mouse mode
;
; returns map of mouse config
kbmmodeMouse() {
    return Map(
        "x", "LSX", 
        "y", "-LSY", 
        "lclick", "A",
        "rclick", "X",
        "hscroll", "RSX",
        "vscroll", "-RSY"
    )
}

; enables kbbmode & displays info splash
;  showDialog - whether or not to show the info splash
;
; returns null
enableKBMMode(showDialog := true) {
    setStatusParam("kbmmode", true)
    MouseMove(percentWidth(0.5, false), percentHeight(0.5, false))

    ; create basic gui dialog showing kb & mouse mode on
    ; TODO - add tooltip for keyboard button
    if (showDialog) {
        guiObj := Gui(GUIOPTIONS . " +AlwaysOnTop +Disabled +ToolWindow +E0x20", GUIKBMMODETITLE)
        guiObj.BackColor := COLOR1

        guiWidth := percentWidth(0.16)
        guiHeight := percentHeight(0.05)
        guiSetFont(guiObj, "bold s24")

        guiObj.Add("Text", "0x200 Center x0 y0 w" . guiWidth . " h" . guiHeight, "KB && Mouse Mode")
        guiObj.Show("NoActivate w" . guiWidth . " h" . guiHeight 
            . " x" . (percentWidth(1) - (guiWidth + percentWidth(0.01, false))) . " y" . (percentHeight(1) - (guiHeight + percentWidth(0.01, false))))
        
        WinSetTransparent(230, GUIKBMMODETITLE)
    }
}

; disables kbbmode & destroys info splash
;
; returns null
disableKBMMode() {
    global globalGuis

    if (globalGuis.Has(GUIKEYBOARDTITLE)) {
        globalGuis[GUIKEYBOARDTITLE].Destroy()
    }
    
    setStatusParam("kbmmode", false)
    MouseMove(percentWidth(1), percentHeight(1))

    if (WinShown(GUIKBMMODETITLE)) {
        WinClose(GUIKBMMODETITLE)
    }
}

; hotkeys for desktop mode
;
; returns map of hotkeys
desktopmodeHotkeys() {
    setStatusParam("buttonTime", 0)

    ; TODO - button for keyboard
    return Map(
        "HOME", "disableDesktopMode",
        "SELECT", "toggleKeyboard",
        "START", "Send {LWin}",

        "[REPEAT]DU", "Send {Up}",
        "[REPEAT]DD", "Send {Down}",
        "[REPEAT]DL", "Send {Left}",
        "[REPEAT]DR", "Send {Right}",

        "[REPEAT]B", "Send {Backspace}",

        "LT>0.3", "Send !{Tab}",
        "RT>0.3", "Send !+{Tab}",
    )
}

; enables desktop & displays info splash
;  showDialog - whether or not to show the info splash
;
; returns null
enableDesktopMode(showDialog := false) {
    global globalConfig
    global globalRunning

    for key, value in globalRunning {
        if (value.background || value.minimized) {
            continue
        }

        value.minimize()
        Sleep(100)
    }

    if (globalConfig["General"].Has("HideTaskbar") && globalConfig["General"]["HideTaskbar"]) {
        try WinShow "ahk_class Shell_TrayWnd"
    }

    setStatusParam("suspendScript", true)
    setStatusParam("desktopmode", true)
    MouseMove(percentWidth(0.5, false), percentHeight(0.5, false))

    ; create basic gui dialog showing kb & mouse mode on
    ; TODO - add tooltip for keyboard button
    if (showDialog) {
        guiObj := Gui(GUIOPTIONS . " +AlwaysOnTop +Disabled +ToolWindow +E0x20", GUIDESKTOPTITLE)
        guiObj.BackColor := COLOR1

        guiWidth := percentWidth(0.31)
        guiHeight := percentHeight(0.05)
        guiSetFont(guiObj, "bold s24")

        guiObj.Add("Text", "0x200 Center x0 y0 w" . guiWidth . " h" . guiHeight, "Press HOME to Disable Desktop Mode")
        guiObj.Show("NoActivate w" . guiWidth . " h" . guiHeight 
            . " x" . (percentWidth(1) - (guiWidth + percentWidth(0.01, false))) . " y" . (percentHeight(1) - (guiHeight + percentWidth(0.01, false))))
        
        WinSetTransparent(230, GUIDESKTOPTITLE)
    }

    destroyLoadScreen()
}

; disables desktop & destroys info splash
;
; returns null
disableDesktopMode() {
    global globalConfig
    global globalGuis
 
    if (globalConfig["General"].Has("HideTaskbar") && globalConfig["General"]["HideTaskbar"]) {
        try WinHide "ahk_class Shell_TrayWnd"
    }

    if (globalGuis.Has(GUIKEYBOARDTITLE)) {
        globalGuis[GUIKEYBOARDTITLE].Destroy()
    }
    
    setStatusParam("suspendScript", false)
    setStatusParam("desktopmode", false)
    MouseMove(percentWidth(1), percentHeight(1))

    if (WinShown(GUIDESKTOPTITLE)) {
        WinClose(GUIDESKTOPTITLE)
    }
}

; checks whether the keyboard is open
;
; returns true if the keyboard is visible
keyboardExists() {
    resetDHW := A_DetectHiddenWindows
    DetectHiddenWindows(true)

    hwnd := DllCall("FindWindowEx", "UInt", 0, "UInt", 0, "Str", "IPTip_Main_Window", "UInt", 0)

    DetectHiddenWindows(resetDHW)
    return (hwnd != 0)
}

; turns off gui keyboard
;
; returns null
openKeyboard() {
    resetDHW := A_DetectHiddenWindows
    resetSTM := A_TitleMatchMode

    DetectHiddenWindows(true)
    SetTitleMatchMode(3)

    try resetA := WinGetTitle("A")

    if (resetA = "Search") {
        Run "C:\Program Files\Common Files\microsoft shared\ink\TabTip.exe"
    }
    else {
        try {
            WinActivate("ahk_class Shell_TrayWnd")
    
            Sleep(100)
            Run "C:\Program Files\Common Files\microsoft shared\ink\TabTip.exe"
            Sleep(100)
        }
    }

    DetectHiddenWindows(resetDHW)
    SetTitleMatchMode(resetSTM)

    if (resetA && WinShown(resetA)) {
        WinActivate(resetA)
    }

    Hotkey("Enter", EnterOverrideHotkey)
} 

; turns off gui keyboard
;
; returns null
closeKeyboard() {
    resetDHW := A_DetectHiddenWindows
    DetectHiddenWindows(true)

    hwnd := DllCall("FindWindowEx", "UInt", 0, "UInt", 0, "Str", "IPTip_Main_Window", "UInt", 0)

    if (hwnd) {
        WinClose("ahk_id " hwnd)
    }
    
    DetectHiddenWindows(resetDHW)

    try Hotkey("Enter", "Off")
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

; check if keyboard is open when pressing enter to properly close it
EnterOverrideHotkey(*) { 
    Send("{Enter}")

    if (keyboardExists()) {
        closeKeyboard()
    }
}