global GUIVOLUMETITLE := "AHKGUIVOLUME"
global MASTERVOLUME := SoundGetVolume()
global MASTERMUTE := false

global CHANGEVOLUME := false

createVolumeMenu() {
    global globalConfig
    global globalRunning
    global globalGuis

    createInterface(GUIVOLUMETITLE, GUIOPTIONS . " +AlwaysOnTop",, Map("B", "gui.Destroy"), true, false)
    volumeInt := globalGuis[GUIVOLUMETITLE]

    volumeInt.unselectColor := COLOR2
    volumeInt.selectColor := COLOR3

    volumeInt.guiObj.BackColor := COLOR1
    volumeInt.guiObj.MarginX := percentHeight(0.01)
    volumeInt.guiObj.MarginY := percentHeight(0.01)

    guiWidth  := percentWidth(0.2)
    guiHeight := percentHeight(0.165)
    maxHeight := percentHeight(0.5)

    guiSetFont(volumeInt, "bold s24")
    volumeInt.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 ym5 h" . percentHeight(0.05) . " w" . (guiWidth - percentHeight(0.02)), "Volume Control")

    volControlWidth     := percentWidth(0.16)
    volControlHeight    := percentHeight(0.035)
    volControlSelectBox := percentHeight(0.01)

    ; --- ADD MASTER VOLUME CONTROL ---
    guiSetFont(volumeInt, "norm s20")
    volumeInt.Add("Text", "Section xm0 y+" . percentHeight(0.018), "Master")
    volumeInt.Add("Text", "vMasterControl Center f(updateChangeVolume) xpos1 ypos1 Background" . COLOR2 " h" . volControlHeight . " w" . volControlWidth . " y+" . percentHeight(0.0065), "")
    volumeInt.Add("Progress", "vMasterProgress Background" . COLOR2 . " c" . FONTCOLOR 
        . " h" . (volControlHeight - volControlSelectBox) . " w" . (volControlWidth - volControlSelectBox) . " yp" . (volControlSelectBox / 2) . " xm" . (volControlSelectBox / 2), SoundGetVolume())
    
    volumeInt.Add("Picture", "vMasterMute f(muteVolume) xpos2 ypos1 yp-" . (volControlSelectBox / 2) . " x+" . percentWidth(0.012) . " h" . volControlHeight . " w" . volControlHeight
        , (!MASTERMUTE) ? getAssetPath("icons\gui\volume.png", globalConfig) : getAssetPath("icons\gui\volume-off.png", globalConfig))

    ; clean the program list
    programList := []
    for key, value in globalRunning {
        if (value.background) {
            continue
        }

        ; ignore programs with no audio interface initialized
        if (!value.muted || value.volume = -1) {
            value.updateVolume()
        }

        if (value.volume = -1) {
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

    ; --- ADD PROGRAM VOLUME CONTROLS ---
    loop programList.Length {     
        ; adjust gui height up to max for additional programs
        if (guiHeight < maxHeight) {
            newHeight := guiHeight + percentHeight(0.085)
            guiHeight := (newHeight > maxHeight) ? maxHeight : newHeight
        }

        currProgram := globalRunning[programList[A_Index]]

        volumeInt.Add("Text", "Section xm0 y+" . percentHeight(0.018), globalRunning[programList[A_Index]].name)
        volumeInt.Add("Text", "v" . programList[A_Index] . "Control Center f(updateChangeVolume " . programList[A_Index] . ") xpos1 ypos" . (A_Index + 1) . " Background" . COLOR2 " h" . volControlHeight . " w" . volControlWidth . " y+" . percentHeight(0.0065), "")
        volumeInt.Add("Progress", "v" . programList[A_Index] . "Progress Background" . COLOR2 . " c" . FONTCOLOR 
            . " h" . (volControlHeight - volControlSelectBox) . " w" . (volControlWidth - volControlSelectBox) . " yp" . (volControlSelectBox / 2) . " xm" . (volControlSelectBox / 2), (currProgram.muted) ? 0 : currProgram.volume)
        
        volumeInt.Add("Picture", "v" . programList[A_Index] . "Mute f(muteVolume " . programList[A_Index] . ") xpos2 ypos" . (A_Index + 1) . " yp-" . (volControlSelectBox / 2) . " x+" . percentWidth(0.012) . " h" . volControlHeight . " w" . volControlHeight
            , (!currProgram.muted) ? getAssetPath("icons\gui\volume.png", globalConfig) : getAssetPath("icons\gui\volume-off.png", globalConfig))
    }

    ; --- SHOW GUI ---
    volumeInt.Show("y0 x" . percentWidth(0.25) . " w" . guiWidth . " h" . guiHeight)
}

; mutes the system/selected program
;  currProgramName - name of program to mute, or master (system)
;
; returns null
muteVolume(currProgramName := "master") {
    global MASTERMUTE
    global globalRunning
    global globalGuis

    currGui := globalGuis[GUIVOLUMETITLE]
    if (!currGui) {
        return
    }

    ; mute system volume
    if (currProgramName = "master") {
        if (MASTERMUTE) {
            SoundSetVolume(MASTERVOLUME)
            currGui.guiObj["MasterProgress"].Value := MASTERVOLUME
            currGui.guiObj["MasterMute"].Value := getAssetPath("icons\gui\volume.png", globalConfig)
        }
        else {
            SoundSetVolume(0)
            currGui.guiObj["MasterProgress"].Value := 0
            currGui.guiObj["MasterMute"].Value := getAssetPath("icons\gui\volume-off.png", globalConfig)
        }

        MASTERMUTE := !MASTERMUTE
        return
    }

    currProgram := globalRunning[currProgramName]
    if (currProgram.muted) {
        currGui.guiObj[currProgramName . "Progress"].Value := currProgram.volume
        currGui.guiObj[currProgramName . "Mute"].Value := getAssetPath("icons\gui\volume.png", globalConfig)
    }
    else {
        currGui.guiObj[currProgramName . "Progress"].Value := 0
        currGui.guiObj[currProgramName . "Mute"].Value := getAssetPath("icons\gui\volume-off.png", globalConfig)
    }

    currProgram.muteVolume()
}

; changes the volume of the system/selected program by a specified value
;  diff - amount to adjust volume by (+ or -)
;  currProgramName - name of program to adjust, or master (system)
;
; returns null
updateVolume(diff, currProgramName := "master") {
    global MASTERVOLUME
    global MASTERMUTE
    global globalConfig
    global globalGuis

    currGui := globalGuis[GUIVOLUMETITLE]
    if (!currGui) {
        return
    }

    if (Type(diff) = "String") {
        diff := Integer(diff)
    }

    ; adjust system volume
    if (currProgramName = "master") {
        currVolume := (MASTERMUTE) ? MASTERVOLUME : SoundGetVolume()

        if (currVolume > 0 && diff < 0) {
            newVolume := (currVolume + diff <= 0) ? 0 : currVolume + diff
            
            SoundSetVolume(newVolume)
            MASTERVOLUME := newVolume
            currGui.guiObj["MasterProgress"].Value := newVolume
        }
        else if (currVolume < 100 && diff > 0) {
            newVolume := (currVolume + diff >= 100) ? 100 : currVolume + diff
            
            SoundSetVolume(newVolume)
            MASTERVOLUME := newVolume
            currGui.guiObj["MasterProgress"].Value := newVolume
        }

        if (MASTERMUTE) {
            MASTERMUTE := false
            currGui.guiObj["MasterMute"].Value := getAssetPath("icons\gui\volume.png", globalConfig)
        }
        
        return
    }
    
    currProgram := globalRunning[currProgramName]
    currVolume := currProgram.volume
    
    if (currProgram.muted) {
        currProgram.muteVolume()
        currGui.guiObj[currProgramName . "Progress"].Value := currVolume
        currGui.guiObj[currProgramName . "Mute"].Value := getAssetPath("icons\gui\volume.png", globalConfig)
    }

    if (currVolume > 0 && diff < 0) {
        newVolume := (currVolume + diff <= 0) ? 0 : currVolume + diff
        
        currProgram.setVolume(newVolume)
        currGui.guiObj[currProgramName . "Progress"].Value := newVolume
    }
    else if (currVolume < 100 && diff > 0) {
        newVolume := (currVolume + diff >= 100) ? 100 : currVolume + diff
        
        currProgram.setVolume(newVolume)
        currGui.guiObj[currProgramName . "Progress"].Value := newVolume
    }
}

; locks/unlocks the user selection on the volume progress bar
;  currProgramName - name of program to adjust, or master (system)
;
; returns null
updateChangeVolume(currProgramName := "master") {
    global MASTERVOLUME
    global CHANGEVOLUME
    global globalGuis

    static currHotkeys := Map()

    currGui := globalGuis[GUIVOLUMETITLE]
    if (!currGui) {
        return
    }

    ; if user is locked -> restore old hotkeys & unlock
    if (CHANGEVOLUME) {
        currGui.hotkeys := currHotkeys
        
        if (currProgramName = "master") {
            currGui.guiObj["MasterProgress"].Opt("c" . FONTCOLOR)
        }
        else {
            currGui.guiObj[currProgramName . "Progress"].Opt("c" . FONTCOLOR)
        }
    }

    ; if user is unlocked -> save hotkeys & lock user
    else {
        currHotkeys := currGui.hotkeys

        newHotkeys := Map()
        newHotkeys["[REPEAT]LSX>0.2|LSY>0.2"]   := "updateVolume 1 " . currProgramName
        newHotkeys["[REPEAT]LSX<-0.2|LSY<-0.2"] := "updateVolume -1 " . currProgramName
        newHotkeys["[REPEAT]DR|DU"]             := "updateVolume 10 " . currProgramName
        newHotkeys["[REPEAT]DL|DD"]             := "updateVolume -10 " . currProgramName
        newHotkeys["A|B"] := "updateChangeVolume " . currProgramName

        currGui.hotkeys := newHotkeys

        if (currProgramName = "master") {
            currGui.guiObj["MasterProgress"].Opt("c" . COLOR3)
        }
        else {
            currGui.guiObj[currProgramName . "Progress"].Opt("c" . COLOR3)
        }
    }

    ; keeps track of if user is locked in volume control
    CHANGEVOLUME := !CHANGEVOLUME
}