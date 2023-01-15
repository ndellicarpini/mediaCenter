class LoadScreenInterface extends Interface {
    __New(text) {
        super.__New(INTERFACES["loadscreen"]["wndw"], GUI_OPTIONS)

        this.guiObj.BackColor := COLOR1
        this.guiObj.marginX := percentWidth(0.01, false)

        this.SetFont("italic s30")
        this.Add("Text", "vLoadText Right 0x200 xm0 w" . (percentWidth(1) - percentWidth(0.03, false)), text)

        this.guiObj["LoadText"].GetPos(&X, &Y, &W, &H)
        this.guiObj["LoadText"].Move(X, (percentHeight(1) - percentWidth(0.01, false) - H), W, H)
    }

    Show() {
        super.Show("x0 y0 NoActivate w" . percentWidth(1) . " h" . percentHeight(1))
    }

    select() {
        return
    }

    back() {
        return
    }

    updateText(text) {
        this.guiObj["LoadText"].Text := text
        this.guiObj["LoadText"].Redraw()
    }
}

; activates the load screen
;
; retuns null
activateLoadScreen() {
	if (WinShown(INTERFACES["loadscreen"]["wndw"])) {
		WinActivate(INTERFACES["loadscreen"]["wndw"])
	}
}

; destroys the load screen
;
; returns null
destroyLoadScreen() {
    global globalStatus
    global globalGuis

    globalStatus["loadscreen"]["enable"] := false
    globalStatus["loadscreen"]["overrideWNDW"] := ""

    if (globalGuis.Has("loadscreen")) {
        globalGuis["loadscreen"].Destroy()
        globalGuis.Delete("loadscreen")
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