global GUIPAUSETITLE := "AHKGUIPAUSE"

; creates the pause screen
;  currProgram - current program
;  globalGuis - current guis
;
; returns null
createPauseMenu() {
    global globalConfig
    global globalPrograms
    global globalGuis

    createInterface(GUIPAUSETITLE, GUIOPTIONS . " +AlwaysOnTop",, Map("B", "Pause"), true, "count-current", "setStatusParam pause 0", true)
    pauseInt := globalGuis[GUIPAUSETITLE]

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
    guiSetFont(pauseInt, "s38")
    pauseInt.Add("Text", "vTime Section Center xm0 ym0 w" . (guiWidth * 0.46), currentTimeArr[1])

    guiSetFont(pauseInt)
    pauseInt.Add("Text", "vDate Center wp0 xm0 y+" . percentHeight(0.008), currentTimeArr[2])

    ; --- ADD MONITORS ---
    if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
        monitorSpacing := percentHeight(0.008)

        pauseInt.Add("Text", "vInfoText Section x+" . percentWidth(0.010) . " ys+5", "CPU")
        pauseInt.Add("Text", "xs0 y+" . monitorSpacing, "RAM")
        pauseInt.Add("Text", "xs0 y+" . monitorSpacing, "GPU")

        pauseInt.Add("Progress", "vCPU Background" . COLOR2 . " c" . COLOR3 . " hp0 w" . percentWidth(0.078) . " ys0 x+" . percentWidth(0.006), 0)
        pauseInt.Add("Progress", "vRAM Background" . COLOR2 . " c" . COLOR3 . " hp0 wp0 xp0 y+" . monitorSpacing, 0)
        pauseInt.Add("Progress", "vGPU Background" . COLOR2 . " c" . COLOR3 . " hp0 wp0 xp0 y+" . monitorSpacing, 0)
    }
    else {
        monitorSpacing := percentHeight(0.038)

        pauseInt.Add("Text", "vInfoText Section x+" . percentWidth(0.010) . " ys+5", "CPU")
        pauseInt.Add("Text", "xs0 y+" . monitorSpacing, "RAM")

        pauseInt.Add("Progress", "vCPU Background" . COLOR2 . " c" . COLOR3 . " hp0 w" . percentWidth(0.078) " ys0 x+" . percentWidth(0.006), 0)
        pauseInt.Add("Progress", "vRAM Background" . COLOR2 . " c" . COLOR3 . " hp0 wp0 xp0 y+" . monitorSpacing, 0)
    }

    ; --- ADD TOP ROW BUTTONS ---
    if (globalConfig["Programs"].Has("Default") && globalConfig["Programs"]["Default"] != "") {
        buttonSpacing := percentWidth(0.0097)

        pauseInt.Add("Picture", "vHome Section f(defaultProgramOpen) xpos1 ypos1 xm0 y+" . percentHeight(0.02) . " w" . percentWidth(0.039) . " h" . percentHeight(0.07), getAssetPath("icons\gui\home.png", globalConfig))
        pauseInt.Add("Picture", "vVolume f(createVolumeMenu) xpos2 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\volume.png", globalConfig))
        pauseInt.Add("Picture", "vControllers xpos3 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\controller.png", globalConfig))
        pauseInt.Add("Picture", "vMulti xpos4 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\multitasking.png", globalConfig))
        pauseInt.Add("Picture", "vPower xpos5 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\power.png", globalConfig))
    
    }
    else {
        buttonSpacing := percentWidth(0.0257)

        pauseInt.Add("Picture", "vVolume Section f(createVolumeMenu) xpos1 ypos1 xm0 y+" . percentHeight(0.02) . " w" . percentWidth(0.039) . " h" . percentHeight(0.07), getAssetPath("icons\gui\volume.png", globalConfig))
        pauseInt.Add("Picture", "vControllers xpos2 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\controller.png", globalConfig))
        pauseInt.Add("Picture", "vMulti xpos3 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\multitasking.png", globalConfig))
        pauseInt.Add("Picture", "vPower xpos4 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\power.png", globalConfig))
    }


    ; --- ADD PAUSE OPTIONS ---
    currProgram := getStatusParam("currProgram")

    defaultOptions := defaultPauseOptions()
    programOptions := programPauseOptions((currProgram != "") ? globalRunning[currProgram] : "")

    optionWidth := guiWidth - (2 * percentWidth(0.0095))
    optionHeight := percentHeight(0.045)

    y_index := 1

    ; program options
    if (programOptions.items.Count > 0) {
        guiSetFont(pauseInt, "bold s24")
        pauseInt.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 y+" . percentHeight(0.02) . " h" . percentHeight(0.05) . " w" . optionWidth, getStatusParam("currProgram"))
    
        guiSetFont(pauseInt, "norm s20")
        
        for item in programOptions.order {
            if (programOptions.items.Has(item)) {
                pauseInt.Add("Text", "v" . item . " f(" . programOptions.items[item].function . ") 0x200 ypos" . toString(y_index + 1) . " xm0 y+" . percentHeight(0.007) . " h" . optionHeight . " w" . optionWidth, "  " . programOptions.items[item].title)
                y_index += 1
            }
        }
    }

    ; global options
    if (defaultOptions.items.Count > 0) {
        guiSetFont(pauseInt, "bold s23")
        pauseInt.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 y+" . percentHeight(0.02) . " h" . percentHeight(0.05) . " w" . optionWidth, "Options")
    
        guiSetFont(pauseInt, "norm s19")

        for item in defaultOptions.order {
            if (defaultOptions.items.Has(item)) {
                pauseInt.Add("Text", "v" . item . " f(" . defaultOptions.items[item].function . ") 0x200 ypos" . toString(y_index + 1) . " xm0 y+" . percentHeight(0.007) . " h" . optionHeight . " w" . optionWidth, "  " . defaultOptions.items[item].title)
                y_index += 1
            }
        }
    }

    ; --- SHOW GUI ---
    pauseInt.Show("y0 x0 w" . guiWidth . " h" . guiHeight)

    SetTimer(PauseSecondTimer, 1000)
    PauseSecondTimer()
}

