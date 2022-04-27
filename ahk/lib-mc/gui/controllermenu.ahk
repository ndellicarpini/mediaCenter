global GUICONTROLLERTITLE := "AHKGUICONTROLLER"

createControllerMenu() {
    global globalConfig
    global globalControllers
    global globalGuis

    createInterface(GUICONTROLLERTITLE, GUIOPTIONS . " +AlwaysOnTop",, Map("B", "gui.Destroy", "[HOLD]A", Map("down", "controllerMenuVibrate 1", "up", "controllerMenuVibrate 0")), true, false,, "destroyControllerMenu")
    controllerInt := globalGuis[GUICONTROLLERTITLE]

    controllerInt.unselectColor := COLOR1
    controllerInt.selectColor := COLOR3

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

        ; add port text
        controllerInt.Add("Text", "0x200 xm0 y" . ypos . " w" . percentWidth(0.05) . " h" . percentHeight(0.03), "Port " . A_Index)

        connected    := xGetConnected(port, globalControllers)
        batteryType  := xGetBatteryType(port, globalControllers)
        batteryLevel := xGetBatteryLevel(port, globalControllers) * 100

        ; add disconnected text
        controllerInt.Add("Text", "vPort" . port . "Text Center 0x200 hp0 x" . percentWidth(0.057) . " y" . ypos . " w" . percentWidth(0.085)
            . (((batteryType = 2 || batteryType = 3) && connected) ? " Hidden" : ""), (batteryType != 2 && batteryType != 3 && connected) ? "Wired" : "Disconnected")
        
        batteryColor := "00FF00"
        if (batteryLevel < 100) {
            batteryColor := "AAFF00"
        }
        else if (batteryLevel < 60) {
            batteryColor := "FF0000"
        }

        borderWidth := percentHeight(0.005)

        ; add battery level display
        controllerInt.Add("Text", "vPort" . port . "Outline Background" . FONTCOLOR . " hp0 x" . percentWidth(0.061) . " y" . ypos . " w" . percentWidth(0.075)
            . ((batteryType != 2 && batteryType != 3) ? " Hidden" : ""), "")
        controllerInt.Add("Progress", "vPort" . port . "Progress Background" . COLOR1 . " c" . batteryColor . " yp+" . (borderWidth / 2) . " xp+" . (borderWidth / 2) . " wp-" . borderWidth . " hp-" . borderWidth
            . ((batteryType != 2 && batteryType != 3) ? " Hidden" : ""), batteryLevel)
        controllerInt.Add("Text", "vPort" . port . "Nub Background" . FONTCOLOR . " x+" . (borderWidth - percentWidth(0.002)) . " y" . (ypos + percentHeight((0.03 - 0.01) / 2)) . " w" . percentWidth(0.004) . " h" . percentHeight(0.01)
            . ((batteryType != 2 && batteryType != 3) ? " Hidden" : ""), "")

        ; add vibe button
        controllerInt.Add("Text", "vPort" . port . "Vibe Center 0x200 Background" . COLOR2 . " xpos1 ypos" . A_Index . " x" . percentWidth(0.154) . " y" . ypos . " w" . percentWidth(0.04) . " h" . percentHeight(0.03)
            . ((!connected) ? " Hidden" : ""), "Vibe")
    }

    controllerInt.Show("y0 x" . percentWidth(0.25) . " w" . guiWidth . " h" . guiHeight)
    SetTimer(ControllerSecondTimer, 1000)
}

; causes the current controller to vibrate/stop
;  enable - boolean whether to enable or disable vibrations
;
; returns null
controllerMenuVibrate(enable) {
    global globalControllers
    global globalGuis

    if (!globalGuis.Has(GUICONTROLLERTITLE)) {
        return
    }

    currGui := globalGuis[GUICONTROLLERTITLE]

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

    if (getGUI(GUICONTROLLERTITLE)) {
        SetTimer(ControllerSecondTimer, 0)
        globalGuis[GUICONTROLLERTITLE].guiObj.Destroy()
    }
}

; timer triggered each second to update the controller info
; in order to update the controller info need to redraw the whole gui
ControllerSecondTimer() {
    global globalConfig
    global globalControllers
    global globalGuis

    currGui := getGui(GUICONTROLLERTITLE)
    if (!currGui) {
        return
    }

    loop globalConfig["General"]["MaxXInputControllers"] {
        port := A_Index - 1

        connected    := xGetConnected(port, globalControllers)
        batteryType  := xGetBatteryType(port, globalControllers)
        batteryLevel := xGetBatteryLevel(port, globalControllers) * 100

        ; update values
        currGui["Port" . port . "Text"].Text := (batteryType != 2 && batteryType != 3 && connected) ? "Wired" : "Disconnected"

        batteryColor := "00FF00"
        if (batteryLevel < 100) {
            batteryColor := "AAFF00"
        }
        else if (batteryLevel < 60) {
            batteryColor := "FF0000"
        }

        currGui["Port" . port . "Progress"].Value := batteryLevel
        currGui["Port" . port . "Progress"].Opt("c" . batteryColor)

        ; update visibility status
        currGui["Port" . port . "Text"].Visible := (batteryType != 2 && batteryType != 3) || !connected
        currGui["Port" . port . "Outline"].Visible := (batteryType = 2 || batteryType = 3) && connected
        currGui["Port" . port . "Progress"].Visible := (batteryType = 2 || batteryType = 3) && connected
        currGui["Port" . port . "Nub"].Visible := (batteryType = 2 || batteryType = 3) && connected
        currGui["Port" . port . "Vibe"].Visible := connected
    }
	
	return
}