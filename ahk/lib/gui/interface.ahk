; creates a wrapper object over a gui that gets added to globalGuis
; this wrapper supports interactions with the controller using a grid that keeps track of interactable controls
; this obj is used like a gui, but 'Add' supports addition params for interaction settings
class Interface {
    ; attributes
    guiObj := ""
    overlayObj := ""

    allowPause := false
    allowFocus := true

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

    __New(title, options := "", eventObj := "") {
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
            this.guiObj := Gui(options, title, eventObj)
        }
        else {
            this.guiObj := Gui(options, title)
        }

        this.time := A_TickCount
    }

    ; exactly like gui.show except renders the selected item w/ the proper background
    ;  options - see gui.show
    ;
    ; returns null
    Show(options := "") {
        restoreCritical := A_IsCritical
        Critical("On")

        optionsArr := StrSplit(options, A_Space)
        for item in optionsArr {
            if (StrLower(SubStr(item, 1, 1)) = "x") {
                this._guiX := MONITOR_X + Integer(SubStr(item, 2))
                options := StrReplace(options, item, "x" . this._guiX)
            }
            else if (StrLower(SubStr(item, 1, 1)) = "y") {
                this._guiY := MONITOR_Y + Integer(SubStr(item, 2))
                options := StrReplace(options, item, "y" . this._guiY)
            }
            else if (StrLower(SubStr(item, 1, 1)) = "w") {
                this._guiW := Integer(SubStr(item, 2))

                if (this._guiW > MONITOR_W) {
                    this._guiW := MONITOR_W
                    options := StrReplace(options, item, "w" . MONITOR_W)
                }
            }
            else if (StrLower(SubStr(item, 1, 1)) = "h") {
                this._guiH := Integer(SubStr(item, 2))

                if (this._guiH > MONITOR_H) {
                    this._guiH := MONITOR_H
                    options := StrReplace(options, item, "h" . MONITOR_H)
                }
            }
        }

        loop this.control2D.Length {
            x_index := A_Index

            loop this.control2D[x_index].Length {
                y_index := A_Index

                currControl := this.control2D[x_index][y_index].control

                if (currControl != "") {
                    if (this.currentX = x_index && this.currentY = y_Index) {
                        this.guiObj[currControl].Opt("Background" . this.selectColor)
                    }
                    else {
                        this.guiObj[currControl].Opt("Background" . ((this.customDeselect.Has(currControl)) ? this.customDeselect[currControl] : this.unselectColor))
                    }
                }
            }
        }

        if (this.overlayObj != "") {
            this.overlayObj.Show("x0 y0 w" . percentWidth(1) . " h" . percentHeight(1))
            WinSetTransparent(200, "AHKOVERLAY")
        }

        retVal := this.guiObj.Show(options)
        
        Critical(restoreCritical)
        return retVal
    }

    ; exactly like gui.destroy
    ; 
    ; returns null
    Destroy() {
        restoreCritical := A_IsCritical
        Critical("On")

        if (this.overlayObj != "") {
            try this.overlayObj.Destroy()
            this.overlayObj := ""
            SetTimer(OverlayKill, -100)
        }

        if (this.guiObj != "") {
            try this.guiObj.Destroy()
            this.guiObj := ""
        }
        
        Critical(restoreCritical)
        return

        ; omega kill this stupid overlay bc sometimes destroy doesn't work i guess??
        OverlayKill() {
            if (WinExist("AHKOVERLAY")) {
                WinCloseAll("AHKOVERLAY")
            }

            return
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
                    xposRange[1] := Integer(StrReplace(xposRange[1], "xpos", ""))
                    xposRange[2] := Integer(xposRange[2])

                    xposArr.Push(xposRange[1])
                    loop (xposRange[2] - xposRange[1]) {
                        xposArr.Push(xposRange[1] + A_Index)
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
                    yposRange[1] := Integer(StrReplace(yposRange[1], "ypos", ""))
                    yposRange[2] := Integer(yposRange[2])

                    yposArr.Push(yposRange[1])
                    loop (yposRange[2] - yposRange[1]) {
                        yposArr.Push(yposRange[1] + A_Index)
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
                    
                    ; put the interacable data in every slot
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

                    ; put the interacable data in every slot at same ypos
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

                    ; put the interacable data in every slot at same xpos
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

                    ; put the interacable data in the requested slot
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

    ; works the same as Gui
    SetFont(options := "s15", enableSizing := true) {
        return guiSetFont(this.guiObj, options, enableSizing)
    }

    ; runs the select function defined in the selected control's interactable data
    ;
    ; returns null
    select() {
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
    back() {
        this.Destroy()
    }

    ; --- MOVEMENT FUNCTIONS ---
    ; moves the user selection in the requested direction of the gui 
    ; basically just colors the background of a control to be considered selected
    ; skips controls that don't have a key & wraps around both axis

    ; check if the selected control is outside of the wndw & vertically scroll if it is
    checkScrollVertical(selectedControl) {
        y := 0
        h := 0
        
        ControlGetPos(, &y,, &h, selectedControl)
        y += this._guiY

        if (this.currentY = 1) {
            DllCall("ScrollWindow", "Ptr", this.guiObj.Hwnd, "Int", 0, "Int", (-1 * this._scrollVOffset), "Ptr", 0, "Ptr", 0)
            this._scrollVOffset := 0
        }
        else if (y < 0) {
            diff := -1 * (y - percentHeight(0.005))
            DllCall("ScrollWindow", "Ptr", this.guiObj.Hwnd, "Int", 0, "Int", diff, "Ptr", 0, "Ptr", 0)
            this._scrollVOffset += diff
        }
        else if ((y + h) > (this._guiY + this._guiH)) {
            diff := -1 * (Abs((y + h) - (this._guiY + this._guiH)) + percentHeight(0.005))
            DllCall("ScrollWindow", "Ptr", this.guiObj.Hwnd, "Int", 0, "Int", diff, "Ptr", 0, "Ptr", 0)
            this._scrollVOffset += diff
        }
    }

    ; check if the selected control is outside of the wndw & horizontally scroll if it is
    checkScrollHorizontal(selectedControl) {
        x := 0
        w := 0
        
        ControlGetPos(&x,, &w,, selectedControl)
        x += this._guiX

        if (this.currentX = 1) {
            DllCall("ScrollWindow", "Ptr", this.guiObj.Hwnd, "Int", (-1 * this._scrollHOffset), "Int", 0, "Ptr", 0, "Ptr", 0)
            this._scrollHOffset := 0
        }
        else if (x < 0) {
            diff := -1 * (x - percentWidth(0.005))
            DllCall("ScrollWindow", "Ptr", this.guiObj.Hwnd, "Int", diff, "Int", 0, "Ptr", 0, "Ptr", 0)
            this._scrollHOffset += diff
        }
        else if ((x + w) > (this._guiX + this._guiW)) {
            diff := -1 * (Abs((x + w) - (this._guiX + this._guiW)) + percentWidth(0.005))
            DllCall("ScrollWindow", "Ptr", this.guiObj.Hwnd, "Int", diff, "Int", 0, "Ptr", 0, "Ptr", 0)
            this._scrollHOffset += diff
        }
    }

    up() {  
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
        
        this.checkScrollVertical(this.guiObj[newControl])
    }
    
    down() {    
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
        
        this.checkScrollVertical(this.guiObj[newControl])
    }
    
    left() {    
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

        this.checkScrollHorizontal(this.guiObj[newControl])
    }
    
    right() {   
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

        this.checkScrollHorizontal(this.guiObj[newControl])
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

    setMonitorInfo()

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
        globalStatus["currGui"] := interfaceKey
        return
    }

    globalGuis[interfaceKey] := %interfaceObj["class"]%(args*)

    if (globalGuis[interfaceKey].guiObj != "") {
        globalGuis[interfaceKey].guiObj.Title := interfaceObj["wndw"]
        globalGuis[interfaceKey].Show()
    }

    if (setCurrent) {
        globalStatus["currGui"] := interfaceKey
    }

    if (customTime != "") {
        globalGuis[interfaceKey].time := customTime
    }

    return
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