#Include std.ahk

; creates the pause screen
;
; returns null
createPauseMenu() {
    ; TODO - fix weirdness with closing pause screen

    guiObj := Gui.New(GUIOPTIONS . " +AlwaysOnTop", GUIPAUSETITLE)
    guiObj.BackColor := COLOR1
    guiObj.MarginX := percentWidth(0.0095)
    guiObj.MarginY := percentHeight(0.01)

    guiWidth := percentWidth(0.25)
    guiHeight := percentHeight(1)

    ; add static elements
    currentTimeArr := StrSplit(FormatTime(, "h:mm tt`ndddd, MMM d yyy"), "`n")

    guiSetFont(guiObj, "s50")
    guiObj.Add("Text", "vTime Section Left xm0 ym10 w" . (guiWidth * 0.46), currentTimeArr[1])

    guiSetFont(guiObj)
    guiObj.Add("Text", "vDate Left wp0 xm0 y+" . percentHeight(0.008), currentTimeArr[2])

    guiObj.Add("Text", "Section vInfoText x+" . percentWidth(0.010) . " ys+5", "CPU")
    guiObj.Add("Text", "xs0 y+" . percentHeight(0.008), "RAM")

    if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
        guiObj.Add("Text", "xs0 y+" . percentHeight(0.008), "GPU")
    }

    guiObj.Add("Progress", "vCPU Background" . COLOR2 . " c" . COLOR3 . " hp0 w" . percentWidth(0.078) " ys0 x+" . percentWidth(0.006), 0)
    guiObj.Add("Progress", "vRAM Background" . COLOR2 . " c" . COLOR3 . " hp0 wp0 xp0 y+" . percentHeight(0.008), 0)

    if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
        guiObj.Add("Progress", "vGPU Background" . COLOR2 . " c" . COLOR3 . " hp0 wp0 xp0 y+" . percentHeight(0.008), 0)
    }

    buttonSpacing := percentWidth(0.0097)

    ; TODO - maybe just set the background color to represent selected or not, can't actually set/check focus of pictures
    guiObj.Add("Picture", "vHome Section Background" . COLOR3 . " xm0 y+" percentHeight(0.03) . " w" . percentWidth(0.039) . " h" . percentHeight(0.07), getAssetPath("icons\gui\home.png"))
    guiObj.Add("Picture", "vVolume wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\volume.png"))
    guiObj.Add("Picture", "vControllers wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\controller.png"))
    guiObj.Add("Picture", "vMulti wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\multitasking.png"))
    guiObj.Add("Picture", "vPower Background" . COLOR3 . " wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\power.png"))

    ; SHOW GUI
    guiObj.Show("y0 x0 w" . guiWidth . " h" . guiHeight)

    SetTimer "PauseSecondTimer", 1000
    PauseSecondTimer()
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