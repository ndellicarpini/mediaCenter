class VolumeInterface extends Interface {
    id := "volume"
    title := INTERFACES["volume"]["wndw"]

    guiWidth := 0
    guiHeight := 0

    masterVolume := 0
    masterMute := false

    changingVolume := ""

    __New() {
        this.masterVolume := SoundGetVolume()
    
        global globalConfig
        global globalRunning

        super.__New(GUI_OPTIONS . " +AlwaysOnTop")

        this.unselectColor := COLOR2
        this.selectColor := COLOR3

        this.guiObj.BackColor := COLOR1
        this.guiObj.MarginX := interfaceHeight(0.01)
        this.guiObj.MarginY := interfaceHeight(0.01)

        this.guiWidth  := interfaceWidth(0.2)
        this.guiHeight := interfaceHeight(0.17)
        maxHeight := interfaceHeight(1)

        this.SetFont("bold s24")
        this.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 ym5 h" . interfaceHeight(0.05) . " w" . (this.guiWidth - interfaceHeight(0.02)), "Volume Control")

        volControlWidth     := interfaceWidth(0.16)
        volControlHeight    := interfaceHeight(0.035)
        volControlSelectBox := interfaceHeight(0.01)

        ; --- ADD MASTER VOLUME CONTROL ---
        this.SetFont("norm s20")
        this.Add("Text", "Section xm0 y+" . interfaceHeight(0.018), "Master")
        this.Add("Text", "vMasterControl Center f(changeVolume master) xpos1 ypos1 Background" . COLOR2 " h" . volControlHeight . " w" . volControlWidth . " y+" . interfaceHeight(0.0065), "")
        this.Add("Progress", "vMasterProgress Background" . COLOR2 . " c" . FONT_COLOR 
            . " h" . (volControlHeight - volControlSelectBox) . " w" . (volControlWidth - volControlSelectBox) . " yp" . (volControlSelectBox / 2) . " xm" . (volControlSelectBox / 2), SoundGetVolume())
        
        this.Add("Picture", "vMasterMute f(muteVolume master) xpos2 ypos1 yp-" . (volControlSelectBox / 2) . " x+" . interfaceWidth(0.012) . " h" . volControlHeight . " w" . volControlHeight
            , (!this.masterMute) ? getAssetPath("icons\gui\volume.png", globalConfig) : getAssetPath("icons\gui\volume-off.png", globalConfig))

        ; clean the program list
        programList := []
        for key, value in globalRunning {
            if (value.background) {
                continue
            }

            ; ignore programs with no audio interface initialized
            if (!value.muted || value.volume = -1) {
                value.checkVolume()
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
            if (this.guiHeight < maxHeight) {
                newHeight := this.guiHeight + interfaceHeight(0.088)
                this.guiHeight := (newHeight > maxHeight) ? maxHeight : newHeight
            }

            currProgram := globalRunning[programList[A_Index]]

            this.Add("Text", "Section xm0 y+" . interfaceHeight(0.018), globalRunning[programList[A_Index]].name)
            this.Add("Text", "v" . programList[A_Index] . "Control Center f(changeVolume " . programList[A_Index] . ") xpos1 ypos" . (A_Index + 1) . " Background" . COLOR2 " h" . volControlHeight . " w" . volControlWidth . " y+" . interfaceHeight(0.0065), "")
            this.Add("Progress", "v" . programList[A_Index] . "Progress Background" . COLOR2 . " c" . FONT_COLOR 
                . " h" . (volControlHeight - volControlSelectBox) . " w" . (volControlWidth - volControlSelectBox) . " yp" . (volControlSelectBox / 2) . " xm" . (volControlSelectBox / 2), (currProgram.muted) ? 0 : currProgram.volume)
            
            this.Add("Picture", "v" . programList[A_Index] . "Mute f(muteVolume " . programList[A_Index] . ") xpos2 ypos" . (A_Index + 1) . " yp-" . (volControlSelectBox / 2) . " x+" . interfaceWidth(0.012) . " h" . volControlHeight . " w" . volControlHeight
                , (!currProgram.muted) ? getAssetPath("icons\gui\volume.png", globalConfig) : getAssetPath("icons\gui\volume-off.png", globalConfig))
        }
    }

    _Show() {
        super._Show("y0 x" . interfaceWidth(0.25) . " w" . this.guiWidth . " h" . this.guiHeight)
    }

    _select() {
        if (this.changingVolume != "") {
            this._unFocusSlider()
            return
        }

        funcArr := StrSplit(this.control2D[this.currentX][this.currentY].select, A_Space)
        if (funcArr[1] = "changeVolume") {
            this._focusSlider(funcArr[2])
        }
        else if (funcArr[1] = "muteVolume") {
            this._mute(funcArr[2])
        }
        else {
            super._select()
        }
    }

    _back() {
        if (this.changingVolume != "") {
            this._unFocusSlider()
            return
        }

        super._back()
    }

    ; TODO - handle slider adjustments in interface as a new type of "Add"

    _up() {
        if (this.changingVolume != "") {
            this._changeVolume(this.changingVolume, 10)
            return
        }

        super._up()
    }

    _down() {
        if (this.changingVolume != "") {
            this._changeVolume(this.changingVolume, -10)
            return
        }

        super._down()
    }

    _left() {
        if (this.changingVolume != "") {
            this._changeVolume(this.changingVolume, -1)
            return
        }

        super._left()
    }

    _right() {
        if (this.changingVolume != "") {
            this._changeVolume(this.changingVolume, 1)
            return
        }

        super._right()
    }

    _mute(name) {
        global globalConfig
        global globalRunning

        ; mute system volume
        if (name = "master") {
            if (this.masterMute) {
                SoundSetVolume(this.masterVolume)
                this.guiObj["MasterProgress"].Value := this.masterVolume
                this.guiObj["MasterMute"].Value := getAssetPath("icons\gui\volume.png", globalConfig)
            }
            else {
                SoundSetVolume(0)
                this.guiObj["MasterProgress"].Value := 0
                this.guiObj["MasterMute"].Value := getAssetPath("icons\gui\volume-off.png", globalConfig)
            }

            this.masterMute := !this.masterMute
            return
        }

        currProgram := globalRunning[name]
        if (currProgram.muted) {
            this.guiObj[name . "Progress"].Value := currProgram.volume
            this.guiObj[name . "Mute"].Value := getAssetPath("icons\gui\volume.png", globalConfig)
        }
        else {
            this.guiObj[name . "Progress"].Value := 0
            this.guiObj[name . "Mute"].Value := getAssetPath("icons\gui\volume-off.png", globalConfig)
        }

        currProgram.muteVolume()
    }

    _changeVolume(name, diff) {
        global globalConfig
        global globalRunning

        if (Type(diff) = "String") {
            diff := Integer(diff)
        }    

        ; adjust system volume
        if (name = "master") {
            currVolume := (this.masterMute) ? this.masterVolume : SoundGetVolume()

            if (currVolume > 0 && diff < 0) {
                newVolume := (currVolume + diff <= 0) ? 0 : currVolume + diff
                
                SoundSetVolume(newVolume)
                this.masterVolume := newVolume
                this.guiObj["MasterProgress"].Value := newVolume
            }
            else if (currVolume < 100 && diff > 0) {
                newVolume := (currVolume + diff >= 100) ? 100 : currVolume + diff
                
                SoundSetVolume(newVolume)
                this.masterVolume := newVolume
                this.guiObj["MasterProgress"].Value := newVolume
            }

            if (this.masterMute) {
                this.masterMute := false
                this.guiObj["MasterMute"].Value := getAssetPath("icons\gui\volume.png", globalConfig)
            }
            
            return
        }
        
        currProgram := globalRunning[name]
        currVolume := currProgram.volume
        
        if (currProgram.muted) {
            currProgram.muteVolume()
            this.guiObj[name . "Progress"].Value := currVolume
            this.guiObj[name . "Mute"].Value := getAssetPath("icons\gui\volume.png", globalConfig)
        }

        if (currVolume > 0 && diff < 0) {
            newVolume := (currVolume + diff <= 0) ? 0 : currVolume + diff
            
            currProgram.setVolume(newVolume)
            this.guiObj[name . "Progress"].Value := newVolume
        }
        else if (currVolume < 100 && diff > 0) {
            newVolume := (currVolume + diff >= 100) ? 100 : currVolume + diff
            
            currProgram.setVolume(newVolume)
            this.guiObj[name . "Progress"].Value := newVolume
        }
    }

    _focusSlider(name) {
        if (name = "master") {
            this.guiObj["MasterProgress"].Opt("c" . COLOR3)
        }
        else {
            this.guiObj[name . "Progress"].Opt("c" . COLOR3)
        }
        
        this.changingVolume := name
    }

    _unFocusSlider() {
        if (this.changingVolume = "master") {
            this.guiObj["MasterProgress"].Opt("c" . FONT_COLOR)
        }
        else {
            this.guiObj[this.changingVolume . "Progress"].Opt("c" . FONT_COLOR)
        }

        this.changingVolume := ""
    }
}