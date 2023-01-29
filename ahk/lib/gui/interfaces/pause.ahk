class PauseInterface extends Interface {
    allowPause := true

    monitorTimer := 0
    guiWidth := 0
    guiHeight := 0
    
    __New() {
        global globalConfig
        global globalStatus
        global globalRunning
        global globalPrograms

        currProgram := globalStatus["currProgram"]
        
        ; set activate currProgram pause
        if (currProgram != "") {
            globalRunning[currProgram].pause()
        }

        ; close the keyboard if open
        if (keyboardExists()) {
            closeKeyboard()
        }

        super.__New(INTERFACES["pause"]["wndw"], GUI_OPTIONS . " +AlwaysOnTop")
    
        this.unselectColor := COLOR1
        this.selectColor := COLOR3

        this.guiObj.BackColor := COLOR1
        this.guiObj.MarginX := percentWidth(0.0095)
        this.guiObj.MarginY := percentHeight(0.01)

        this.guiWidth := percentWidth(0.25)
        this.guiHeight := percentHeight(1)

        ; add static elements
        currentTimeArr := StrSplit(FormatTime(, "h:mm tt`ndddd, MMM d yyy"), "`n")

        ; --- ADD TIME & DATE --- 
        this.SetFont("s38")
        this.Add("Text", "vTime Section Center xm0 ym0 w" . (this.guiWidth * 0.46), currentTimeArr[1])

        this.SetFont("s13")
        this.Add("Text", "vDate Center wp0 xm0 y+" . percentHeight(0.008), currentTimeArr[2])

        ; --- ADD MONITORS ---
        this.SetFont()

        if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
            monitorSpacing := percentHeight(0.008)

            this.Add("Text", "vInfoText Section x+" . percentWidth(0.010) . " ys+5", "CPU")
            this.Add("Text", "xs0 y+" . monitorSpacing, "RAM")
            this.Add("Text", "xs0 y+" . monitorSpacing, "GPU")

            this.Add("Progress", "vCPU Background" . COLOR2 . " c" . COLOR3 . " hp0 w" . percentWidth(0.078) . " ys0 x+" . percentWidth(0.006), 0)
            this.Add("Progress", "vRAM Background" . COLOR2 . " c" . COLOR3 . " hp0 wp0 xp0 y+" . monitorSpacing, 0)
            this.Add("Progress", "vGPU Background" . COLOR2 . " c" . COLOR3 . " hp0 wp0 xp0 y+" . monitorSpacing, 0)
        }
        else {
            monitorSpacing := percentHeight(0.038)

            this.Add("Text", "vInfoText Section x+" . percentWidth(0.010) . " ys+5", "CPU")
            this.Add("Text", "xs0 y+" . monitorSpacing, "RAM")

            this.Add("Progress", "vCPU Background" . COLOR2 . " c" . COLOR3 . " hp0 w" . percentWidth(0.078) " ys0 x+" . percentWidth(0.006), 0)
            this.Add("Progress", "vRAM Background" . COLOR2 . " c" . COLOR3 . " hp0 wp0 xp0 y+" . monitorSpacing, 0)
        }

        ; --- ADD TOP ROW BUTTONS ---
        if (globalConfig["Plugins"].Has("DefaultProgram") && globalConfig["Plugins"]["DefaultProgram"] != "") {
            buttonSpacing := percentWidth(0.0097)

            this.Add("Picture", "vHome Section f(createDefaultProgram) xpos1 ypos1 xm0 y+" . percentHeight(0.02) . " w" . percentWidth(0.039) . " h" . percentWidth(0.039), getAssetPath("icons\gui\home.png", globalConfig))
            this.Add("Picture", "vVolume f(createInterface volume) xpos2 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\volume.png", globalConfig))
            this.Add("Picture", "vControllers f(createInterface input) xpos3 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\controller.png", globalConfig))
            this.Add("Picture", "vMulti f(createInterface program) xpos4 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\multitasking.png", globalConfig))
            this.Add("Picture", "vPower f(createInterface power) xpos5 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\power.png", globalConfig))
        }
        else {
            buttonSpacing := percentWidth(0.0257)

            this.Add("Picture", "vVolume Section f(createInterface volume) xpos1 ypos1 xm0 y+" . percentHeight(0.02) . " w" . percentWidth(0.039) . " h" . percentWidth(0.039), getAssetPath("icons\gui\volume.png", globalConfig))
            this.Add("Picture", "vControllers f(createInterface input) xpos2 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\controller.png", globalConfig))
            this.Add("Picture", "vMulti f(createInterface program) xpos3 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\multitasking.png", globalConfig))
            this.Add("Picture", "vPower f(createInterface power) xpos4 ypos1 wp0 hp0 ys0 x+" . buttonSpacing, getAssetPath("icons\gui\power.png", globalConfig))
        }

        ; --- ADD PAUSE OPTIONS ---
        defaultOptions := this._defaultPauseOptions()
        programOptions := this._programPauseOptions((currProgram != "") ? globalRunning[currProgram] : "")

        optionWidth := this.guiWidth - (2 * percentWidth(0.0095))
        optionHeight := percentHeight(0.045)

        y_index := 1

        ; program options
        if (!globalStatus["desktopmode"] && programOptions.items.Count > 0) {
            this.SetFont("bold s24")
            this.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 y+" . percentHeight(0.02) . " h" . percentHeight(0.05) . " w" . optionWidth, globalRunning[currProgram].name)
        
            this.SetFont("norm s20")
            
            for item in programOptions.order {
                if (programOptions.items.Has(item)) {
                    this.Add("Text", "v" . item . " f(" . programOptions.items[item].function . ") 0x200 ypos" . toString(y_index + 1) . " xm0 y+" . percentHeight(0.007) . " h" . optionHeight . " w" . optionWidth, "  " . programOptions.items[item].title)
                    y_index += 1
                }
            }
        }

        ; global options
        if (defaultOptions.items.Count > 0) {
            this.SetFont("bold s23")
            this.Add("Text", "Section Center 0x200 Background" . COLOR2 . " xm0 y+" . percentHeight(0.02) . " h" . percentHeight(0.05) . " w" . optionWidth, "Options")
        
            this.SetFont("norm s19")

            for item in defaultOptions.order {
                if (defaultOptions.items.Has(item)) {
                    this.Add("Text", "v" . item . " f(" . defaultOptions.items[item].function . ") 0x200 ypos" . toString(y_index + 1) . " xm0 y+" . percentHeight(0.007) . " h" . optionHeight . " w" . optionWidth, "  " . defaultOptions.items[item].title)
                    y_index += 1
                }
            }
        }
    }
    
    Show() {
        super.Show("y0 x0 w" . this.guiWidth . " h" . this.guiHeight)
    
        MouseMove(percentWidth(1), percentHeight(1))

        PauseSecondTimer()
        return 

        ; timer triggered each second while pause menu is open
        ; updates the time & monitors
        PauseSecondTimer() {
            global globalConfig
            
            if (!WinShown(INTERFACES["pause"]["wndw"])) {
                return
            }

            currentTimeArr := StrSplit(FormatTime(, "h:mm tt`ndddd, MMM d yyy"), "`n")

            try {
                this.guiObj["Time"].Text := currentTimeArr[1]
                this.guiObj["Date"].Text := currentTimeArr[2]
    
                this.guiObj["CPU"].Value := Ceil(getCpuLoad())
                this.guiObj["RAM"].Value := Ceil(getRamLoad())
    
                if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
                    this.guiObj["GPU"].Value := Ceil(getNvidiaLoad())
                }
            }
            catch {
                return
            }
            
            SetTimer(PauseSecondTimer, -1000)
            return
        }
    }

    Destroy() {
        Sleep(100)
        super.Destroy()
    }

    select() {
        global globalStatus

        funcArr := StrSplit(this.control2D[this.currentX][this.currentY].select, A_Space)

        if (funcArr[1] != "createInterface" || funcArr[2] = "power" || funcArr[2] = "program") {
            this.Destroy()

            if (funcArr[1] = "desktopmode") {
                if (!globalStatus["desktopmode"]) {
                    enableDesktopMode()
                }
                else {
                    disableDesktopMode()
                }
            }
            else {
                currProgram := globalStatus["currProgram"]
                if (currProgram != "") {
                    globalRunning[currProgram].resume()
                }

                if (funcArr[1] = "kbmmode") {
                    if (!globalStatus["kbmmode"]) {
                        enableKBMMode()
                    }
                    else {
                        disableKBMMode()
                    }
                }
                else if (funcArr[1] = "suspendScript") {
                    if (globalStatus["desktopmode"]) {
                        disableDesktopMode()
                    }
                    else {
                        globalStatus["suspendScript"] := !globalStatus["suspendScript"]
                    }
                }
                else {
                    super.select()
                }
            }
        }
        else {
            super.select()
        }
    }

    ; adds default to pause options based on selected options from global config
    ; 
    ; returns default order & options
    _defaultPauseOptions() {
        global globalConfig
        global globalStatus

        defaultOptions := Map()
        defaultOptions["Settings"] := {title: "Consolizer Settings", function: "createSettingsGui global.cfg"}
        
        currKBMMode     := globalStatus["kbmmode"]
        currDesktopMode := globalStatus["desktopmode"]
        currSuspend     := globalStatus["suspendScript"]

        defaultOptions["KBMMode"] := {
            title: (!currKBMMode) ? "Enable KB && Mouse Mode" : "Disable KB && Mouse Mode", 
            function: "kbmmode"
        }
        defaultOptions["DesktopMode"] := {
            title: (!currDesktopMode) ? "Enable Desktop Mode" : "Disable Desktop Mode", 
            function: "desktopmode"
        }
        defaultOptions["Suspend"] := {
            title: (!currSuspend) ? "Suspend Consolizer" : "Resume Consolizer", 
            function: "suspendScript"
        }

        optionsOrder := []
        if (globalConfig["GUI"].Has("DefaultPauseOptions") && IsObject(globalConfig["GUI"]["DefaultPauseOptions"])) {
            optionsOrder := globalConfig["GUI"]["DefaultPauseOptions"]

            for item in optionsOrder {           
                if (!defaultOptions.Has(item)) {
                    try defaultOptions[item] := runFunction(item)
                }
            }
        }

        return {order: optionsOrder, items: defaultOptions}
    }

    ; adds program pause options
    ;  currProgram = program to get pause options from
    ; 
    ; returns program pause settings
    _programPauseOptions(currProgram) {   
        programOptions := Map()

        if (currProgram = "") {
            return {items: Map()}
        }

        if (currProgram != "") {
            for key, value in currProgram.pauseOptions {
                programOptions[RegExReplace(value, "[^a-zA-Z\d]*", "")] := {title: key, function: value}
            }    
        }

        programOrder := []
        if (currProgram.pauseOrder.Length > 0) {
            for item in currProgram.pauseOrder {
                for key, value in programOptions {
                    if (InStr(item, "?") && InStr(item, value.title)) {
                        nameArr := StrSplit(item, "?",, 2)

                        if (runFunction(nameArr[1])) {
                            programOrder.Push(key)
                            break
                        }
                    }

                    if (item = value.title) {
                        programOrder.Push(key)
                        break
                    }
                }
            }
        }
        else {
            for key, value in programOptions {
                programOrder.Push(key)
            }
        }

        ; add exit
        if (currProgram.allowExit) {
            programOptions["ExitProgram"] := {title: "Exit", function: "program.exit"}
            programOrder.Push("ExitProgram")
        }

        return {order: programOrder, items: programOptions}
    }
}