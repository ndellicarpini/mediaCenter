#Include std.ahk

; creates the pause screen
;
; returns null
createPauseMenu() {
    ; TODO - fix weirdness with closing pause screen

    guiObj := Gui.New(GUIOPTIONS . " +AlwaysOnTop", GUIPAUSETITLE)
    guiObj.BackColor := COLOR1
    guiObj.MarginX := percentWidth(0.01)
    guiObj.MarginY := percentHeight(0.01)

    guiWidth := percentWidth(0.25)
    guiHeight := percentHeight(1)

    ; add static elements
    currentTimeArr := StrSplit(FormatTime(, "h:mm tt`ndddd, MMM d yyy"), "`n")

    guiSetFont(guiObj, "s50")
    guiObj.Add("Text", "vTime Section Center xm0 ym10 w" . (guiWidth * 0.46), currentTimeArr[1])

    guiSetFont(guiObj)
    guiObj.Add("Text", "vDate Center wp0 xm0 y+" . percentHeight(0.008), currentTimeArr[2])

    guiObj.Add("Text", "Section vInfoText x+" . percentWidth(0.015) . " ys+5", "CPU")
    guiObj.Add("Text", "xs0 y+" . percentHeight(0.008), "RAM")

    if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
        guiObj.Add("Text", "xs0 y+" . percentHeight(0.008), "GPU")
    }

    SetTimer "PauseSecondTimer", 1000

    ; SHOW GUI
    guiObj.Show("y0 x0 w" . guiWidth . " h" . guiHeight)
    
    ; add progress bars after render to properly calculate width
    ControlGetPos infoX,, infoW,, guiObj["InfoText"].Hwnd, GUIPAUSETITLE
    progressX := infoX + infoW + percentWidth(0.008)

    guiObj.Add("Progress", "vCPU Background" . COLOR2 . " c" . COLOR3 . " hp0 w" . (guiWidth - progressX - guiObj.MarginX) . " x" . progressX . " ys0", 0)
    guiObj.Add("Progress", "vRAM Background" . COLOR2 . " c" . COLOR3 . " hp0 wp0 xp0 y+" . percentHeight(0.008), 0)

    if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
        guiObj.Add("Progress", "vGPU Background" . COLOR2 . " c" . COLOR3 . " hp0 wp0 xp0 y+" . percentHeight(0.008), 0)
    }

}

; destroys the pause screen
;
; returns null
destroyPauseMenu() {
    SetTimer "PauseSecondTimer", 0
    
    if (getGUI(GUIPAUSETITLE)) {
        getGUI(GUIPAUSETITLE).Destroy()
    }
}

; TIMER TRIGGERED EACH SECOND IN PAUSE MENU
; this timer is actually used in mainThread for performance reasons
PauseSecondTimer() {
    pauseObj := getGUI(GUIPAUSETITLE)

    if (pauseObj) {
        currentTimeArr := StrSplit(FormatTime(, "h:mm tt`ndddd, MMM d yyy"), "`n")

        try {
            pauseObj["Time"].Text := currentTimeArr[1]
            pauseObj["Date"].Text := currentTimeArr[2]

            pauseObj["CPU"].Value := Ceil(getCpuLoad())
            pauseObj["RAM"].Value := Ceil(getRamLoad())

            if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
                pauseObj["GPU"].Value := Ceil(getNvidiaLoad())
            }
        }
    }
    
    return
}