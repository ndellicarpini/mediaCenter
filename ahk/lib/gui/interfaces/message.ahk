class MessageInterface extends Interface {
    allowFocus := true

    timeout := 0

    __New(message, timeout := 0) {
        super.__New(INTERFACES["message"]["wndw"], "+AlwaysOnTop " . GUI_OPTIONS)

        this.timeout := timeout
        
        this.guiObj.BackColor := COLOR1

        this.SetFont()
        this.Add("Text", "Center 0x200", message)
    }

    Show() {
        super.Show("Center AutoSize")

        if (this.timeout > 0) {
            SetTimer(MsgCloseTimer, -1 * this.timeout)
        }

        return

        MsgCloseTimer() {
            if (WinShown(INTERFACES["message"]["wndw"])) {
                this.Destroy()
            }

            return
        }
    }

    select() {
        this.Destroy()
    }
}