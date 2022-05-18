global GUICHOICETITLE := "AHKGUICHOICE"

createChoiceDialog(text, lText := "Cancel", lFunc := "", lColor := "", rText := "OK", rFunc := "", rColor := "") {
    global globalConfig
    global globalGuis

    destroyPauseMenu(false)

    if (lColor = "") {
        lColor := COLOR2
    }
    if (rColor = "") {
        rColor := "30BF30"
    }

    createInterface(GUICHOICETITLE, GUIOPTIONS . " +AlwaysOnTop +Overlay000000",,, true, false, "current")
    choiceInt := globalGuis[GUICHOICETITLE]

    choiceInt.unselectColor := COLOR1
    choiceInt.selectColor   := COLOR3

    choiceInt.guiObj.BackColor := COLOR1

    guiWidth  := percentWidth(0.2)
    guiHeight := percentHeight(0.2)

    marginSize := (guiWidth * (2/60))
    choiceInt.guiObj.MarginX := marginSize
    choiceInt.guiObj.MarginY := marginSize

    guiSetFont(choiceInt, "norm s24")
    choiceInt.Add("Text", "Center BackgroundTrans xm0 ym0 w" . (guiWidth - (2 * marginSize)), text) 
    
    guiSetFont(choiceInt, "bold s24")
    choiceInt.Add("Text", "vLeft f(" . lFunc . ") Center 0x200 Background" . lColor . " xpos1 ypos1 xm0 y" . (guiHeight * 0.75) . " w" . (guiWidth * 0.4) . " h" . ((guiHeight * 0.25) - marginSize), lText) 
    choiceInt.Add("Text", "vRight f(" . rFunc . ") Center 0x200 Background" . rColor . " xpos2 ypos1 yp0 x" . (guiWidth * 0.575) . " hp0 wp0", rText) 

    choiceInt.Show("Center w" . guiWidth . " h" . guiHeight)
}