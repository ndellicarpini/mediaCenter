class InputInterface extends Interface {
    id := "input"
    title := INTERFACES["input"]["wndw"]

    vibrating := []

    guiWidth := 0
    guiHeight := 0

    __New() {
        global globalConfig
        global globalInputStatus
        global globalInputConfigs

        super.__New(GUI_OPTIONS . " +AlwaysOnTop")

        this.unselectColor := COLOR1
        this.selectColor := COLOR3

        this.guiObj.BackColor := COLOR1
        this.guiObj.MarginX := interfaceHeight(0.01)
        this.guiObj.MarginY := interfaceHeight(0.01)

        this.guiWidth  := interfaceWidth(0.218)
        this.guiHeight := interfaceHeight(0.08)

        this.SetFont("bold s24")
        this.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 ym5 h" . interfaceHeight(0.05) 
            . " w" . (this.guiWidth - interfaceHeight(0.02)), "Input Devices")

        this.SetFont("norm s20")
        ypos := interfaceHeight(0.075)

        ; loop each type of input device
        for key, value in globalInputConfigs {
            if (!globalInputStatus.Has(key) || (value.Has("hideInMenu") && value["hideInMenu"])) {
                continue
            }

            ; add input device config name
            this.Add("Text", "0x200 xm0 y" . ypos . " w" . (this.guiWidth - interfaceHeight(0.02)) . " h" . interfaceHeight(0.03)
                , (value.Has("name")) ? value["name"] . "s" : "Unknown Devices")
            this.Add("Text", "0x200 Background" . FONT_COLOR . " xm0 y+" . interfaceHeight(0.002) . " w" . (this.guiWidth - interfaceHeight(0.02)) 
                . " h" . interfaceHeight(0.002), "")

            this.guiHeight += interfaceHeight(0.05)

            loop globalInputStatus[key].length {
                device := globalInputStatus[key][A_Index]
        
                this.guiHeight += interfaceHeight(0.05)
                ypos += interfaceHeight(0.05)
        
                ; add device number text
                this.Add("Text", "0x200 xm" . interfaceWidth(0.005) . " y" . ypos . " w" . interfaceWidth(0.06) . " h" . interfaceHeight(0.03)
                    , "Device " . A_Index)

                connected      := device["connected"]
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

                controlName := key . "-" . A_Index
        
                ; add disconnected text
                this.Add("Text", "v" . controlName . "Text Center 0x200 hp0 x" . interfaceWidth(0.075) . " y" . ypos 
                    . " w" . interfaceWidth(0.085) . ((connectionType = 1) ? " Hidden" : ""), connectionText)
                
                batteryLevel := device["batteryLevel"] * 100
                batteryColor := "00FF00"
                if (batteryLevel < 50) {
                    batteryColor := "FF0000"
                }
        
                borderWidth := interfaceHeight(0.005)

                ; add battery level display
                this.Add("Text", "v" . controlName . "Outline Background" . FONT_COLOR . " hp0 x" . interfaceWidth(0.079) 
                    . " y" . ypos . " w" . interfaceWidth(0.075) . ((connectionType != 1) ? " Hidden" : ""), "")
                this.Add("Progress", "v" . controlName . "Progress Background" . COLOR1 . " c" . batteryColor . " yp+" . (borderWidth / 2) 
                    . " xp+" . (borderWidth / 2) . " wp-" . borderWidth . " hp-" . borderWidth . ((connectionType != 1) ? " Hidden" : ""), batteryLevel)
                this.Add("Text", "v" . controlName . "Nub Background" . FONT_COLOR . " x+" . (borderWidth - interfaceWidth(0.002)) 
                    . " y" . (ypos + interfaceHeight((0.03 - 0.01) / 2)) . " w" . interfaceWidth(0.004) . " h" . interfaceHeight(0.01) . ((connectionType != 1) ? " Hidden" : ""), "")

                ; add vibe button
                this.Add("Text", "v" . controlName . "Vibe f(vibe " . controlName . ") u(unvibe) Center 0x200 Background" 
                    . COLOR2 . " xpos1 ypos" . A_Index . " x" . interfaceWidth(0.172) . " y" . ypos . " w" . interfaceWidth(0.04) . " h" . interfaceHeight(0.03) 
                    . ((!value.Has("vibration") || !value["vibration"] || !connected) ? " Hidden" : ""), "Vibe")
            }

            ypos += interfaceHeight(0.025)
        }
    }

    _Show() {
        super._Show("y0 x" . interfaceWidth(0.25) . " w" . this.guiWidth . " h" . this.guiHeight)
        SetTimer(InputSecondTimer, -1000)

        return 

        ; timer triggered each second to update the controller info
        ; in order to update the controller info need to redraw the whole gui
        InputSecondTimer() {
            global globalConfig
            global globalInputStatus

            if (!WinShown(this.title)) {
                return
            }

            try {
                for key, value in globalInputConfigs {
                    if (!globalInputStatus.Has(key) || (value.Has("hideInMenu") && value["hideInMenu"])) {
                        continue
                    }
    
                    loop globalInputStatus[key].length {
                        device := globalInputStatus[key][A_Index]
    
                        connected      := device["connected"]
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
    
                        controlName := key . "-" . A_Index
    
                        ; update values
                        this.guiObj[controlName . "Text"].Text := connectionText
    
                        batteryLevel := device["batteryLevel"] * 100
                        batteryColor := "00FF00"
                        if (batteryLevel < 50) {
                            batteryColor := "FF0000"
                        }
    
                        this.guiObj[controlName . "Progress"].Value := batteryLevel
                        this.guiObj[controlName . "Progress"].Opt("c" . batteryColor)
    
                        ; update visibility status
                        this.guiObj[controlName . "Text"].Visible := connectionType != 1 || !connected
                        this.guiObj[controlName . "Outline"].Visible := connectionType = 1 && connected
                        this.guiObj[controlName . "Progress"].Visible := connectionType = 1 && connected
                        this.guiObj[controlName . "Nub"].Visible := connectionType = 1 && connected
                        this.guiObj[controlName . "Vibe"].Visible := connected
                    }
                }
            }
            catch {
                return
            }
            
            SetTimer(InputSecondTimer, -1000)
            return
        }
    }

    _Destroy() {
        currVibing := ObjDeepClone(this.vibrating)
        loop currVibing.Length {
            this._unvibe()
        }

        super._Destroy()
    }

    _select() {
        funcArr := StrSplit(this.control2D[this.currentX][this.currentY].select, A_Space)
        if (funcArr[1] = "vibe") {
            this._vibe(funcArr[2])
        }
        else {
            super._select()
        }
    }

    _unselect() {
        funcArr := StrSplit(this.control2D[this.currentX][this.currentY].unselect, A_Space)
        if (funcArr[1] = "unvibe") {
            this._unvibe()
        }
        else {
            super._unselect()
        }
    }

    _vibe(controlName) {
        global globalInputStatus

        if (inArray(controlName, this.vibrating)) {
            return
        }

        deviceArr := StrSplit(controlName, "-",, 2)
        globalInputStatus[deviceArr[1]][Integer(deviceArr[2])]["vibrating"] := true
        this.vibrating.Push(controlName)
    }

    _unvibe() {
        global globalInputStatus

        loop this.vibrating.Length {
            controlName := this.vibrating[A_Index]

            deviceArr := StrSplit(controlName, "-",, 2)
            globalInputStatus[deviceArr[1]][Integer(deviceArr[2])]["vibrating"] := false
        }

        this.vibrating := []
    }
}