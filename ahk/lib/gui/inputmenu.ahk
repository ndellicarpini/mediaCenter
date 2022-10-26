guiInputMenu() {
    global globalConfig
    global globalGuis
    global globalInputStatus
    global globalInputConfigs

    createInterface(GUICONTROLLERTITLE, GUIOPTIONS . " +AlwaysOnTop",, false,,, "destroyInputMenu")
    controllerInt := globalGuis[GUICONTROLLERTITLE]

    controllerInt.unselectColor := COLOR1
    controllerInt.selectColor := COLOR3

    controllerInt.guiObj.BackColor := COLOR1
    controllerInt.guiObj.MarginX := percentHeight(0.01)
    controllerInt.guiObj.MarginY := percentHeight(0.01)

    guiWidth  := percentWidth(0.218)
    guiHeight := percentHeight(0.08)

    guiSetFont(controllerInt, "bold s24")
    controllerInt.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 ym5 h" . percentHeight(0.05) . " w" . (guiWidth - percentHeight(0.02)), "Input Devices")

    guiSetFont(controllerInt, "norm s20")
    ypos := percentHeight(0.075)

    for key, value in globalInputConfigs {
        if (!globalInputStatus.Has(key) || (value.Has("hideInMenu") && value["hideInMenu"])) {
            continue
        }

        controllerInt.Add("Text", "0x200 xm0 y" . ypos . " w" . (guiWidth - percentHeight(0.02)) . " h" . percentHeight(0.03), (value.Has("name")) ? value["name"] . "s" : "Unknown Devices")
        controllerInt.Add("Text", "0x200 Background" . FONTCOLOR . " xm0 y+" . percentHeight(0.002) . " w" . (guiWidth - percentHeight(0.02)) . " h" . percentHeight(0.002), "")

        guiHeight += percentHeight(0.05)

        loop globalInputStatus[key].length {
            device := globalInputStatus[key][A_Index]
    
            guiHeight += percentHeight(0.05)
            ypos      += percentHeight(0.05)
    
            ; add name text
            controllerInt.Add("Text", "0x200 xm" . percentWidth(0.005) . " y" . ypos . " w" . percentWidth(0.06) . " h" . percentHeight(0.03), "Device " . A_Index)

            connected := device["connected"]

            connectionType := device["connectionType"]
            connectionText := ""
            if (connected) {
                if (connectionType = 0) {
                    connectionText := "Wired"
                }
                else if (connectionType = -1) {
                    connectionText := "Unknown"
                }
            }
            else {
                connectionText := "Disconnected"
            }
    
            ; add disconnected text
            controllerInt.Add("Text", "v" . A_Index . "-" . key . "Text Center 0x200 hp0 x" . percentWidth(0.075) . " y" . ypos . " w" . percentWidth(0.085)
                . ((connectionType = 1) ? " Hidden" : ""), connectionText)
            
            batteryLevel := device["batteryLevel"] * 100
            batteryColor := "00FF00"
            if (batteryLevel < 50) {
                batteryColor := "FF0000"
            }
    
            borderWidth := percentHeight(0.005)

            ; add battery level display
            controllerInt.Add("Text", "v" . A_Index . "-" . key . "Outline Background" . FONTCOLOR . " hp0 x" . percentWidth(0.079) . " y" . ypos . " w" . percentWidth(0.075)
                . ((connectionType != 1) ? " Hidden" : ""), "")
            controllerInt.Add("Progress", "v" . A_Index . "-" . key . "Progress Background" . COLOR1 . " c" . batteryColor . " yp+" . (borderWidth / 2) . " xp+" . (borderWidth / 2) . " wp-" . borderWidth . " hp-" . borderWidth
                . ((connectionType != 1) ? " Hidden" : ""), batteryLevel)
            controllerInt.Add("Text", "v" . A_Index . "-" . key . "Nub Background" . FONTCOLOR . " x+" . (borderWidth - percentWidth(0.002)) . " y" . (ypos + percentHeight((0.03 - 0.01) / 2)) . " w" . percentWidth(0.004) . " h" . percentHeight(0.01)
                . ((connectionType != 1) ? " Hidden" : ""), "")
    
            ; add vibe button
            controllerInt.Add("Text", "v" . A_Index . "-" . key . "Vibe Center 0x200 Background" . COLOR2 . " xpos1 ypos" . A_Index . " x" . percentWidth(0.172) . " y" . ypos . " w" . percentWidth(0.04) . " h" . percentHeight(0.03)
            . ((!value.Has("vibration") || !value["vibration"] || !connected) ? " Hidden" : ""), "Vibe")
        }

        ypos += percentHeight(0.025)
    }

    controllerInt.Show("y0 x" . percentWidth(0.25) . " w" . guiWidth . " h" . guiHeight)
    SetTimer(ControllerSecondTimer, 1000)
}

; causes the current controller to vibrate/stop
;  enable - boolean whether to enable or disable vibrations
;
; returns null
inputMenuVibrate(enable) {
    global globalInputStatus
    global globalGuis

    if (!globalGuis.Has(GUICONTROLLERTITLE)) {
        return
    }

    currGui := globalGuis[GUICONTROLLERTITLE]
    loop currGui.control2D.Length {
        xIndex := A_Index

        loop currGui.control2D[xIndex].Length {
            yIndex := A_Index

            currControl := currGui.control2D[xIndex][yIndex].control
            if (SubStr(currControl, -4, 4) != "Vibe") {
                continue
            }

            deviceInfoArr := StrSplit(SubStr(currControl, 1, (StrLen(currControl) - 4)), "-",, 2)


            if (xIndex = currGui.currentX && yIndex = currGui.currentY) {
                globalInputStatus[deviceInfoArr[2]][deviceInfoArr[1]]["vibrating"] := (enable) ? true : false
            }
            else {
                globalInputStatus[deviceInfoArr[2]][deviceInfoArr[1]]["vibrating"] := false
            }
        }
    } 
}

; destroys the controller menu
;
; returns null
destroyInputMenu() {
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
    global globalInputStatus
    global globalGuis

    currGui := getGui(GUICONTROLLERTITLE)
    if (!currGui) {
        return
    }

    for key, value in globalInputConfigs {
        if (!globalInputStatus.Has(key) || (value.Has("hideInMenu") && value["hideInMenu"])) {
            continue
        }

        loop globalInputStatus[key].length {
            device := globalInputStatus[key][A_Index]
            connected := device["connected"]

            connectionType := device["connectionType"]
            connectionText := ""
            if (connected) {
                if (connectionType = 0) {
                    connectionText := "Wired"
                }
                else if (connectionType = -1) {
                    connectionText := "Unknown"
                }
            }
            else {
                connectionText := "Disconnected"
            }

            ; update values
            currGui[A_Index . "-" . key . "Text"].Text := connectionText

            batteryLevel := device["batteryLevel"] * 100
            batteryColor := "00FF00"
            if (batteryLevel < 50) {
                batteryColor := "FF0000"
            }

            currGui[A_Index . "-" . key . "Progress"].Value := batteryLevel
            currGui[A_Index . "-" . key . "Progress"].Opt("c" . batteryColor)

            ; update visibility status
            currGui[A_Index . "-" . key . "Text"].Visible := connectionType != 1 || !connected
            currGui[A_Index . "-" . key . "Outline"].Visible := connectionType = 1 && connected
            currGui[A_Index . "-" . key . "Progress"].Visible := connectionType = 1 && connected
            currGui[A_Index . "-" . key . "Nub"].Visible := connectionType = 1 && connected
            currGui[A_Index . "-" . key . "Vibe"].Visible := connected
        }
    }
	
	return
}