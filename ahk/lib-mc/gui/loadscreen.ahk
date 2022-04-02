global GUILOADTITLE := "AHKGUILOAD"

; creates & shows the load screen
;
; returns null
createLoadScreen() {
    global globalConfig

    guiObj := Gui(GUIOPTIONS, GUILOADTITLE)

    if (globalConfig["GUI"].Has("LoadScreenFunction") && globalConfig["GUI"]["LoadScreenFunction"] != "") {
        guiObj := runFunction(globalConfig["GUI"]["LoadScreenFunction"], guiObj)
    }
    else {
        guiObj.BackColor := COLOR1
        guiSetFont(guiObj, "italic s30")

        guiObj.Add("Text", "vLoadText Right x0 y" . percentHeight(0.92, false) " w" . percentWidth(0.985, false), getStatusParam("loadText"))
    }

    guiObj.Show("x" . MONITORX . " y" . MONITORY . " NoActivate w" . percentWidth(1) . " h" . percentHeight(1))
}

; activates & updates the text the load screen
;  activate - if to activate the loadscreen
;
; returns null
updateLoadScreen(activate := true) {
    loadObj := getGUI(GUILOADTITLE)

    if (loadObj) {
        loadObj["LoadText"].Text := getStatusParam("loadText")
        
        if (activate) {
            WinActivate(GUILOADTITLE)
        }
    }
    else {
        createLoadScreen()
    }
}

; destroys the load screen
;
; returns null
destroyLoadScreen() {
    if (getGUI(GUILOADTITLE)) {
        getGUI(GUILOADTITLE).Destroy()
    }
}

; sets the text of the load screen & activates it
;  text - new load screen text
;
; returns null
setLoadScreen(text) {
    setStatusParam("loadShow", true)
    setStatusParam("loadText", text)
    updateLoadScreen()
}

; resets the text of the load screen & deactivates it
;
; returns null
resetLoadScreen() {
    global globalConfig

    setStatusParam("loadText", (mainConfig["GUI"].Has("DefaultLoadText")) ? mainConfig["GUI"]["DefaultLoadText"] : "Now Loading...")
    updateLoadScreen(false)
    setStatusParam("loadShow", false)
}