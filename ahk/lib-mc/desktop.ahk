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
enableDesktopMode(showDialog := true) {
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

; turns on & off gui keyboard
;
; returns null
toggleKeyboard() {
    ; global globalGuis

    ; if (globalGuis.Has(GUIKEYBOARDTITLE)) {
    ;     globalGuis[GUIKEYBOARDTITLE].Destroy()
    ; }
    ; else {
    ;     guiKeyboard() 
    ; }

    if (WinShown("On-Screen Keyboard")) {
        WinClose("On-Screen Keyboard")
    }
    else {
        Run "osk.exe"
    }
}