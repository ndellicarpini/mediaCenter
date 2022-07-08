guiProgramMenu() {
    global globalConfig
    global globalRunning
    global globalGuis

    destroyPauseMenu()

    createInterface(GUIPROGRAMTITLE, GUIOPTIONS . " +AlwaysOnTop +Overlay000000",, Map("B", "gui.Destroy"), true, false,,, "destroyProgramMenu")
    programInt := globalGuis[GUIPROGRAMTITLE]

    programInt.unselectColor := COLOR1
    programInt.selectColor   := COLOR3

    programInt.guiObj.BackColor := COLOR1

    marginSize := percentHeight(0.01)
    programInt.guiObj.MarginX := marginSize
    programInt.guiObj.MarginY := marginSize

    guiWidth  := percentWidth(0.4)
    guiHeight := percentHeight(0.75)

    guiSetFont(programInt, "bold s24")
    programInt.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 ym5 h" . percentHeight(0.05) . " w" . (guiWidth - (marginSize * 2)), "Multitasking")

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
        guiSetFont(programInt, "norm s24")
        programInt.Add("Text", "0x200 xm5 y+" . percentHeight(0.01) . " h" . percentHeight(0.04) . " w" . (guiWidth - (marginSize * 2)), "Quick Access")
        programInt.Add("Text", "Section Background" . FONTCOLOR . " xm0 y+" . percentHeight(0.002) . " h" . percentHeight(0.002) . " w" . (guiWidth - (marginSize * 2)), "")

        guiSetFont(programInt, "bold s24")
        for item in quickAccessList {
            programInt.Add("Text", "vQuick" . item . " f(launchQuickProgram " . item . ") Center 0x200 xpos1 ypos" . index . " xm0 y+" . percentHeight(0.006) . " h" . percentHeight(0.05) . " w" . (guiWidth - (marginSize * 2)), globalPrograms[item]["name"])
            index += 1
        }
    }

    ; render the list of running programs
    if (programList.Length > 0) {
        closeButtonSize := percentWidth(0.03)
        thumbnailSize   := percentWidth(0.18)

        guiSetFont(programInt, "norm s24")
        programInt.Add("Text", "0x200 xm5 y+" . percentHeight(0.015) . " h" . percentHeight(0.04) . " w" . (guiWidth - percentHeight(0.02)), "Running Programs")
        programInt.Add("Text", "Section Background" . FONTCOLOR . " xm0 y+" . percentHeight(0.002) . " h" . percentHeight(0.002) . " w" . (guiWidth - (marginSize * 2)), "")

        programIndex := 1
        guiSetFont(programInt, "bold s24")
        for item in programList {
            if (programIndex = 1) {
                programInt.Add("Text", "vRunning" . item . " f(updateCurrProgram " . item . ") Center xpos1 ypos" . index . " xm0 ys+" . percentHeight(0.006) . " h" . percentHeight(0.19) . " w" . (guiWidth - (marginSize * 2)), "")
            }
            else {
                programInt.Add("Text", "vRunning" . item . " f(updateCurrProgram " . item . ") Center xpos1 ypos" . index . " xm0 ys+" . percentHeight(0.19) . " h" . percentHeight(0.19) . " w" . (guiWidth - (marginSize * 2)), "")
            }

            programInt.Add("Picture", "Section xm+" . percentWidth(0.0035) . " yp+" . percentHeight(0.005) . " w" . thumbnailSize . " h-1", getThumbnailPath(item, globalConfig))
            programInt.Add("Text", "Left BackgroundTrans h" . percentHeight(0.105) . " w" . percentWidth(0.195) . " yp+" . percentHeight(0.075) . " x+" . percentWidth(0.0075), globalRunning[item].name)

            if (globalRunning[item].allowExit) {
                ; render minimize/restore buttons if there are multiple running programs
                if (programList.Length > 1) {
                    if (!globalRunning[item].minimized) {
                        programInt.Add("Picture", "vMinMax" . item . " f(minimizeProgram " . item . ") Background" . COLOR2 . " xpos2 ypos" . index . " xm+" . percentWidth(0.323) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\minimize.png", globalConfig))
                    }
                    else {
                        programInt.Add("Picture", "vMinMax" . item . " f(restoreProgram " . item . ") Background" . COLOR2 . " xpos2 ypos" . index . " xm+" . percentWidth(0.323) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\restore.png", globalConfig))
                    }

                    programInt.Add("Picture", "vClose" . item . " f(closeProgram " . item . ") BackgroundFF0000 xpos3 ypos" . index . " xm+" . percentWidth(0.356) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\close.png", globalConfig))
                }
                else {
                    programInt.Add("Picture", "vClose" . item . " f(closeProgram " . item . ") BackgroundFF0000 xpos2 ypos" . index . " xm+" . percentWidth(0.356) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\close.png", globalConfig))
                }
            }
            else {
                if (!globalRunning[item].minimized) {
                    programInt.Add("Picture", "vMinMax" . item . " f(minimizeProgram " . item . ") Background" . COLOR2 . " xpos2 ypos" . index . " xm+" . percentWidth(0.356) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\minimize.png", globalConfig))
                }
                else {
                    programInt.Add("Picture", "vMinMax" . item . " f(restoreProgram " . item . ") Background" . COLOR2 . " xpos2 ypos" . index . " xm+" . percentWidth(0.356) . " ys0 h" . closeButtonSize . " w" . closeButtonSize, getAssetPath("icons\gui\restore.png", globalConfig))
                }
            }
            
            index += 1
            programIndex += 1
        }
    }

    programInt.Show("Center w" . guiWidth . " h" . guiHeight)
    
    ; hide the mouse in the gui
    MouseMove(percentWidth(1), percentHeight(1))
}

; destroys the program menu & resumes current program
;
; returns null
destroyProgramMenu() {
    global globalGuis

    if (getGUI(GUIPROGRAMTITLE)) {
        globalGuis[GUIPROGRAMTITLE].guiObj.Destroy()
        
        setStatusParam("pause", false)
    }
}

; sets the current program to selected
;  name - selected program
;
; returns null
updateCurrProgram(name) {
    global globalRunning

    destroyProgramMenu()

    globalRunning[name].time := A_TickCount
    setCurrentProgram(name)
}

; launchs quick program as currProgram
;  name - selected quick program
;
; returns null
launchQuickProgram(name) {
    destroyProgramMenu()
    createProgram(name)
}

; closes the selected program
;  name - selected program
;
; returns null
closeProgram(name) {
    global globalRunning

    destroyProgramMenu()
    globalRunning[name].exit()
}

; minimizes the selected program
;  name - selected program
;
; returns null
minimizeProgram(name) {
    global globalRunning

    destroyProgramMenu()

    globalRunning[name].time := 0
    setStatusParam("currProgram", "")
    globalRunning[name].minimize()
}

; restores the selected program
;  name - selected program
;
; returns null
restoreProgram(name) {
    setCurrentProgram(name)
    destroyProgramMenu()
}