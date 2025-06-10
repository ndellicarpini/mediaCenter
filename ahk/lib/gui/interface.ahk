; creates a wrapper object over a gui that gets added to globalGuis
; this wrapper supports interactions with the controller using a grid that keeps track of interactable controls
; this obj is used like a gui, but 'Add' supports addition params for interaction settings
class Interface {
    ; attributes
    id         := ""
    title      := ""
    guiObj     := ""
    overlayObj := ""

    allowPause := false
    allowFocus := true
    
    ; used for scaling the interface to different screen ratios
    designRatio  := 16/9
    designWidth  := 1920
    designHeight := 1080

    monitorNum := -1
    _monitorX  := 0
    _monitorY  := 0
    _monitorW  := 0
    _monitorH  := 0

    customDeselect := Map()

    ; 2d grid of interactable controls
    control2D := [[]]

    ; current pos of user selection
    currentX := 1
    currentY := 1

    _guiX := 0
    _guiY := 0
    _guiW := 0
    _guiH := 0
    
    _scrollVOffset := 0
    _scrollHOffset := 0

    ; base constructor for interface
    ; designed to be called from descendent __New() function
    __New(options := "", eventObj := "") {
        customOptions := []

        optionsArr := StrSplit(options, A_Space)
        for item in optionsArr {
            if (item != "" && InStr(StrLower(item), "overlay")) {
                this.overlayObj := Gui(GUI_OPTIONS . " +Disabled +ToolWindow +E0x20", "AHKOVERLAY")
                this.overlayObj.BackColor := StrReplace(StrLower(item), "overlay", "")

                customOptions.Push(item)
            }
        }

        for item in customOptions {
            options := StrReplace(options, item, "")
        }
        
        ; create the gui object
        if (eventObj != "") {
            this.guiObj := Gui(options, this.title, eventObj)
        }
        else {
            this.guiObj := Gui(options, this.title)
        }

        this.time := A_TickCount
        this._setMonitorInfo()
    }
    

    ; exactly like gui.show except renders the selected item w/ the proper background
    ;  options - see gui.show
    ;
    ; returns null
    Show(options := "") {
        restoreCritical := A_IsCritical
        Critical("On")

        this._setMonitorInfo()

        if (options != "") {
            retVal := this._Show(options)
        }
        else {
            retVal := this._Show()
        }
        
        Critical(restoreCritical)
        return retVal
    }
    _Show(options := "") {
        optionsArr := StrSplit(options, A_Space)
        monitorDPI := MonitorGetDPI(this.monitorNum)

        for item in optionsArr {
            if (StrLower(SubStr(item, 1, 1)) = "x") {
                this._guiX := this._monitorX + Round(Integer(SubStr(item, 2)) * (monitorDPI / A_ScreenDPI))
                ; if the gui is drawn right on the edge of a monitor -> will use previous monitor as dpi reference
                ; adjust gui position to use proper dpi
                if (this._guiX = this._monitorX) {
                    this._guiX += 1
                }

                options := StrReplace(options, item, "x" . this._guiX)
            }
            else if (StrLower(SubStr(item, 1, 1)) = "y") {
                this._guiY := this._monitorY + Round(Integer(SubStr(item, 2)) * (monitorDPI / A_ScreenDPI))
                ; if the gui is drawn right on the edge of a monitor -> will use previous monitor as dpi reference
                ; adjust gui position to use proper dpi
                if (this._guiY = this._monitorY) {
                    this._guiY += 1
                }

                options := StrReplace(options, item, "y" . this._guiY)
            }
            else if (StrLower(SubStr(item, 1, 1)) = "w") {
                this._guiW := Integer(SubStr(item, 2))
                ; for whatever reason, gui width needs to use values relative to primary screen dpi
                if (this._guiW > this._monitorW * (A_ScreenDPI / monitorDPI)) {
                    this._guiW := this._monitorW * (A_ScreenDPI / monitorDPI)
                }

                options := StrReplace(options, item, "w" . this._guiW - 1)
            }
            else if (StrLower(SubStr(item, 1, 1)) = "h") {
                this._guiH := Integer(SubStr(item, 2))
                ; for whatever reason, gui height needs to use values relative to primary screen dpi
                if (this._guiH > this._monitorH * (A_ScreenDPI / monitorDPI)) {
                    this._guiH := this._monitorH * (A_ScreenDPI / monitorDPI)
                }

                options := StrReplace(options, item, "h" . this._guiH)
            }
        }

        selectedControl := ""
        loop this.control2D.Length {
            x_index := A_Index

            loop this.control2D[x_index].Length {
                y_index := A_Index

                currControl := this.control2D[x_index][y_index].control

                if (currControl != "") {
                    if (this.currentX = x_index && this.currentY = y_index) {
                        this.guiObj[currControl].Opt("Background" . this.selectColor)
                        selectedControl := currControl
                    }
                    else if (currControl != selectedControl) {
                        this.guiObj[currControl].Opt("Background" . ((this.customDeselect.Has(currControl)) ? this.customDeselect[currControl] : this.unselectColor))
                    }
                }
            }
        }

        if (this.overlayObj != "") {
            this.overlayObj.Show("x" . this._monitorX . " y" . this._monitorY . " w" . this._calcPercentWidth(1) . " h" . this._calcPercentHeight(1))
            WinSetTransparent(200, "AHKOVERLAY")
        }

        return this.guiObj.Show(options)
    }

