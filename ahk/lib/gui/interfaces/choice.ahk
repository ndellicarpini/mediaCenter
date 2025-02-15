class ChoiceInterface extends Interface {
    id := "choice"
    title := INTERFACES["choice"]["wndw"]

    guiWidth := 0
    guiHeight := 0

    __New(text, lText := "Cancel", lFunc := "", lColor := "", rText := "OK", rFunc := "", rColor := "") {
        global globalConfig
        global globalGuis

        if (lColor = "") {
            lColor := COLOR2
        }
        if (rColor = "") {
            rColor := "30BF30"
        }

        super.__New(GUI_OPTIONS . " +AlwaysOnTop +Overlay000000")

        this.unselectColor := COLOR1
        this.selectColor   := COLOR3

        this.guiObj.BackColor := COLOR1

        this.guiWidth  := interfaceWidth(0.2)
        this.guiHeight := interfaceHeight(0.2)

        marginSize := (this.guiWidth * (2/60))
        this.guiObj.MarginX := marginSize
        this.guiObj.MarginY := marginSize

        this.SetFont("norm s24")
        this.Add("Text", "Center BackgroundTrans xm0 ym0 w" . (this.guiWidth - (2 * marginSize)), text) 
        
        this.SetFont("bold s24")
        this.Add("Text", "vLeft f(" . lFunc . ") Center 0x200 Background" . lColor . " xpos1 ypos1 xm0 y" . (this.guiHeight * 0.75) . " w" . (this.guiWidth * 0.4) . " h" . ((this.guiHeight * 0.25) - marginSize), lText) 
        this.Add("Text", "vRight f(" . rFunc . ") Center 0x200 Background" . rColor . " xpos2 ypos1 yp0 x" . (this.guiWidth * 0.575) . " hp0 wp0", rText) 
    }

    _Show() {
        guiX := ((MONITOR_W / 2) - (this.guiWidth / 2))
        guiY := ((MONITOR_H / 2) - (this.guiHeight / 2))
        super._Show("x" . guiX . " y" . guiY . " w" . this.guiWidth . " h" . this.guiHeight)
    }

    _select() {
        super._select()
        this.Destroy()
    }

    _back() {
        return
    }
}