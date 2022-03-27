global GUIPROGRAMTITLE := "AHKGUIPROGRAM"

createProgramMenu() {
    global globalConfig
    global globalRunning
    global globalGuis

    destroyPauseMenu()

    createInterface(GUIPROGRAMTITLE, GUIOPTIONS . " +AlwaysOnTop +Overlay000000",, Map("B", "gui.Destroy"), true, false,, "destroyProgramMenu")
    programInt := globalGuis[GUIPROGRAMTITLE]

    programInt.unselectColor := COLOR1
    programInt.selectColor   := COLOR3

    programInt.guiObj.BackColor := COLOR1

    marginSize := percentHeight(0.01)
    programInt.guiObj.MarginX := marginSize
    programInt.guiObj.MarginY := marginSize

    guiWidth  := percentWidth(0.3)
    guiHeight := percentHeight(0.4)

    guiSetFont(programInt, "bold s24")
    programInt.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 ym5 h" . percentHeight(0.05) . " w" . (guiWidth - (marginSize * 2)), "MultiTasking")

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

    quickAccessList := []
    for key, value in globalPrograms {
        if ((value.Has("background") && value["background"]) || inArray(key, programList)) {
            continue
        }

        if (value.Has("allowQuickAccess") && value["allowQuickAccess"]) {
            quickAccessList.Push(key)
        }
    }

    index := 1
    if (quickAccessList.Length > 0) {
        guiSetFont(programInt, "norm s22")
        programInt.Add("Text", "0x200 xm0 y+" . percentHeight(0.01) . " h" . percentHeight(0.04) . " w" . (guiWidth - (marginSize * 2)), "Quick Access")
        programInt.Add("Text", "Section Background" . FONTCOLOR . " xm0 y+" . percentHeight(0.008) . " h" . percentHeight(0.002) . " w" . (guiWidth - (marginSize * 2)), "")

        guiSetFont(programInt, "s20")
        for item in quickAccessList {
            programInt.Add("Text", "vQuick" . item . " f(launchQuickProgram " . item . ") 0x200 xpos1 ypos" . index . " xm0 y+" . percentHeight(0.01) . " h" . percentHeight(0.04) . " w" . (guiWidth - (marginSize * 2)), "  " . item)
            index += 1
        }
    }

    if (programList.Length > 0) {
        closeButtonSize := percentWidth(0.02)

        guiSetFont(programInt, "norm s22")
        programInt.Add("Text", "0x200 xm0 y+" . percentHeight(0.01) . " h" . percentHeight(0.04) . " w" . (guiWidth - percentHeight(0.02)), "Running Programs")
        programInt.Add("Text", "Section Background" . FONTCOLOR . " xm0 y+" . percentHeight(0.008) . " h" . percentHeight(0.002) . " w" . (guiWidth - (marginSize * 2)), "")

        guiSetFont(programInt, "s20")
        for item in programList {
            programInt.Add("Text", "vRunning" . item . " f(updateCurrProgram " . item . ") 0x200 xpos1 ypos" . index . " xm0 y+" . percentHeight(0.01) . " h" . percentHeight(0.04) . " w" . (guiWidth - (marginSize * 2)), "  " . item)
            programInt.Add("Picture", "vClose" . item . " f(closeProgram " . item . ") BackgroundFF0000 xpos2 ypos" . index . " xm+" . percentWidth(0.2) . " yp+" . percentHeight(0.01) . " h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\close.png", globalConfig))
            index += 1
        }
    }

    programInt.Show("Center w" . guiWidth . " h" . guiHeight)
}

destroyProgramMenu() {
    global globalRunning
    global globalGuis

    if (getGUI(GUIPROGRAMTITLE)) {
        globalGuis[GUIPROGRAMTITLE].guiObj.Destroy()

        currProgram := getStatusParam("currProgram")
    
        ; set pause & activate currProgram resume
        setStatusParam("pause", false)
        if (currProgram != "") {
            globalRunning[currProgram].resume()
        }
    }
}

updateCurrProgram(name) {
    setStatusParam("currProgram", name)
    destroyProgramMenu()
}

launchQuickProgram(name) {
    createProgram(name)
    destroyProgramMenu()
}

closeProgram(name) {
    global globalRunnning

    destroyProgramMenu()
    globalRunning[name].exit()
}