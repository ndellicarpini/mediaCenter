global GUICONTROLLERTITLE := "AHKGUICONTROLLER"

createControllerMenu() {
    global globalConfig
    global globalGuis

    createInterface(GUICONTROLLERTITLE, GUIOPTIONS . " +AlwaysOnTop",, Map("B", "gui.Destroy"), true)
    controllerInt := globalGuis[GUICONTROLLERTITLE]

    controllerInt.unselectColor := COLOR1
    controllerInt.selectColor := COLOR3

    controllerInt.guiObj.BackColor := COLOR1
    controllerInt.guiObj.MarginX := percentHeight(0.01)
    controllerInt.guiObj.MarginY := percentHeight(0.01)

    guiWidth  := percentWidth(0.2)
    guiHeight := percentHeight(0.165)
    maxHeight := percentHeight(0.5)

    guiSetFont(controllerInt, "bold s24")
    controllerInt.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 ym5 h" . percentHeight(0.05) . " w" . (guiWidth - percentHeight(0.02)), "Controller Info")

    


    controllerInt.Show("y0 x" . percentWidth(0.25) . " w" . guiWidth . " h" . guiHeight)
}