    ; exactly like gui.Hide
    ;
    ; returns null
    Hide() {
        restoreCritical := A_IsCritical
        Critical("On")

        retVal := this._Hide()
        
        Critical(restoreCritical)
        return retVal
    }
    _Hide() {
        return this.guiObj.Hide()
    }

    ; exactly like gui.destroy
    ; 
    ; returns null
    Destroy(updateGlobalGuis := true) {
        global globalStatus
        global globalGuis

        restoreCritical := A_IsCritical
        Critical("On")

        this._Destroy()

        if (this.overlayObj != "") {
            try this.overlayObj.Destroy()
            this.overlayObj := ""
        }
                
        Sleep(80)

        ; sometimes destroy doesn't work, so double check
        if (WinShown(this.title)) {
            WinClose(this.title)
        }
        if (WinExist("AHKOVERLAY")) {
            WinCloseAll("AHKOVERLAY")
        }

        if (updateGlobalGuis) {
            updateGuis()
        }

        Critical(restoreCritical)
    }
    _Destroy() {
        if (this.guiObj != "") {
            try this.guiObj.Destroy()
            this.guiObj := ""
        }
    }

    ; exactly like gui.add, but supports additional params
    ;  type - see gui.add
    ;  options - see gui.add w/ additional support for:
    ;    xpos - xposition of control in gui (for user selection)
    ;         - if -1 -> gui considered in every x @ current y at time of add
    ;    ypos - yposition of control in gui (for user selection)
    ;         - if -1 -> gui considered in every y @ current x at time of add
    ;    f(x) - function string (x) to be ran on select of control using runFunction
    ;    u(x) - function string (x) to be ran on release of control using runFunction
    ;  text - see gui.add
    ;
    ; returns null
    Add(type, options := "", text := "") {
        return this._Add(type, options, text)
    }
    _Add(type, options, text) {
        optionsArr := StrSplit(options, A_Space)
        removeArr := []

        addControl := false
        controlName := ""
        controlSelectFunc := ""
        controlUnSelectFunc := ""

        controlDeselect := ""
        xposArr := []
        yposArr := []

        currItem := ""
        inFunction := ""
        for item in optionsArr {
            ; loop to support functions w/ params
            if (inFunction != "") {
                currItem .= item . A_Space

                if (SubStr(item, -1, 1) = ")") {
                    currItem := RTrim(currItem, A_Space)
                    if (inFunction = "select") {
                        controlSelectFunc := SubStr(currItem, 3, StrLen(currItem) - 3)
                    }
                    else {
                        controlUnSelectFunc := SubStr(currItem, 3, StrLen(currItem) - 3)
                    }

                    removeArr.Push(currItem)
                    inFunction := ""
                    addControl := true
                }

                continue
            }

            ; get name of control for key
            if (SubStr(item, 1, 1) = "v") {
                controlName := SubStr(item, 2)
            }

            ; check for custom fallback background
            else if (SubStr(item, 1, 10) = "Background") {
                controlDeselect := SubStr(item, 10)
            }

            ; check for a select function string
            else if (SubStr(item, 1, 2) = "f(") {
                if (SubStr(item, -1, 1) = ")") {
                    controlSelectFunc := SubStr(item, 3, StrLen(item) - 3)

                    removeArr.Push(item)
                    addControl := true
                }
                else {
                    currItem := item . A_Space
                    inFunction := "select"
                }
            }

            ; check for a unselect function string
            else if (SubStr(item, 1, 2) = "u(") {
                if (SubStr(item, -1, 1) = ")") {
                    controlUnSelectFunc := SubStr(item, 3, StrLen(item) - 3)

                    removeArr.Push(item)
                    addControl := true
                }
                else {
                    currItem := item . A_Space
                    inFunction := "unselect"
                }
            }

            ; check for a xpos string
            else if (SubStr(item, 1, 4) = "xpos") {
                if (InStr(item, "-")) {
                    xposRange := StrSplit(item, "-")

                    if (xposRange[1] = "xpos") {
                        xposArr.Push(xposRange[2])
                    }
                    else {
                        xposRange[1] := Integer(StrReplace(xposRange[1], "xpos", ""))
                        xposRange[2] := Integer(xposRange[2])
    
                        xposArr.Push(xposRange[1])
                        loop (xposRange[2] - xposRange[1]) {
                            xposArr.Push(xposRange[1] + A_Index)
                        }
                    }
                }
                else {
                    xposArr.Push(Integer(SubStr(item, 5)))
                }
                
                removeArr.Push(item)
                addControl := true
            }

            ; check for a xpos string
            else if (SubStr(item, 1, 4) = "ypos") {
                if (InStr(item, "-")) {
                    yposRange := StrSplit(item, "-")

                    if (yposRange[1] = "ypos") {
                        yposArr.Push(yposRange[2])
                    }  
                    else {
                        yposRange[1] := Integer(StrReplace(yposRange[1], "ypos", ""))
                        yposRange[2] := Integer(yposRange[2])
    
                        yposArr.Push(yposRange[1])
                        loop (yposRange[2] - yposRange[1]) {
                            yposArr.Push(yposRange[1] + A_Index)
                        }
                    }                  
                }
                else {
                    yposArr.Push(Integer(SubStr(item, 5)))
                }

                removeArr.Push(item)
                addControl := true
            }
        }

        ; if control is interactable
        if (addControl && controlName != "") {
            ; if an axis pos is missing, default to all slots
            if (xposArr.Length > 0 && yposArr.Length = 0) {
                yposArr.Push(-1)
            }
            if (xposArr.Length = 0 && yposArr.Length > 0) {
                xposArr.Push(-1)
            }

            for xpos in xposArr {
                for ypos in yposArr {
                    ; add empty slots if xpos > max xpos
                    if (xpos > 0) {
                        while (this.control2D.Length < xpos) {
                            this.control2D.Push([])
                        }
                    }
                    
                    ; add empty slots if ypos > max ypos
                    if (ypos > 0) {
                        if (xpos = -1) {
                            loop this.control2D.Length {
                                x_index := A_Index
            
                                while(this.control2D[x_index].Length < ypos) {
                                    this.control2D[x_index].Push({control: "", select: "", unselect: ""})
                                }
                            }
                        }
                        else {
                            while(this.control2D[xpos].Length < ypos) {
                                this.control2D[xpos].Push({control: "", select: "", unselect: ""})
                            }
                        }
                    }
                    
                    ; put the interactable data in every slot
                    if (xpos = -1 && ypos = -1) {
                        loop this.control2D.Length {
                            x_index := A_Index

                            loop this.control2D[x_index].Length {
                                y_index := A_Index

                                if (this.control2D[x_index][y_index].control = "") {
                                    this.control2D[x_index][y_index] := {
                                        control: controlName, 
                                        select: controlSelectFunc,
                                        unselect: controlUnSelectFunc
                                    }
                                }
                            }
                        }
                    }

                    ; put the interactable data in every slot at same ypos
                    else if (xpos = -1) {
                        loop this.control2D.Length {
                            if (this.control2D[A_Index][ypos].control = "") {
                                this.control2D[A_Index][ypos] := {
                                    control: controlName, 
                                    select: controlSelectFunc,
                                    unselect: controlUnSelectFunc
                                }
                            }
                        }
                    }

                    ; put the interactable data in every slot at same xpos
                    else if (ypos = -1) {
                        loop this.control2D[xpos].Length {
                            if (this.control2D[xpos][A_Index].control = "") {
                                this.control2D[xpos][A_Index] := {
                                    control: controlName, 
                                    select: controlSelectFunc,
                                    unselect: controlUnSelectFunc
                                }
                            }
                        }
                    }

                    ; put the interactable data in the requested slot
                    else {
                        this.control2D[xpos][ypos] := {
                            control: controlName, 
                            select: controlSelectFunc,
                            unselect: controlUnSelectFunc
                        }
                    }
                }
            }

            if (controlDeselect != "") {
                this.customDeselect[controlName] := controlDeselect
            }
        }

        cleanOptions := options
        for item in removeArr {
            cleanOptions := StrReplace(cleanOptions, item,,,, 1)
        }

        if (text != "") {
            return this.guiObj.Add(type, cleanOptions, text)
        }
        else {
            return this.guiObj.Add(type, cleanOptions)
        }
    }

