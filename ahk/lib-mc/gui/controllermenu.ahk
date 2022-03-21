global GUICONTROLLERTITLE := "AHKGUICONTROLLER"
global GUIPREVCONTROLLERINSTANCE

createControllerMenu() {
    global globalConfig
    global globalGuis
    global globalControllers

    createInterface(GUICONTROLLERTITLE, GUIOPTIONS . " +AlwaysOnTop",, Map("B", "destroyControllerMenu", "[HOLD]A", Map("down", "controllerMenuVibrate 1", "up", "controllerMenuVibrate 0")), true)
    controllerInt := globalGuis[GUICONTROLLERTITLE]

    controllerInt.unselectColor := COLOR1
    controllerInt.selectColor := COLOR3

    createControllerGui(controllerInt)
    SetTimer(ControllerSecondTimer, 1000)
}

; creates the actual gui for the controller, need to rebuild on every update tick
;  controllerInt - interface object of the controller menu
;
; returns null
createControllerGui(controllerInt) {
    controllerInt.guiObj.BackColor := COLOR1
    controllerInt.guiObj.MarginX := percentHeight(0.01)
    controllerInt.guiObj.MarginY := percentHeight(0.01)

    guiWidth  := percentWidth(0.2)
    guiHeight := percentHeight(0.08)

    guiSetFont(controllerInt, "bold s24")
    controllerInt.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 ym5 h" . percentHeight(0.05) . " w" . (guiWidth - percentHeight(0.02)), "Controller Info")

    guiSetFont(controllerInt, "norm s20")
    loop globalConfig["General"]["MaxXInputControllers"] {
        port := A_Index - 1
		ypos := percentHeight(0.08 + (0.05 * port))

        guiHeight += percentHeight(0.05)

        controllerInt.Add("Text", "0x200 xm0 y" . ypos . " w" . percentWidth(0.05) . " h" . percentHeight(0.03), "Port " . A_Index)

        if (NumGet(globalControllers + (port * 20), 0, "UChar")) {
            batteryType := NumGet(globalControllers + (port * 20) + 1, 0, "UChar")
            if (batteryType = 1) {
                controllerInt.Add("Text", "Section Center 0x200 yp0 hp0 x+" . percentWidth(0.007) . " w" . percentWidth(0.085), "Wired")
            }
            else if (batteryType = 2 || batteryType = 3) {
                batteryLevel := NumGet(globalControllers + (port * 20) + 2, 0, "UChar")
                
                batteryColor := "00FF00"
                batteryProgress := 100

                if (batteryLevel = 0) {
                    batteryColor := "FF0000"
                    batteryProgress := 10
                }
                else if (batteryLevel = 1) {
                    batteryColor := "FFFF00"
                    batteryProgress := 40
                }
                else if (batteryLevel = 2) {
                    batteryProgress := 70
                }

                borderWidth := percentHeight(0.005)

                controllerInt.Add("Text", "Section Background" . FONTCOLOR . " hp0 x+" . percentWidth(0.007) . " y" . ypos . " w" . percentWidth(0.075), "")
                controllerInt.Add("Progress", "vPort" . A_Index . "Progress Background" . COLOR1 . " c" . batteryColor . " yp+" . (borderWidth / 2) . " xp+" . (borderWidth / 2) . " wp-" . borderWidth . " hp-" . borderWidth, batteryProgress)
                controllerInt.Add("Text", "Background" . FONTCOLOR . " x+" . (borderWidth - percentWidth(0.002)) . " y" . (ypos + percentHeight((0.03 - 0.01) / 2)) . " w" . percentWidth(0.004) . " h" . percentHeight(0.01), "")
            }

            controllerInt.Add("Text", "vPort" . A_Index . "Vibe Center 0x200 Background" . COLOR2 . " xpos1 ypos" . A_Index . " xs+" . percentWidth(0.092) . " y" . ypos . " w" . percentWidth(0.04) . " h" . percentHeight(0.03), "Vibe")
        }
        else {
            controllerInt.Add("Text", "Center 0x200 hp0 x+" . percentWidth(0.007) . " y" . ypos . " w" . percentWidth(0.085), "Disconnected")
        }
    }

    controllerInt.Show("y0 x" . percentWidth(0.25) . " w" . guiWidth . " h" . guiHeight)
}

; causes the current controller to vibrate/stop
;  enable - boolean whether to enable or disable vibrations
;
; returns null
controllerMenuVibrate(enable) {
    global globalControllers
    global globalGuis

    currGui := globalGuis[GUICONTROLLERTITLE]
    if (!currGui) {
        return
    }

    if (enable) {
        xEnableVibration(currGui.currentY - 1, globalControllers)
    }
    else {
        xDisableVibration(currGui.currentY - 1, globalControllers)
    }
}

; destroys the controller menu
;
; returns null
destroyControllerMenu() {
    global globalGuis

    SetTimer(ControllerSecondTimer, 0)
    
    globalGuis[GUICONTROLLERTITLE].guiObj.Destroy()
}

; timer triggered each second to update the controller info
; in order to update the controller info need to redraw the whole gui
ControllerSecondTimer() {
	global GUIPREVCONTROLLERINSTANCE
    global globalGuis

    try {
        currGui := globalGuis[GUICONTROLLERTITLE]    
        if (!currGui) {
            return
        }

        GUIPREVCONTROLLERINSTANCE := currGui.guiObj.Hwnd
        currGui.control2D := [[]]
		currGui.guiObj := Gui(GUIOPTIONS . " +AlwaysOnTop", GUICONTROLLERTITLE)

        createControllerGui(currGui)
        SetTimer(ClearPrevInstance, -500)
    }
	
	return
}

ClearPrevInstance() {
	global GUIPREVCONTROLLERINSTANCE
	
	prevGui := getGui(GUIPREVCONTROLLERINSTANCE)
	
	if (prevGui) {
		prevGui.Destroy()
	}
	
	return
}