; destroys the pause screen
;  globalGuis - current guis 
;
; returns null
destroyPauseMenu() {
    global globalGuis

    SetTimer(PauseSecondTimer, 0)
    
    globalGuis[GUIPAUSETITLE].guiObj.Destroy()
}

; adds default to pause options based on selected options from global config
;  currOptions - current options map to add default to
;  currKeys - current key array used to maintain user defined order
; 
; returns current options + default options
defaultPauseOptions() {
    global globalConfig

    defaultOptions := Map()
    defaultOptions["WinSettings"] := {title: "Windows Settings", function: "runWinSettings"}
    defaultOptions["Settings"] := {title: "Script Settings", function: "createSettingsGui config\global.cfg"}
    
    currKBMMode := getStatusParam("kbmmode")
    currSuspend := getStatusParam("suspendScript")

    defaultOptions["KBMMode"] := {
        title: (!currKBMMode) ? "Enable KB && Mouse Mode" : "Disable KB && Mouse Mode", 
        function: "setStatusParam kbmmode " . !currKBMMode
    }

    defaultOptions["Suspend"] := {
        title: (!currSuspend) ? "Suspend Program Scripts" : "Resume Program Scripts", 
        function: "setStatusParam suspendScript " . !currSuspend
    }

    if (globalConfig["GUI"].Has("DefaultPauseOptions") && IsObject(globalConfig["GUI"]["DefaultPauseOptions"])) {
        globalOptions := globalConfig["GUI"]["DefaultPauseOptions"]

        for item in globalOptions {           
            if (!defaultOptions.Has(item)) {
                defaultOptions.Delete(item)
            }
        }
    }

    return {order: globalOptions, items: defaultOptions}
}

; adds program pause options
;  currProgram = program to get pause options from
; 
; returns program pause settings
programPauseOptions(currProgram) {   
    programOptions := Map()

    if (currProgram = "") {
        return {items: Map()}
    }

    if (currProgram != "") {
        for key, value in currProgram.pauseOptions {
            programOptions[RegExReplace(value, "[^a-zA-Z\d]*", "")] := {title: key, function: value}
        }    
    }

    programOrder := []
    if (currProgram.pauseOrder.Length > 0) {
        for item in currProgram.pauseOrder {
            for key, value in programOptions {
                if (item = value.title) {
                    programOrder.Push(key)
                    break
                }
            }
        }
    }
    else {
        for key, value in programOptions {
            programOrder.Push(key)
        }
    }

    ; add exit
    programOptions["currProgramExit"] := {title: "Exit", function: "currProgramExit"}
    programOrder.Push("currProgramExit")

    return {order: programOrder, items: programOptions}
}

; exits the current program
;
; returns null
currProgramExit() {
    global globalRunning

    globalRunning[getStatusParam("currProgram")].exit()
}

; runs/restores the default program
;
; returns null
defaultProgramOpen() {
    global globalConfig
    global globalRunning

    if (globalConfig["Programs"].Has("Default") && globalConfig["Programs"]["Default"] != "") {
        defaultProgram := globalConfig["Programs"]["Default"]

        if (globalRunning.Has(defaultProgram)) {
            globalRunning[defaultProgram].restore()
        }
        else {
            createProgram(defaultProgram, true, true)
        }
    }
}

; timer triggered each second while pause menu is open
; updates the time & monitors
PauseSecondTimer() {
    global globalConfig

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