    ; exactly like gui.setfont, but supports additional params
    ;  enableSizing - scales the font size based on gui scaling from config
    ;
    ; returns gui.setfont
    SetFont(options := "s15", enableSizing := true) {
        return this._SetFont(options, enableSizing)
    }
    _SetFont(options, enableSizing) {
        global FONT
        global FONT_COLOR
        global SIZE

        if (!MonitorGetValid(this.monitorNum)) {
            this._setMonitorInfo()
        }

        optionsMap := Map()
        optionsMap["c"] := FONT_COLOR

        ; set options from parameter
        if (options != "") {
            if (Type(options) != "String") {
                ErrorMsg("gui.SetFont options must be a string")
                return
            }

            optionsArr := StrSplit(options, A_Space)
            for item in optionsArr {
                key := SubStr(item, 1, 1)
                value := SubStr(item, 2)

                if (StrLower(key) = "c" && SubStr(value, 1, 1) = "#") {
                    optionsMap[key] := SubStr(value, 2)
                }
                else {
                    optionsMap[key] := value
                }
            }
        }

        ; update the font size if the size multiplier is enabled
        ; the font size is scaled based on the 96 / screen's dpi (96 = default windows dpi)
        ; its also scaled by the monitor height compared to design 
        if (enableSizing) {
            optionsMap["s"] := toString(this._calcFontSize(optionsMap["s"]))
        }

        ; convert optionMap into properly formatted options string
        optionString := ""
        for key, value in optionsMap {
            optionString .= key . value . A_Space
        }

        optionString := RTrim(optionString, A_Space)
        if (FONT != "") {
            this.guiObj.SetFont(optionString, FONT)
        }
        else {
            this.guiObj.SetFont(optionString)
        }
    }

