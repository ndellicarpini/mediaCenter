#Include std.ahk

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
        guiSetFont(guiObj, "italic s40")

        guiObj.Add("Text", "vLoadText Right x0 y" . percentHeight(0.92, false) " w" . percentWidth(0.985, false), getStatusParam("loadText"))
    }

    guiObj.Show("Center NoActivate w" . percentWidth(1) . " h" . percentHeight(1))
}

; activates & updates the text the load screen
;
; returns null
activateLoadScreen() {
    loadObj := getGUI(GUILOADTITLE)

    if (loadObj) {
        loadObj["LoadText"].Text := getStatusParam("loadText")
        WinActivate(GUILOADTITLE)
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