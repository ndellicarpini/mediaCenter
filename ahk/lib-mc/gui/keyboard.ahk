global GUIKEYBOARDTITLE := "AHKGUIKEYBOARD"

guiKeyboard() {
    global globalGuis
    global globalRunning

    currProgram := getStatusParam("currProgram")

    createInterface(GUIKEYBOARDTITLE, GUIOPTIONS . " +AlwaysOnTop",, Map(),,, false,, "destroyKeyboard")
    kbInt := globalGuis[GUIKEYBOARDTITLE]

    if (getStatusParam("kbmmode")) {
        kbInt.hotkeys := addHotkeys(kbmmodeHotkeys(), kbInt.hotkeys)
        kbInt.mouse := kbmmodeMouse()
    }
    else if (currProgram != "" && globalRunning.Has(currProgram)) {
        currHotkeys := kbInt.hotkeys
        currHotkeys := addHotkeys(globalRunning[currProgram].hotkeys, currHotkeys)

        kbInt.hotkeys := currHotkeys
        kbInt.mouse := globalRunning[currProgram].mouse
    }

    kbInt.selectColor := COLOR3

    kbInt.guiObj.BackColor := COLOR1
    kbInt.guiObj.MarginX := percentWidth(0.02)
    kbInt.guiObj.MarginY := percentWidth(0.02)

    guiWidth := percentWidth(0.38)
    guiHeight := (guiWidth / 21) * 9

    kbInt.Show("NoActivate x" . (percentWidth(0.5, false) - (guiWidth / 2)) . " y" . percentHeight(0.5, false) . " w" . guiWidth . " h" . guiHeight)
    WinSetTransparent(230, GUIKEYBOARDTITLE)
    OnMessage(0x201, GrabKeyboard)
}

guiKeyboardButton(kbInt, text, color, x, y, w, h) {

}

destroyKeyboard() {
    global globalGuis

    if (getGUI(GUIKEYBOARDTITLE)) {
        OnMessage(0x201, GrabKeyboard, 0)
        globalGuis[GUIKEYBOARDTITLE].guiObj.Destroy()
    }
}

GrabKeyboard(wParam, lParam, msg, hwnd) {
    PostMessage(0xA1, 2)
}