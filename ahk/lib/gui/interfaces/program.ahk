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

        marginSize := percentHeight(0.01)
        this.guiObj.MarginX := marginSize
        this.guiObj.MarginY := marginSize

        this.guiWidth  := percentWidth(0.4)
        this.guiHeight := percentHeight(0.75)

        this.SetFont("bold s24")
        this.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 ym5 h" . percentHeight(0.05) . " w" . (this.guiWidth - (marginSize * 2)), "Multitasking")

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
            this.Add("Text", "0x200 xm5 y+" . percentHeight(0.01) . " h" . percentHeight(0.04) . " w" . (this.guiWidth - (marginSize * 2)), "Quick Access")
            this.Add("Text", "Section Background" . FONT_COLOR . " xm0 y+" . percentHeight(0.002) . " h" . percentHeight(0.002) . " w" . (this.guiWidth - (marginSize * 2)), "")

            this.SetFont("bold s24")
            for item in quickAccessList {
                this.Add("Text", "vQuick" . item . " f(createProgram " . item . ") Center 0x200 xpos1 ypos" . index . " xm0 y+" . percentHeight(0.006) . " h" . percentHeight(0.05) . " w" . (this.guiWidth - (marginSize * 2)), globalPrograms[item]["name"])
                index += 1
            }
        }

        ; render the list of running programs
        if (programList.Length > 0) {
            closeButtonSize := percentWidth(0.03)
            thumbnailSize   := percentWidth(0.18)

            this.SetFont("norm s24")
            this.Add("Text", "0x200 xm5 y+" . percentHeight(0.015) . " h" . percentHeight(0.04) . " w" . (this.guiWidth - percentHeight(0.02)), "Running Programs")
            this.Add("Text", "Section Background" . FONT_COLOR . " xm0 y+" . percentHeight(0.002) . " h" . percentHeight(0.002) . " w" . (this.guiWidth - (marginSize * 2)), "")

            programIndex := 1
            this.SetFont("bold s24")
            for item in programList {
                if (programIndex = 1) {
                    this.Add("Text", "vRunning" . item . " f(setCurrentProgram " . item . ") Center xpos1 ypos" . index . " xm0 ys+" . percentHeight(0.006) . " h" . percentHeight(0.19) . " w" . (this.guiWidth - (marginSize * 2)), "")
                }
                else {
                    this.Add("Text", "vRunning" . item . " f(setCurrentProgram " . item . ") Center xpos1 ypos" . index . " xm0 ys+" . percentHeight(0.19) . " h" . percentHeight(0.19) . " w" . (this.guiWidth - (marginSize * 2)), "")
                }

                this.Add("Picture", "Section xm+" . percentWidth(0.0035) . " yp+" . percentHeight(0.005) . " w" . thumbnailSize . " h-1", getThumbnailPath(item, globalConfig))
                this.Add("Text", "Left BackgroundTrans h" . percentHeight(0.105) . " w" . percentWidth(0.195) . " yp+" . percentHeight(0.075) . " x+" . percentWidth(0.0075), globalRunning[item].name)

                if (globalRunning[item].allowExit) {
                    ; render minimize/restore buttons if there are multiple running programs
                    if (programList.Length > 1) {
                        if (!globalRunning[item].minimized) {
                            this.Add("Picture", "vMinMax" . item . " f(minimizeProgram " . item . ") Background" . COLOR2 . " xpos2 ypos" . index . " xm+" . percentWidth(0.323) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\minimize.png", globalConfig))
                        }
                        else {
                            this.Add("Picture", "vMinMax" . item . " f(setCurrentProgram " . item . ") Background" . COLOR2 . " xpos2 ypos" . index . " xm+" . percentWidth(0.323) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\restore.png", globalConfig))
                        }

                        this.Add("Picture", "vClose" . item . " f(closeProgram " . item . ") BackgroundFF0000 xpos3 ypos" . index . " xm+" . percentWidth(0.356) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\close.png", globalConfig))
                    }
                    else {
                        this.Add("Picture", "vClose" . item . " f(closeProgram " . item . ") BackgroundFF0000 xpos2 ypos" . index . " xm+" . percentWidth(0.356) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\close.png", globalConfig))
                    }
                }
                else {
                    if (!globalRunning[item].minimized) {
                        this.Add("Picture", "vMinMax" . item . " f(minimizeProgram " . item . ") Background" . COLOR2 . " xpos2 ypos" . index . " xm+" . percentWidth(0.356) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\minimize.png", globalConfig))
                    }
                    else {
                        this.Add("Picture", "vMinMax" . item . " f(setCurrentProgram " . item . ") Background" . COLOR2 . " xpos2 ypos" . index . " xm+" . percentWidth(0.356) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\restore.png", globalConfig))
                    }
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

        guiX := MONITOR_X + ((MONITOR_W / 2) - (this.guiWidth / 2))
        guiY := MONITOR_Y + ((MONITOR_H / 2) - (this.guiHeight / 2))
        super._Show("x" . guiX . " y" . guiY . "  w" . this.guiWidth . " h" . this.guiHeight)

        ; hide the mouse in the gui
        MouseMove(percentWidth(1), percentHeight(1))
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
        else {
            super._select()
        }
    }
}