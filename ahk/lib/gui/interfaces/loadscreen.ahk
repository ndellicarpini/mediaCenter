class LoadScreenInterface extends Interface {
    id := "loadscreen"
    title := INTERFACES["loadscreen"]["wndw"]

    controlsVisible := true
    _restoreControlsList := []

    __New(text) {
        super.__New(GUI_OPTIONS)

        this.guiObj.BackColor := COLOR1
        this.guiObj.marginX := this._calcPercentWidth(0.01)

        this.SetFont("italic s30")
        this.Add("Text", "vLoadText Right 0x200 xm0 w" . (this._calcPercentWidth(1) - this._calcPercentWidth(0.03, false)), text)

        this.guiObj["LoadText"].GetPos(&X, &Y, &W, &H)
        this.guiObj["LoadText"].Move(X, (this._calcPercentHeight(1) - this._calcPercentWidth(0.01, false) - H), W, H)
    }

    _Show() {
        super._Show("x0 y0 NoActivate w" . this._calcPercentWidth(1) . " h" . this._calcPercentHeight(1))
    }

    _select() {
        return
    }

    _back() {
        return
    }

    updateText(text) {
        this.guiObj["LoadText"].Text := text
        this.guiObj["LoadText"].Redraw()
    }

    restoreControls() {
        this.guiObj.BackColor := COLOR1

        index := 1
        for key, value in this.guiObj {
            if (!value.Visible && inArray(index, this._restoreControlsList)) {
                value.Visible := true
            }

            index += 1
        }

        this.controlsVisible := true
        this._restoreControlsList := []
    }

    hideControls() {
        this.guiObj.BackColor := "000000"

        index := 1
        for key, value in this.guiObj {
            if (value.Visible) {
                value.Visible := false
                this._restoreControlsList.Push(index)
            }

            index += 1
        }

        this.controlsVisible := false
    }
}

; activates the load screen
;
; retuns null
activateLoadScreen() {
	if (WinShown(INTERFACES["loadscreen"]["wndw"])) {
		try WinActivateForeground(INTERFACES["loadscreen"]["wndw"])
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

; hides the load screen
;
; returns null
hideLoadScreen() {
    global globalStatus
    global globalGuis

    globalStatus["loadscreen"]["enable"] := false
    globalStatus["loadscreen"]["overrideWNDW"] := ""

    if (globalGuis.Has("loadscreen")) {
        globalGuis["loadscreen"].Hide()
    }
}

; sets the text of the load screen & activates it
;  text - new load screen text
;
; returns null
setLoadScreen(text := "") {
	global globalConfig
	global globalStatus
    global globalGuis

    if (globalStatus["suspendScript"] || globalStatus["desktopmode"]) {
        return
    }

    if (globalGuis.Has("pause")) {
        try globalGuis["pause"].Destroy()
    }

    HideMouseCursor()

    globalStatus["loadscreen"]["enable"] := true
    globalStatus["loadscreen"]["show"] := true

    if (text != "") {
        globalStatus["loadscreen"]["text"] := text
    }
    else {
        globalStatus["loadscreen"]["text"] := (globalConfig["GUI"].Has("DefaultLoadText")) 
            ? globalConfig["GUI"]["DefaultLoadText"] : "Now Loading..."
    }
}

; resets the text of the load screen & deactivates it
;  delay - delays updating the load text
;
; returns null
resetLoadScreen(delay := 1000) {
	global globalStatus

	globalStatus["loadscreen"]["show"] := false
	globalStatus["loadscreen"]["overrideWNDW"] := ""

    if (delay = 0) {
        ResetText(globalStatus["loadscreen"]["text"])
    }
    else {
        SetTimer(ResetText.Bind(globalStatus["loadscreen"]["text"]), Neg(delay))
    }

	return

	ResetText(currText) {
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