class PowerInterface extends Interface {
    guiWidth := 0
    guiHeight := 0

    _restoreMousePos := []

    __New() {
        global globalConfig

        super.__New(INTERFACES["power"]["wndw"], GUI_OPTIONS . " +AlwaysOnTop +Overlay000000")

        this.unselectColor := COLOR2
        this.selectColor   := COLOR3

        this.guiObj.BackColor := COLOR1

        marginSize := percentWidth(0.01)
        this.guiObj.MarginX := marginSize
        this.guiObj.MarginY := marginSize
        
        buttonSize := percentWidth(0.07)
        buttonSpacing := percentWidth(0.018)
        powerOptions := this._createPowerOptions()

        this.SetFont("bold s22")

        index := 0
        for item in powerOptions.order {
            index += 1

            if (index = 1) {
                this.Add("Picture", "v" . item . " f(" . powerOptions.items[item].function . ") Section ypos1 xpos" . index . " xm0 ym0 w" . buttonSize . " h" . buttonSize, getAssetPath("icons\gui\" . powerOptions.items[item].icon . ".png", globalConfig))
                this.Add("Text", "Center wp0 xp0 y+" . (buttonSpacing / 3), powerOptions.items[item].title)
            }
            else {
                this.Add("Picture", "v" . item . " f(" . powerOptions.items[item].function . ") Section ypos1 xpos" . index . " xs+" . (buttonSize + buttonSpacing) . " ym0 w" . buttonSize . " h" . buttonSize, getAssetPath("icons\gui\" . powerOptions.items[item].icon . ".png", globalConfig))
                this.Add("Text", "Center wp0 xp0 y+" . (buttonSpacing / 3), powerOptions.items[item].title)
            }
        }

        this.guiWidth := (buttonSize * index) + (buttonSpacing * (index - 1)) + (marginSize * 2)
        this.guiHeight := percentHeight(0.2)        
    }

    _Show() {
        global globalStatus

        if (globalStatus["kbmmode"] || globalStatus["desktopmode"]) {
            MouseGetPos(&x, &y)
            this._restoreMousePos := [x, y]
        }

        guiX := MONITOR_X + ((MONITOR_W / 2) - (this.guiWidth / 2))
        guiY := MONITOR_Y + ((MONITOR_H / 2) - (this.guiHeight / 2))
        super._Show("x" . guiX . " y" . guiY . " w" . this.guiWidth . " h" . this.guiHeight)

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

        selected := this.control2D[this.currentX][this.currentY].select

        this.Destroy()
        globalStatus["input"]["buffer"].Push(selected)
    }

    ; adds power options based on selected options from global config
    ; 
    ; returns powers order & options
    _createPowerOptions() {
        global globalConfig

        defaultOptions := Map()
        defaultOptions["Standby"]  := {title: "Standby",  function: "Standby",  icon: "standby"}
        defaultOptions["Shutdown"] := {title: "Shutdown", function: "PowerOff", icon: "power"}
        defaultOptions["Restart"]  := {title: "Restart",  function: "Restart",  icon: "restart"}
        defaultOptions["Reset"] := {title: "Reload", function: "ResetScript", icon: "reload"}
        defaultOptions["Exit"] := {title: "Exit", function: "ExitScript", icon: "close"}

        optionsOrder := []
        if (globalConfig["GUI"].Has("PowerOptions") && IsObject(globalConfig["GUI"]["PowerOptions"])) {
            optionsOrder := globalConfig["GUI"]["PowerOptions"]

            for item in optionsOrder {
                if (!defaultOptions.Has(item)) {
                    defaultOptions.Delete(item)
                }
            }
        }

        return {order: optionsOrder, items: defaultOptions}
    }
}