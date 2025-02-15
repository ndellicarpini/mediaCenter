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

        marginSize := interfaceHeight(0.01)
        this.guiObj.MarginX := marginSize
        this.guiObj.MarginY := marginSize

        this.guiWidth  := interfaceWidth(0.4)
        this.guiHeight := interfaceHeight(0.75)

        this.SetFont("bold s24")
        this.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 ym5 h" . interfaceHeight(0.05) . " w" . (this.guiWidth - (marginSize * 2)), "Multitasking")

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
            this.Add("Text", "0x200 xm5 y+" . interfaceHeight(0.01) . " h" . interfaceHeight(0.04) . " w" . (this.guiWidth - (marginSize * 2)), "Quick Access")
            this.Add("Text", "Section Background" . FONT_COLOR . " xm0 y+" . interfaceHeight(0.002) . " h" . interfaceHeight(0.002) . " w" . (this.guiWidth - (marginSize * 2)), "")

            this.SetFont("bold s24")
            for item in quickAccessList {
                this.Add("Text", "vQuick" . item . " f(createProgram " . item . ") Center 0x200 xpos1 ypos" . index . " xm0 y+" . interfaceHeight(0.006) . " h" . interfaceHeight(0.05) . " w" . (this.guiWidth - (marginSize * 2)), globalPrograms[item]["name"])
                index += 1
            }
        }

        ; render the list of running programs
        if (programList.Length > 0) {
            closeButtonSize := interfaceWidth(0.03)
            thumbnailMaxWidth  := interfaceWidth(0.18)
            thumbnailMaxHeight := interfaceHeight(0.18)

            this.SetFont("norm s24")
            this.Add("Text", "0x200 xm5 y+" . interfaceHeight(0.015) . " h" . interfaceHeight(0.04) . " w" . (this.guiWidth - interfaceHeight(0.02)), "Running Programs")
            this.Add("Text", "Section Background" . FONT_COLOR . " xm0 y+" . interfaceHeight(0.002) . " h" . interfaceHeight(0.002) . " w" . (this.guiWidth - (marginSize * 2)), "")

            numMonitors := MonitorGetCount()

            programIndex := 1
            for item in programList {
                this.SetFont("bold s24")

                ; program name
                if (programIndex = 1) {
                    this.Add("Text", "vRunning" . item . " f(setCurrentProgram " . item . ") Center xpos1 ypos" . index . " xm0 ys+" . interfaceHeight(0.006) . " h" . interfaceHeight(0.19) . " w" . (this.guiWidth - (marginSize * 2)), "")
                }
                else {
                    this.Add("Text", "vRunning" . item . " f(setCurrentProgram " . item . ") Center xpos1 ypos" . index . " xm0 ys+" . interfaceHeight(0.19) . " h" . interfaceHeight(0.19) . " w" . (this.guiWidth - (marginSize * 2)), "")
                }

                thumbnail := getThumbnailPath(item, globalConfig)
                thumbnailDims := getImageDimensions(thumbnail)

                thumbnailSize := "h-1 w" . thumbnailMaxWidth
                if ((thumbnailDims[1] / thumbnailDims[2]) < (thumbnailMaxWidth / thumbnailMaxHeight)) {
                    thumbnailSize := "w-1 h" . thumbnailMaxHeight
                }

                ; program picture / selection background
                this.Add("Picture", "Section xm+" . interfaceWidth(0.0035) . " yp+" . interfaceHeight(0.005) . " " . thumbnailSize, thumbnail)
                this.Add("Text", "Left BackgroundTrans h" . interfaceHeight(0.105) . " w" . interfaceWidth(0.195) . " yp+" . interfaceHeight(0.075) . " x+" . interfaceWidth(0.0075), globalRunning[item].name)

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
                    this.Add("Text", "vSwitchMonitor" . item . " f(switchMonitor " . item . ") Center 0x200 Background" . COLOR2 . " xpos" . currXPos . " ypos" . index . " xm+" . interfaceWidth(monitorOffset) . " ys0 h" . closeButtonSize . " w" . interfaceWidth(0.1), "Change Screen")
                    currXPos += 1
                }
                if (enableMin) {
                    ; render minimize/restore buttons if there are multiple running programs
                    if (!globalRunning[item].minimized) {
                        this.Add("Picture", "vMinMax" . item . " f(minimizeProgram " . item . ") Background" . COLOR2 . " xpos" . currXPos . " ypos" . index . " xm+" . interfaceWidth(minOffset) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\minimize.png", globalConfig))
                    }
                    else {
                        this.Add("Picture", "vMinMax" . item . " f(setCurrentProgram " . item . ") Background" . COLOR2 . " xpos" . currXPos . " ypos" . index . " xm+" . interfaceWidth(minOffset) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\restore.png", globalConfig))
                    }

                    currXPos += 1
                }
                if (enableExit) {
                    this.Add("Picture", "vClose" . item . " f(closeProgram " . item . ") BackgroundFF0000 xpos" . currXPos . " ypos" . index . " xm+" . interfaceWidth(exitOffset) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\close.png", globalConfig))
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

        guiX := ((MONITOR_W / 2) - (this.guiWidth / 2))
        guiY := ((MONITOR_H / 2) - (this.guiHeight / 2))
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
            setCurrentProgram(funcArr[2])

            numMonitors := MonitorGetCount()
            if (globalRunning[funcArr[2]].monitorNum >= numMonitors) {
                globalRunning[funcArr[2]].switchMonitor(1)
            } else {
                globalRunning[funcArr[2]].switchMonitor(globalRunning[funcArr[2]].monitorNum + 1)
            }
        }
        else {
            super._select()
        }
    }
}