    ; runs the select function defined in the selected control's interactable data
    ;
    ; returns null
    select() {
        this._select()
    }
    _select() {
        global globalStatus

        if (this.control2D[this.currentX][this.currentY].select != "") {
            try {
                runFunction(this.control2D[this.currentX][this.currentY].select)
            }
            catch {
                globalStatus["input"]["buffer"].Push(this.control2D[this.currentX][this.currentY].select)
            }
        }
    }

    ; runs the unselect function defined in the selected control's interactable data
    ;
    ; returns null
    unselect() {
        this._unselect()
    }
    _unselect() {
        global globalStatus

        if (this.control2D[this.currentX][this.currentY].unselect != "") {
            try {
                runFunction(this.control2D[this.currentX][this.currentY].unselect)
            }
            catch {
                globalStatus["input"]["buffer"].Push(this.control2D[this.currentX][this.currentY].unselect)
            }
        }
    }

    ; goes back, usually overridden w/ custom function 
    ;
    ; returns null
    back() {
        this._back()
    }
    _back() {
        this.Destroy()
    }

    ; --- MOVEMENT FUNCTIONS ---
    ; moves the user selection in the requested direction of the gui 
    ; basically just colors the background of a control to be considered selected
    ; skips controls that don't have a key & wraps around both axis

