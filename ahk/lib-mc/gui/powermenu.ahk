global GUIPOWERTITLE := "AHKGUIPOWER"

guiPowerMenu() {
    global globalConfig
    global globalGuis

    destroyPauseMenu()
    
    createInterface(GUIPOWERTITLE, GUIOPTIONS . " +AlwaysOnTop +Overlay000000",, Map("B", "gui.Destroy"), true, false,, "destroyPowerMenu")    
    powerInt := globalGuis[GUIPOWERTITLE]

    powerInt.unselectColor := COLOR2
    powerInt.selectColor   := COLOR3

    powerInt.guiObj.BackColor := COLOR1

    marginSize := percentWidth(0.01)
    powerInt.guiObj.MarginX := marginSize
    powerInt.guiObj.MarginY := marginSize
    
    buttonSize := percentWidth(0.07)
    buttonSpacing := percentWidth(0.018)
    powerOptions := createPowerOptions()

    guiSetFont(powerInt, "bold s22")

    index := 0
    for item in powerOptions.order {
        index += 1

        if (index = 1) {
            powerInt.Add("Picture", "v" . item . " f(" . powerOptions.items[item].function . ") Section ypos1 xpos" . index . " xm0 ym0 w" . buttonSize . " h" . buttonSize, getAssetPath("icons\gui\" . powerOptions.items[item].icon . ".png", globalConfig))
            powerInt.Add("Text", "Center wp0 xp0 y+" . (buttonSpacing / 3), powerOptions.items[item].title)
        }
        else {
            powerInt.Add("Picture", "v" . item . " f(" . powerOptions.items[item].function . ") Section ypos1 xpos" . index . " xs+" . (buttonSize + buttonSpacing) . " ym0 w" . buttonSize . " h" . buttonSize, getAssetPath("icons\gui\" . powerOptions.items[item].icon . ".png", globalConfig))
            powerInt.Add("Text", "Center wp0 xp0 y+" . (buttonSpacing / 3), powerOptions.items[item].title)
        }
    }

    powerInt.Show("Center w" . (buttonSize * index) + (buttonSpacing * (index - 1)) + (marginSize * 2) . " h" . percentHeight(0.2))
    
    ; hide the mouse in the gui
    MouseMove(percentWidth(1), percentHeight(1))
}

; destroys the power menu & resumes current program
;
; returns null
destroyPowerMenu() {
    global globalRunning
    global globalGuis

    if (getGUI(GUIPOWERTITLE)) {
        globalGuis[GUIPOWERTITLE].guiObj.Destroy()
        
        setStatusParam("pause", false)
    }
}

; adds power options based on selected options from global config
; 
; returns powers order & options
createPowerOptions() {
    global globalConfig

    defaultOptions := Map()
    defaultOptions["Standby"]  := {title: "Standby",  function: "powerStandby",  icon: "standby"}
    defaultOptions["Shutdown"] := {title: "Shutdown", function: "powerShutdown", icon: "power"}
    defaultOptions["Restart"]  := {title: "Restart",  function: "powerRestart",  icon: "restart"}
    defaultOptions["Reset"] := {title: "Reload", function: "powerReset", icon: "reload"}
    defaultOptions["Exit"] := {title: "Exit", function: "powerExit", icon: "close"}

    optionsOrder := []
    if (globalConfig["GUI"].Has("PowerOptions") && IsObject(globalConfig["GUI"]["PowerOptions"])) {
        optionsOrder := globalConfig["GUI"]["PowerOptions"]

        for item in optionsOrder {
            if (!defaultOptions.Has(item)) {
                defaultOptions.Delete(item)
            }
        }
    }

    return {order: optionsOrder, items: defaultOptions}
}

; forces backup & exits the script
;
; returns null
powerExit() {
    destroyPowerMenu()
    
    setStatusParam("internalMessage", "ExitScript")
}

; forces backup & resets the script
;
; returns null
powerReset() {
    destroyPowerMenu()
    
    setStatusParam("internalMessage", "ResetScript")
}

; closes all open programs & explorer -> sleep, then on wake restart main
;
; returns null
powerStandby() {
    destroyPowerMenu()

    setStatusParam("internalMessage", "Standby")
}

; closes all open programs then shuts down the system
;
; returns null
powerShutdown() {
    destroyPowerMenu()

    setStatusParam("internalMessage", "PowerOff")
}

; closes all open programs then restarts the system
;
; returns null
powerRestart() {
    destroyPowerMenu()

    setStatusParam("internalMessage", "Restart")
}