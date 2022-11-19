; creates & shows the load screen
;
; returns null
createLoadScreen() {
    global globalConfig
    global globalStatus

    guiObj := Gui(GUIOPTIONS, GUILOADTITLE)

	guiObj.BackColor := COLOR1
    
    guiSetFont(guiObj, "s26")

    imgSize := percentWidth(0.04)
    
    guiObj.Add("Text", "vLoadText Center x0 y" . percentHeight(0.92, false) " w" . percentWidth(1), globalStatus["loadscreen"]["text"])

    imgHTML := (
        "<html>"
            "<body style='background-color: transparent' style='overflow:hidden' leftmargin='0' topmargin='0'>"
                "<img src='" getAssetPath("loading.gif", globalConfig) "' width=" . imgSize . " height=" . imgSize . " border=0 padding=0>"
            "</body>"
        "</html>"
    )

    IMG := guiObj.Add("ActiveX", "w" . imgSize . " h" . imgSize . " x" . percentWidth(0.5, false) - (imgSize / 2) . " yp-" . (imgSize + percentHeight(0.015)), "Shell.Explorer").Value
    IMG.Navigate("about:blank")
    IMG.document.write(imgHTML)

    guiObj.Show("x0 y0 NoActivate w" . percentWidth(1) . " h" . percentHeight(1))
}

; activates the load screen
;
; retuns null
activateLoadScreen() {
	if (WinShown(GUILOADTITLE)) {
		WinActivate(GUILOADTITLE)
	}
}

; destroys the load screen
;
; returns null
destroyLoadScreen() {
    globalStatus["loadscreen"]["enable"] := false
    globalStatus["loadscreen"]["overrideWNDW"] := ""

    if (getGUI(GUILOADTITLE)) {
        getGUI(GUILOADTITLE).Destroy()
    }
}

; sets the text of the load screen & activates it
;  text - new load screen text
;
; returns null
setLoadScreen(text) {
	global globalConfig
	global globalStatus

    MouseMove(percentWidth(1, false), percentHeight(1, false))

    globalStatus["loadscreen"]["enable"] := true
    globalStatus["loadscreen"]["show"] := true
    globalStatus["loadscreen"]["text"] := text
}

; resets the text of the load screen & deactivates it
;
; returns null
resetLoadScreen() {
	global globalStatus

	globalStatus["loadscreen"]["show"] := false
	globalStatus["loadscreen"]["overrideWNDW"] := ""
	SetTimer(DelayResetText.Bind(globalStatus["loadscreen"]["text"]), -1000)

	return

	DelayResetText(currText) {
		global globalConfig

		; don't reset if the text has been changed by another loadText update
		if (globalStatus["loadscreen"]["text"] != currText) {
			return
		}

		globalStatus["loadscreen"]["text"] := (globalConfig["GUI"].Has("DefaultLoadText")) 
			? globalConfig["GUI"]["DefaultLoadText"] : "Now Loading..."

		return
	}
}