    up() {
        this._up()
    }
    _up() {  
        currControl := this.control2D[this.currentX][this.currentY].control
        nextX := 0
        nextY := 0

        longestCol := 0
        loop this.control2D.Length {
            if (this.control2D[A_Index].Length > longestCol) {
                longestCol := this.control2D[A_Index].Length
            } 
        }

        currCol := []
        loop longestCol {
            row := A_Index

            xAdjust := 0
            foundValid := false
            while (!foundValid) {
                if (xAdjust >= this.currentX) {
                    break
                }

                if (row <= this.control2D[this.currentX - xAdjust].Length) {
                    controlName := this.control2D[this.currentX - xAdjust][row].control
                    if (controlName != "" && this.guiObj[controlName].Visible) {
                        if (controlName = currControl && row != this.currentY) {
                            xAdjust += 1
                            continue
                        }

                        foundValid := true
                        currCol.Push({
                            x: this.currentX - xAdjust,
                            y: row
                        })
                    }
                }
            
                xAdjust += 1
            }
        }

        loop currCol.Length {
            if (currCol[A_Index].y = this.currentY) {
                if (A_Index = 1) {
                    nextX := currCol[currCol.Length].x
                    nextY := currCol[currCol.Length].y
                }
                else {
                    nextX := currCol[A_Index - 1].x
                    nextY := currCol[A_Index - 1].y
                }
            }
        }

        this.guiObj[currControl].Opt("Background" . ((this.customDeselect.Has(currControl)) ? this.customDeselect[currControl] : this.unselectColor))
        this.guiObj[currControl].Redraw()
        this.currentX := nextX
        this.currentY := nextY

        newControl := this.control2D[this.currentX][this.currentY].control

        this.guiObj[newControl].Opt("Background" . this.selectColor)
        this.guiObj[newControl].Redraw()
        
        this._checkScrollVertical(this.guiObj[newControl])
    }
    
    down() {
        this._down()
    }
    _down() {    
        currControl := this.control2D[this.currentX][this.currentY].control
        nextX := 0
        nextY := 0

        longestCol := 0
        loop this.control2D.Length {
            if (this.control2D[A_Index].Length > longestCol) {
                longestCol := this.control2D[A_Index].Length
            } 
        }

        currCol := []
        loop longestCol {
            row := A_Index

            xAdjust := 0
            foundValid := false
            while (!foundValid) {
                if (xAdjust >= this.currentX) {
                    break
                }

                if (row <= this.control2D[this.currentX - xAdjust].Length) {
                    controlName := this.control2D[this.currentX - xAdjust][row].control
                    if (controlName != "" && this.guiObj[controlName].Visible) {
                        if (controlName = currControl && row != this.currentY) {
                            xAdjust += 1
                            continue
                        }

                        foundValid := true
                        currCol.Push({
                            x: this.currentX - xAdjust,
                            y: row
                        })
                    }
                }
            
                xAdjust += 1
            }
        }

        loop currCol.Length {
            if (currCol[A_Index].y = this.currentY) {
                if (A_Index = currCol.Length) {
                    nextX := currCol[1].x
                    nextY := currCol[1].y
                }
                else {
                    nextX := currCol[A_Index + 1].x
                    nextY := currCol[A_Index + 1].y
                }
            }
        }
    
        this.guiObj[currControl].Opt("Background" . ((this.customDeselect.Has(currControl)) ? this.customDeselect[currControl] : this.unselectColor))
        this.guiObj[currControl].Redraw()
        this.currentX := nextX
        this.currentY := nextY

        newControl := this.control2D[this.currentX][this.currentY].control

        this.guiObj[newControl].Opt("Background" . this.selectColor)
        this.guiObj[newControl].Redraw()
        
        this._checkScrollVertical(this.guiObj[newControl])
    }
    
