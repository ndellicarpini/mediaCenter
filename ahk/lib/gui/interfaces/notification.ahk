class NotificationInterface extends Interface {
    id := "notification"
    title := INTERFACES["notification"]["wndw"]

    allowFocus := false
    marginX := percentWidth(0.015, false)
    marginY := percentHeight(0.015, false)

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
                offset := "x" . percentWidth(0.01, false) . " y" . percentWidth(0.01, false)
            case "top-right":
                offset := "x" . (percentWidth(0.99, false) - guiWidth) . " y" . percentWidth(0.01, false)
            case "bottom-left":
                offset := "x" . percentWidth(0.01, false) . " y" . (percentHeight(1) - percentWidth(0.01, false) - guiHeight)
            case "bottom-right":
                offset := "x" . (percentWidth(0.99, false) - guiWidth) . " y" . (percentHeight(1) - percentWidth(0.01, false) - guiHeight)
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