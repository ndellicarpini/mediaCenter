#Include std.ahk

global PAUSEOPTIONS := ""

; creates the pause screen
;
; returns null
createPauseMenu() {
    ; TODO - fix weirdness with closing pause screen

    ; TODO - move all gui creation to main, create some sort of gui.Add wrapper that keeps track of each guicontrol w/ x,y pos for moving cursor
    ; can i send a message to a gui somehow?

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

    ; add pause list
    temp := addProgramOptions()
    temp := addDefaultOptions(temp[1], temp[2])

    PAUSEOPTIONS := temp[1]
    
    ; TODO - build options using text adds in a loop

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

; adds default to pause options based on selected options from global config
;  currOptions - current options map to add default to
;  currKeys - current key array used to maintain user defined order
; 
; returns current options + default options
addDefaultOptions(currOptions := "", currKeys := "") {
    defaultOptions := Map()
    defaultOptions["WinSettings"] := ["Windows Settings", "runWinSettings"]
    defaultOptions["Settings"] := ["Script Settings", "createSettingsGui config\global.cfg"]
    
    if (!NumGet(globalStatus['kbmmode'], 0, 'UChar')) {
        defaultOptions["KBMMode"] := ["Enable KB & Mouse Mode", "enableKBMM"]
    }
    else {
        defaultOptions["KBMMode"] := ["Disable KB & Mouse Mode", "disableKBMM"]
    }

    if (!NumGet(globalStatus['suspendScript'], 0, 'UChar')) {
        defaultOptions["Suspend"] := ["Suspend All Scripts", "suspendScript"]
    }
    else {
        defaultOptions["Suspend"] := ["Resume All Scripts", "resumeScript"]
    }

    ; create currOptions map if param not passed
    if (currOptions = "") {
        currOptions := Map()
    }

    ; create currKeys array if param not passed
    if (currKeys = "") {
        currKeys := []
    }

    if (globalConfig["GUI"].Has("DefaultPauseOptions") && IsObject(globalConfig["GUI"]["DefaultPauseOptions"])) {
        globalOptions := globalConfig["GUI"]["DefaultPauseOptions"]

        for key in StrSplit(globalOptions["keys"], ",") {           
            if (defaultOptions.Has(globalOptions[key])) {
                currKeys.Push(defaultOptions[globalOptions[key]][1])
                currOptions[defaultOptions[globalOptions[key]][1]] := defaultOptions[globalOptions[key]][2]
            }
        }
    }

    return [currOptions, currKeys]
}

; adds program pause options
;  currOptions - current options map to add program options to
;  currKeys - current key array used to maintain user defined order
; 
; returns current options + program options
addProgramOptions(currOptions := "", currKeys := "") {
    ; create currOptions map if param not passed
    if (currOptions = "") {
        currOptions := Map()
    }

    ; create currKeys array if param not passed
    if (currKeys = "") {
        currKeys := []
    }

    currProgram := StrGet(globalStatus["currProgram"])

    if (currProgram = "") {
        return [currOptions, currKeys]
    }

    pauseOptions := globalRunning[currProgram].pauseOptions
    for key in StrSplit(pauseOptions["keys"], ",") {
        currKeys.Push(key)
        currOptions[key] := pauseOptions[key]
    }

    return [currOptions, currKeys]
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