    left() {
        this._left()
    }
    _left() {    
        currControl := this.control2D[this.currentX][this.currentY].control
        nextX := 0
        nextY := 0

        currRow := []
        loop this.control2D.Length {
            col := A_Index

            loop this.control2D[col].Length {
                row := A_Index

                controlName := this.control2D[col][row].control
                if (row = this.currentY && controlName != "" && this.guiObj[controlName].Visible) {
                    if (controlName = currControl && col != this.currentX) {
                        continue
                    }

                    currRow.Push({
                        x: col,
                        y: row
                    })
                }
            }
        }

        loop currRow.Length {
            if (currRow[A_Index].x = this.currentX) {
                if (A_Index = 1) {
                    nextX := currRow[currRow.Length].x
                    nextY := currRow[currRow.Length].y
                }
                else {
                    nextX := currRow[A_Index - 1].x
                    nextY := currRow[A_Index - 1].y
                }
            }
        }
    
        this.guiObj[currControl].Opt("Background" . ((this.customDeselect.Has(currControl)) ? this.customDeselect[currControl] : this.unselectColor))
        this.guiObj[currControl].Redraw()
        this.currentX := nextX
        this.currentY := nextY

        newControl := this.control2D[this.currentX][this.currentY].control

        this.guiObj[newControl].Opt("Background" . this.selectColor)
        this.guiObj[newControl].Redraw()

        this._checkScrollHorizontal(this.guiObj[newControl])
    }
    
    right() {
        this._right()
    }
    _right() {   
        currControl := this.control2D[this.currentX][this.currentY].control 
        nextX := 0
        nextY := 0

        currRow := []
        loop this.control2D.Length {
            col := A_Index

            loop this.control2D[col].Length {
                row := A_Index

                controlName := this.control2D[col][row].control
                if (row = this.currentY && controlName != "" && this.guiObj[controlName].Visible) {
                    if (controlName = currControl && col != this.currentX) {
                        continue
                    }

                    currRow.Push({
                        x: col,
                        y: row
                    })
                }
            }
        }

        loop currRow.Length {
            if (currRow[A_Index].x = this.currentX) {
                if (A_Index = currRow.Length) {
                    nextX := currRow[1].x
                    nextY := currRow[1].y
                }
                else {
                    nextX := currRow[A_Index + 1].x
                    nextY := currRow[A_Index + 1].y
                }
            }
        }
    
        this.guiObj[currControl].Opt("Background" . ((this.customDeselect.Has(currControl)) ? this.customDeselect[currControl] : this.unselectColor))
        this.guiObj[currControl].Redraw()
        this.currentX := nextX
        this.currentY := nextY

        newControl := this.control2D[this.currentX][this.currentY].control
        
        this.guiObj[newControl].Opt("Background" . this.selectColor)
        this.guiObj[newControl].Redraw()

        this._checkScrollHorizontal(this.guiObj[newControl])
    }

