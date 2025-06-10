class NotificationInterface extends Interface {
    id := "notification"
    title := INTERFACES["notification"]["wndw"]

    allowFocus := false
    marginX := this._calcPercentWidth(0.015)
    marginY := this._calcPercentHeight(0.015)

    timeout := 0

    ; valid values for position
    ; top-left
    ; top-right
    ; bottom-left
    ; bottom-right
    position := "bottom-right"

    __New(message, timeout := 0, position := "bottom-right") {
        super.__New(GUI_OPTIONS . " +AlwaysOnTop +Disabled +ToolWindow +E0x20")
        
        this.timeout := timeout
        this.position := position
        
        this.guiObj.BackColor := COLOR1

        this.SetFont("bold s24")
        this.guiObj.MarginX := this.marginX
        this.guiObj.MarginY := this.marginY

        this.Add("Text", "vMessage Center 0x200", message)
    }

    _Show() {
        this.guiObj["Message"].GetPos(,, &W, &H)

        guiWidth := W + (this.marginX * 2)
        guiHeight := H + (this.marginY * 2)

        offset := ""
        switch (this.position) {
            case "top-left":
                offset := "x" . (this._calcPercentWidth(0.01, false, false)) . " y" . (this._calcPercentWidth(0.01, false, false))
            case "top-right":
                offset := "x" . (this._calcPercentWidth(0.99, false, false) - guiWidth) . " y" . (this._calcPercentWidth(0.01, false, false))
            case "bottom-left":
                offset := "x" . (this._calcPercentWidth(0.01, false, false)) . " y" . (this._calcPercentHeight(1) - this._calcPercentWidth(0.01, false, false) - guiHeight)
            case "bottom-right":
                offset := "x" . (this._calcPercentWidth(0.99, false, false) - guiWidth) . " y" . (this._calcPercentHeight(1) - this._calcPercentWidth(0.01, false, false) - guiHeight)
        }
    
        super._Show("NoActivate AutoSize " . offset)
        WinSetTransparent(230, this.title)

        if (this.timeout != 0) {
            SetTimer(MsgCloseTimer, Neg(this.timeout))
        }

        return

        MsgCloseTimer() {
            if (WinShown(this.title)) {
                this.Destroy()
            }

            return
        }
    }
}