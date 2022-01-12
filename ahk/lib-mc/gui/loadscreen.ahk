#Include std.ahk

; creates & shows the load screen
;  loadText - text to show on load screen
;  loadFunc - custom function for load screen
;
; returns null
createLoadScreen(loadText, loadFunc := "") {
    ; TODO - maybe create some sort of load screen config (maybe just html?)

    global 

    guiObj := Gui.New(GUIOPTIONS, GUILOADTITLE)

    if (loadFunc != "") {
        guiObj := runFunction(loadFunc, [guiObj, loadText])
    }
    else {
        guiObj.BackColor := COLOR1
        guiSetFont(guiObj)
    }

    guiObj.Show("Center NoActivate w" . percentWidth(1) . " h" . percentHeight(1))
}

; activates & updates the text the load screen
;  loadText - new text to show on load screen
;
; returns null
activateLoadScreen(loadText) {

}

; destroys the load screen
;
; returns null
destroyLoadScreen() {

}