    ; check if the selected control is outside of the wndw & vertically scroll if it is
    _checkScrollVertical(selectedControl) {
        y := 0
        h := 0
        
        ControlGetPos(, &y,, &h, selectedControl)
        y += this._guiY

        scaledGuiH := this._guiH * (MonitorGetDPI(this.monitorNum) / A_ScreenDPI)
        if (this.currentY = 1) {
            DllCall("ScrollWindow", "Ptr", this.guiObj.Hwnd, "Int", 0, "Int", (-1 * this._scrollVOffset), "Ptr", 0, "Ptr", 0)
            this._scrollVOffset := 0
        }
        else if (y < this._monitorY) {
            diff := -1 * (y - this._calcPercentHeight(0.005))
            DllCall("ScrollWindow", "Ptr", this.guiObj.Hwnd, "Int", 0, "Int", diff, "Ptr", 0, "Ptr", 0)
            this._scrollVOffset += diff
        }
        else if ((y + h) > (this._guiY + scaledGuiH)) {
            diff := -1 * (Abs((y + h) - (this._guiY + scaledGuiH)) + this._calcPercentHeight(0.005))
            DllCall("ScrollWindow", "Ptr", this.guiObj.Hwnd, "Int", 0, "Int", diff, "Ptr", 0, "Ptr", 0)
            this._scrollVOffset += diff
        }
    }

    ; check if the selected control is outside of the wndw & horizontally scroll if it is
    _checkScrollHorizontal(selectedControl) {
        x := 0
        w := 0
        
        ControlGetPos(&x,, &w,, selectedControl)
        x += this._guiX

        scaledGuiW := this._guiW * (MonitorGetDPI(this.monitorNum) / A_ScreenDPI)
        if (this.currentX = 1) {
            DllCall("ScrollWindow", "Ptr", this.guiObj.Hwnd, "Int", (-1 * this._scrollHOffset), "Int", 0, "Ptr", 0, "Ptr", 0)
            this._scrollHOffset := 0
        }
        else if (x < this._monitorX) {
            diff := -1 * (x - this._calcPercentWidth(0.005))
            DllCall("ScrollWindow", "Ptr", this.guiObj.Hwnd, "Int", diff, "Int", 0, "Ptr", 0, "Ptr", 0)
            this._scrollHOffset += diff
        }
        else if ((x + w) > (this._guiX + scaledGuiW)) {
            diff := -1 * (Abs((x + w) - (this._guiX + scaledGuiW)) + this._calcPercentWidth(0.005))
            DllCall("ScrollWindow", "Ptr", this.guiObj.Hwnd, "Int", diff, "Int", 0, "Ptr", 0, "Ptr", 0)
            this._scrollHOffset += diff
        }
    }

    ; sets the appropriate monitor variables based on globalStatus
    _setMonitorInfo() {
        global globalStatus
        global DEFAULT_MONITOR
        
        this.monitorNum := DEFAULT_MONITOR
        if (!globalStatus["suspendScript"] && !globalStatus["desktopmode"] 
            && globalStatus["currProgram"]["id"] != "" && globalStatus["currProgram"]["monitor"] != -1) {
            
            this.monitorNum := globalStatus["currProgram"]["monitor"]
        }

        monitorInfo := getMonitorInfo(this.monitorNum)
        this._monitorX := monitorInfo[1]
        this._monitorY := monitorInfo[2]
        this._monitorW := monitorInfo[3]
        this._monitorH := monitorInfo[4]
    }

    ; calculates the percent width of the current monitor
    ; keeps the aspect ratio relative to the original design aspect ratio of 16/9
    ;  percent - percent width of monitor (0-1)
    ;  useSize - whether to apply the size multiplier from global.cfg
    ;  fixAspectRatio - whether to correct the value based on the different between screen & design ratios
    ;
    ; returns percent width of monitor
    _calcPercentWidth(percent, useSize := true, fixAspectRatio := true) {
        global SIZE

        if (!MonitorGetValid(this.monitorNum)) {
            this._setMonitorInfo()
        }

        aspectRatioMult := this.designRatio / (this._monitorW / this._monitorH)
        retVal := percent * this._monitorW * (fixAspectRatio ? aspectRatioMult : 1) * (useSize ? SIZE : 1)
        
        return Min(retVal, this._monitorW) * (A_ScreenDPI / MonitorGetDPI(this.monitorNum))
    }

