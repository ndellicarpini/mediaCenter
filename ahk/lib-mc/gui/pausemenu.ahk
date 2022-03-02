; creates the pause screen
;  currProgram - current program
;  mainGuis - current guis
;
; returns null
createPauseMenu(currProgram, mainGuis) {
    createInterface(mainGuis, GUIPAUSETITLE, GUIOPTIONS . " +AlwaysOnTop",, Map("B", "Pause"), true)
    pauseInt := mainGuis[GUIPAUSETITLE]

    pauseInt.unselectColor := COLOR1
    pauseInt.selectColor := COLOR3

    pauseInt.guiObj.BackColor := COLOR1
    pauseInt.guiObj.MarginX := percentWidth(0.0095)
    pauseInt.guiObj.MarginY := percentHeight(0.01)

    guiWidth := percentWidth(0.25)
    guiHeight := percentHeight(1)

    ; add static elements
    currentTimeArr := StrSplit(FormatTime(, "h:mm tt`ndddd, MMM d yyy"), "`n")

    ; --- ADD TIME & DATE --- 
    guiSetFont(pauseInt, "s50")
    pauseInt.Add("Text", "vTime Section Center xm0 ym10 w" . (guiWidth * 0.46), currentTimeArr[1])

    guiSetFont(pauseInt)
    pauseInt.Add("Text", "vDate Center wp0 xm0 y+" . percentHeight(0.008), currentTimeArr[2])

    ; --- ADD MONITORS ---
    pauseInt.Add("Text", "vInfoText Section x+" . percentWidth(0.010) . " ys+5", "CPU")
    pauseInt.Add("Text", "xs0 y+" . percentHeight(0.008), "RAM")

    if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
        pauseInt.Add("Text", "xs0 y+" . percentHeight(0.008), "GPU")
    }

    pauseInt.Add("Progress", "vCPU Background" . COLOR2 . " c" . COLOR3 . " hp0 w" . percentWidth(0.078) " ys0 x+" . percentWidth(0.006), 0)
    pauseInt.Add("Progress", "vRAM Background" . COLOR2 . " c" . COLOR3 . " hp0 wp0 xp0 y+" . percentHeight(0.008), 0)

    if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
        pauseInt.Add("Progress", "vGPU Background" . COLOR2 . " c" . COLOR3 . " hp0 wp0 xp0 y+" . percentHeight(0.008), 0)
    }

    ; --- ADD TOP ROW BUTTONS ---
    buttonSpacing := percentWidth(0.0097)

    pauseInt.Add("Picture", "vHome Section xpos1 ypos1 xm0 y+" . percentHeight(0.03) . " w" . percentWidth(0.039) . " h" . percentHeight(0.07), getAssetPath("icons\gui\home.png"))
    pauseInt.Add("Picture", "vVolume xpos2 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\volume.png"))
    pauseInt.Add("Picture", "vControllers xpos3 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\controller.png"))
    pauseInt.Add("Picture", "vMulti xpos4 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\multitasking.png"))
    pauseInt.Add("Picture", "vPower xpos5 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\power.png"))

    ; --- ADD PAUSE OPTIONS ---
    defaultOptions := defaultPauseOptions()
    programOptions := programPauseOptions(currProgram)

    optionWidth := guiWidth - (2 * percentWidth(0.0095))
    optionHeight := percentHeight(0.05)

    y_index := 1

    ; program options
    if (programOptions.Count > 0) {
        guiSetFont(pauseInt, "bold s30")
        pauseInt.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 y+" . percentHeight(0.03) . " h" . optionHeight . " w" . optionWidth, "Current Program: " . getStatusParam("currProgram"))
    
        guiSetFont(pauseInt, "s20")

        for key, value in programOptions {
            pauseInt.Add("Text", "v" . key . " f(" . value.function . ") 0x200 ypos" . toString(y_index + 1) . " xm0 y+" . percentHeight(0.005) . " h" . optionHeight . " w" . optionWidth, value.title)
            y_index += 1
        }
    }

    ; global options
    if (defaultOptions.Count > 0) {
        guiSetFont(pauseInt, "bold s30")
        pauseInt.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 y+" . percentHeight(0.03) . " h" . optionHeight . " w" . optionWidth, "Options")
    
        guiSetFont(pauseInt, "s20")

        for key, value in defaultOptions {
            pauseInt.Add("Text", "v" . key . " f(" . value.function . ") 0x200 ypos" . toString(y_index + 1) . " xm0 y+" . percentHeight(0.005) . " h" . optionHeight . " w" . optionWidth, value.title)
            y_index += 1
        }
    }

    ; --- SHOW GUI ---
    pauseInt.Show("y0 x0 w" . guiWidth . " h" . guiHeight)

    SetTimer(PauseSecondTimer, 1000)
    PauseSecondTimer()
}

; destroys the pause screen
;  mainGuis - current guis 
;
; returns null
destroyPauseMenu(mainGuis) {
    SetTimer(PauseSecondTimer, 0)
    
    mainGuis[GUIPAUSETITLE].Destroy()
}

; adds default to pause options based on selected options from global config
;  currOptions - current options map to add default to
;  currKeys - current key array used to maintain user defined order
; 
; returns current options + default options
defaultPauseOptions() {
    defaultOptions := Map()
    defaultOptions["WinSettings"] := {title: "Windows Settings", function: "runWinSettings"}
    defaultOptions["Settings"] := {title: "Script Settings", function: "createSettingsGui config\global.cfg"}
    
    if (!getStatusParam("KBMMode")) {
        defaultOptions["KBMMode"] := {title: "Enable KB & Mouse Mode", function: "updateKBMM"}
    }
    else {
        defaultOptions["KBMMode"] := {title: "Disable KB & Mouse Mode", function: "updateKBMM"}
    }

    if (!getStatusParam("suspendScript")) {
        defaultOptions["Suspend"] := {title: "Suspend All Scripts", function: "updateSuspendScript"}
    }
    else {
        defaultOptions["Suspend"] := {title: "Resume All Scripts", function: "updateSuspendScript"}
    }

    if (globalConfig["GUI"].Has("DefaultPauseOptions") && IsObject(globalConfig["GUI"]["DefaultPauseOptions"])) {
        globalOptions := globalConfig["GUI"]["DefaultPauseOptions"]

        for item in globalOptions {           
            if (!defaultOptions.Has(item)) {
                defaultOptions.Delete(item)
            }
        }
    }

    return defaultOptions
}

; adds program pause options
;  currProgram = program to get pause options from
; 
; returns program pause settings
programPauseOptions(currProgram) {   
    programOptions := Map()

    if (currProgram != "") {
        for key, value in currProgram.pauseOptions {
            programOptions[StrReplace(value, A_Space, "")] := {title: key, function: value}
        }    
    }

    return programOptions
}

; timer triggered each second while pause menu is open
; updates the time & monitors
PauseSecondTimer() {
    pauseObj := getGUI(GUIPAUSETITLE)

    if (pauseObj) {
        currentTimeArr := StrSplit(FormatTime(, "h:mm tt`ndddd, MMM d yyy"), "`n")

        try {
            pauseObj["Time"].Text := currentTimeArr[1]
            pauseObj["Date"].Text := currentTimeArr[2]

            ; MsgBox(getCpuLoad())
            pauseObj["CPU"].Value := Ceil(getCpuLoad())
            pauseObj["RAM"].Value := Ceil(getRamLoad())

            if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
                pauseObj["GPU"].Value := Ceil(getNvidiaLoad())
            }
        }
    }
    
    return
}