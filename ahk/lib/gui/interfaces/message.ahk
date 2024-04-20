class MessageInterface extends Interface {
    id := "message"
    title := INTERFACES["message"]["wndw"]

    allowFocus := true

    timeout := 0

    __New(message, timeout := 0) {
        super.__New("+AlwaysOnTop " . GUI_OPTIONS)

        this.timeout := timeout
        
        this.guiObj.BackColor := COLOR1

        this.SetFont()
        this.Add("Text", "Center 0x200", message)
    }

    _Show() {
        super._Show("Center AutoSize")

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

    _select() {
        this.Destroy()
    }
}