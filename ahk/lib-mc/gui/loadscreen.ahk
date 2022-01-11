#Include std.ahk

; creates & shows the load screen
;  loadText - text to show on load screen
;
; returns null
createLoadScreen(loadText) {
    ; TODO - maybe create some sort of load screen config (maybe just html?)

    global 

    guiObj := Gui.New(GUIOPTIONS, GUILOADTITLE)
    guiObj.BackColor := COLOR1
    guiSetFont(guiObj)

    guiObj.Add("ActiveX", "w" . percentWidth(0.1) . " h" . percentWidth(0.1), "mshtml:<img src=E:\Documents\GitHub\mediaCenter\assets\loading-compressed.gif />")
    guiObj.Add("Text", "Center w" . percentWidth(1), loadText)

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