    ; calculates the percent height of the current monitor
    ; keeps the aspect ratio relative to the original design aspect ratio of 16/9
    ;  percent - percent height of monitor (0-1)
    ;  useSize - whether to apply the size multiplier from global.cfg
    ;  fixAspectRatio - whether to correct the value based on the different between screen & design ratios
    ;
    ; returns percent height of monitor
    _calcPercentHeight(percent, useSize := true, fixAspectRatio := true) {
        global SIZE

        if (!MonitorGetValid(this.monitorNum)) {
            this._setMonitorInfo()
        }

        aspectRatioMult := 1
        retVal := percent * this._monitorH * (fixAspectRatio ? (1 / aspectRatioMult) : 1) * (useSize ? SIZE : 1)
        
        return Min(retVal, this._monitorH) * (A_ScreenDPI / MonitorGetDPI(this.monitorNum))
    }

    ; calculates the font size relative to the original design
    ;  fontSize - original requested font size
    ;
    ; returns adjusted font size for design
    _calcFontSize(fontSize) {
        return Round((96 / MonitorGetDPI(this.monitorNum)) * Float(fontSize) * SIZE * (this._monitorH / this.designHeight))
    }
}

; creates a gui that gets added to globalGuis
;  interfaceKey - key from global INTERFACES containing wndw & class
;  setCurrent - sets the new gui as currGui
;  customTime - override the launch time
;
; returns null
createInterface(interfaceKey, setCurrent := true, customTime := "", args*) {
    global globalConfig
    global globalStatus
    global globalGuis

    if (!INTERFACES.Has(interfaceKey)) {
        ErrorMsg("Invalid Interface Key `n" . interfaceKey)
        return
    }

    interfaceObj := INTERFACES[interfaceKey]

    if (!interfaceObj.Has("wndw") || !interfaceObj.Has("class")) {
        ErrorMsg("Invalid Interface Definition `n" . toString(interfaceObj))
        return
    }

    if (globalGuis.Has(interfaceKey) && WinShown(interfaceObj["wndw"])) {
        setCurrentGui(interfaceKey)
        return
    }

    globalGuis[interfaceKey] := %interfaceObj["class"]%(args*)

    if (globalGuis[interfaceKey].guiObj != "") {
        globalGuis[interfaceKey].guiObj.Title := interfaceObj["wndw"]
    }

    if (setCurrent) {
        setCurrentGui(interfaceKey)
        globalGuis[interfaceKey].Show()
    }

    if (customTime != "") {
        globalGuis[interfaceKey].time := customTime
    }

    return
}

; sets the requested id as the current gui if it exists
;  id - id of gui to set as current
;
; returns null
setCurrentGui(id) {
    global globalStatus

    globalStatus["currGui"] := id
}

; get the most recently opened gui if it exists, otherwise return blank
;
; returns either name of recently opened gui or empty string
getMostRecentGui() {
    global globalGuis

    prevTime := 0
    prevProgram := ""
    for key, value in globalGuis {
        if (value.time > prevTime) {
            prevTime := value.time
            prevProgram := key
        }
    }

    return prevProgram
}

; checks & updates the running list of guis
;
; returns null
checkAllGuis() {
    global globalGuis

    toDelete := []
    for key, value in globalGuis {
        if (value.guiObj = "" || !WinShown(value.guiObj.Title)) {
            toDelete.Push(key)
        }
    }

    for item in toDelete {
        globalGuis.Delete(item)
    }
}

; updates the global guis list & the current gui
;
; returns null
updateGuis() {
    global globalStatus

    currGui := globalStatus["currGui"]

    checkAllGuis()

    mostRecentGui := getMostRecentGui()
    if (mostRecentGui = "") {
        globalStatus["currGui"] := ""
    }
    else if (mostRecentGui != currGui) {
        setCurrentGui(mostRecentGui)
    }
}