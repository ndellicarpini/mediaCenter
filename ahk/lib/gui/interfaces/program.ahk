class ProgramInterface extends Interface {
    id := "program"
    title := INTERFACES["program"]["wndw"]

    guiWidth := 0
    guiHeight := 0

    _restoreMousePos := []

    __New() {
        global globalConfig
        global globalRunning

        super.__New(GUI_OPTIONS . " +AlwaysOnTop +Overlay000000")

        this.unselectColor := COLOR1
        this.selectColor   := COLOR3

        this.guiObj.BackColor := COLOR1

        marginSize := this._calcPercentHeight(0.01)
        this.guiObj.MarginX := marginSize
        this.guiObj.MarginY := marginSize

        this.guiWidth  := this._calcPercentWidth(0.4)
        this.guiHeight := this._calcPercentHeight(0.75)

        this.SetFont("bold s24")
        this.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 ym5 h" . this._calcPercentHeight(0.05) . " w" . (this.guiWidth - (marginSize * 2)), "Multitasking")

        ; create the list of running programs
        programList := []
        for key, value in globalRunning {
            if (value.background) {
                continue
            }

            if (programList.Length = 0) {
                programList.Push(key)
                continue
            }

            ; sort program list by descending launch time
            loop programList.Length {
                if (globalRunning[programList[A_Index]].time <= globalRunning[key].time) {
                    programList.InsertAt(A_Index, key)
                    break
                }
                else if (A_Index = programList.Length) {
                    programList.Push(key)
                    break
                }
            }
        }

        ; create the list of quick access programs
        quickAccessList := []
        for key, value in globalPrograms {
            if ((value.Has("background") && value["background"]) || inArray(key, programList)) {
                continue
            }

            if (value.Has("allowQuickAccess") && value["allowQuickAccess"]) {
                quickAccessList.Push(key)
            }
        }

        ; render the list of quick access programs
        index := 1
        if (quickAccessList.Length > 0) {
            this.SetFont("norm s24")
            this.Add("Text", "0x200 xm5 y+" . this._calcPercentHeight(0.01) . " h" . this._calcPercentHeight(0.04) . " w" . (this.guiWidth - (marginSize * 2)), "Quick Access")
            this.Add("Text", "Section Background" . FONT_COLOR . " xm0 y+" . this._calcPercentHeight(0.002) . " h" . this._calcPercentHeight(0.002) . " w" . (this.guiWidth - (marginSize * 2)), "")

            this.SetFont("bold s24")
            for item in quickAccessList {
                this.Add("Text", "vQuick" . item . " f(createProgram " . item . ") Center 0x200 xpos1 ypos" . index . " xm0 y+" . this._calcPercentHeight(0.006) 
                            . " h" . this._calcPercentHeight(0.05) . " w" . (this.guiWidth - (marginSize * 2)), globalPrograms[item]["name"])
                index += 1
            }
        }

        ; render the list of running programs
        if (programList.Length > 0) {
            closeButtonSize := this._calcPercentWidth(0.03)
            thumbnailMaxWidth  := this._calcPercentWidth(0.18)
            thumbnailMaxHeight := this._calcPercentHeight(0.18)

            this.SetFont("norm s24")
            this.Add("Text", "0x200 xm5 y+" . this._calcPercentHeight(0.015) . " h" . this._calcPercentHeight(0.04) . " w" . (this.guiWidth - this._calcPercentHeight(0.02)), "Running Programs")
            this.Add("Text", "Section Background" . FONT_COLOR . " xm0 y+" . this._calcPercentHeight(0.002) . " h" . this._calcPercentHeight(0.002) . " w" . (this.guiWidth - (marginSize * 2)), "")

            numMonitors := MonitorGetCount()

            programIndex := 1
            for item in programList {
                this.SetFont("bold s24")

                ; program name
                if (programIndex = 1) {
                    this.Add("Text", "vRunning" . item . " f(setCurrentProgram " . item . " false) Center xpos1 ypos" . index . " xm0 ys+" . this._calcPercentHeight(0.006) . " h" . this._calcPercentHeight(0.19) . " w" . (this.guiWidth - (marginSize * 2)), "")
                }
                else {
                    this.Add("Text", "vRunning" . item . " f(setCurrentProgram " . item . " false) Center xpos1 ypos" . index . " xm0 ys+" . this._calcPercentHeight(0.19) . " h" . this._calcPercentHeight(0.19) . " w" . (this.guiWidth - (marginSize * 2)), "")
                }

                thumbnail := getThumbnailPath(item, globalConfig)
                thumbnailDims := getImageDimensions(thumbnail)

                thumbnailSize := "h-1 w" . thumbnailMaxWidth
                if ((thumbnailDims[1] / thumbnailDims[2]) < (thumbnailMaxWidth / thumbnailMaxHeight)) {
                    thumbnailSize := "w-1 h" . thumbnailMaxHeight
                }

                ; program picture / selection background
                this.Add("Picture", "Section xm+" . this._calcPercentWidth(0.0035) . " yp+" . this._calcPercentHeight(0.005) . " " . thumbnailSize, thumbnail)
                this.Add("Text", "Left BackgroundTrans h" . this._calcPercentHeight(0.105) . " w" . this._calcPercentWidth(0.195) . " yp+" . this._calcPercentHeight(0.075) . " x+" . this._calcPercentWidth(0.0075), globalRunning[item].name)

                ; program buttons
                enableExit    := globalRunning[item].allowExit
                enableMin     := programList.Length > 1
                enableMonitor := numMonitors > 1

                monitorOffset := 0.220 + (!enableMin ? 0.033 : 0) + (!enableExit ? 0.033 : 0)
                minOffset := 0.323 + (!enableExit ? 0.033 : 0)
                exitOffset := 0.356

                currXPos := 2
                if (enableMonitor) {
                    this.SetFont("norm s18")
                    this.Add("Text", "vSwitchMonitor" . item . " f(switchMonitor " . item . ") Center 0x200 Background" . COLOR2 . " xpos" . currXPos . " ypos" . index 
                                . " xm+" . this._calcPercentWidth(monitorOffset) . " ys0 h" . closeButtonSize . " w" . this._calcPercentWidth(0.1), "Change Screen")
                    currXPos += 1
                }
                if (enableMin) {
                    ; render minimize/restore buttons if there are multiple running programs
                    if (!globalRunning[item].minimized) {
                        this.Add("Picture", "vMinMax" . item . " f(minimizeProgram " . item . ") Background" . COLOR2 . " xpos" . currXPos . " ypos" . index 
                                    . " xm+" . this._calcPercentWidth(minOffset) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\minimize.png", globalConfig))
                    }
                    else {
                        this.Add("Picture", "vMinMax" . item . " f(setCurrentProgram " . item . ") Background" . COLOR2 . " xpos" . currXPos . " ypos" . index 
                                    . " xm+" . this._calcPercentWidth(minOffset) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\restore.png", globalConfig))
                    }

                    currXPos += 1
                }
                if (enableExit) {
                    this.Add("Picture", "vClose" . item . " f(closeProgram " . item . ") BackgroundFF0000 xpos" . currXPos . " ypos" . index 
                                . " xm+" . this._calcPercentWidth(exitOffset) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\close.png", globalConfig))
                }
                
                index += 1
                programIndex += 1
            }
        }        
    }

    _Show() {
        global globalStatus

        if (globalStatus["kbmmode"] || globalStatus["desktopmode"]) {
            MouseGetPos(&x, &y)
            this._restoreMousePos := [x, y]
        }

        guiX := ((this._calcPercentWidth(1) / 2) - (this.guiWidth / 2))
        guiY := ((this._calcPercentHeight(1) / 2) - (this.guiHeight / 2))
        super._Show("x" . guiX . " y" . guiY . "  w" . this.guiWidth . " h" . this.guiHeight)

        ; hide the mouse in the gui
        HideMouseCursor()
    }

    _Destroy() {
        global globalStatus

        super._Destroy()

        if ((globalStatus["kbmmode"] || globalStatus["desktopmode"]) && this._restoreMousePos.Length = 2) {
            MouseMove(this._restoreMousePos[1], this._restoreMousePos[2])
            this._restoreMousePos := []
        }
    }

    _select() {
        global globalStatus
        global globalRunning

        this.Destroy()

        funcArr := StrSplit(this.control2D[this.currentX][this.currentY].select, A_Space)
        if (funcArr[1] = "closeProgram") {
            globalRunning[funcArr[2]].exit()
        }
        else if (funcArr[1] = "minimizeProgram") {
            resetCurrentProgram()

            globalRunning[funcArr[2]].time := 0
            globalRunning[funcArr[2]].minimize()
        }
        else if (funcArr[1] = "switchMonitor") {
            numMonitors := MonitorGetCount()
            currMonitorNum := globalRunning[funcArr[2]].checkMonitor()

            newMonitor := (currMonitorNum >= numMonitors) ? 1 : currMonitorNum + 1
            if (globalStatus["currProgram"]["id"] != funcArr[2] && globalStatus["currProgram"]["monitor"] = newMonitor) {
                setCurrentProgram(funcArr[2])
            }
            else {
                ; set currProgram monitor ahead of time for loadscreen
                if (globalStatus["currProgram"]["id"] = funcArr[2]) {
                    globalStatus["currProgram"]["monitor"] = newMonitor
                }

                ; flash loadscreen so it looks like something was done
                ; and to hide loadscreen right behind current program
                setLoadScreen()
                globalRunning[funcArr[2]].switchMonitor(newMonitor)
                resetLoadScreen()
            }
        }
        else {
            super._select()
        }
    }
}