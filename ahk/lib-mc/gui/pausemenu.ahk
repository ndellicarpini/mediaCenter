#Include std.ahk

createPauseMenu() {
    global

    guiObj := Gui.New(GUIOPTIONS . " +AlwaysOnTop", GUIPAUSETITLE)
    guiObj.BackColor := COLOR1

    guiObj.Show("y0 x0 w" . percentWidth(0.3) . " h" . percentHeight(1))
}