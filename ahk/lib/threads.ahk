; creates a thread that checks the status of a specific input device type
;  inputID - the id of the input config/status to read/update
;  globalConfigPtr - ptr to globalConfig
;  globalStatusPtr - ptr to globalStatus
;  globalInputStatusPtr - ptr to globalInputStatus
;  globalInputConfigsPtr - ptr to globalInputConfigs
;
; returns ptr to the thread reference
inputThread(inputID, globalConfigPtr, globalStatusPtr, globalInputStatusPtr, globalInputConfigsPtr) {    
    restoreScriptDir := A_ScriptDir
    
    global globalConfig
    
    includeString := ""
    if (globalConfig["Plugins"].Has("InputPluginDir") && globalConfig["Plugins"]["InputPluginDir"] != "") {
        loop files (validateDir(globalConfig["Plugins"]["InputPluginDir"]) . "*.ahk"), "R" {
            includeString .= "#Include " . A_LoopFileShortPath . "`n"
        }
    }

    ref := ThreadObj(includeString . "
    (
        #Include lib\std.ahk
        #Include lib\input\hotkeys.ahk
        #Include lib\input\input.ahk

        ; SetKeyDelay 50, 50
        CoordMode "Mouse", "Screen"
        Critical("Off")

        global exitThread := false

        global inputID            := A_Args[1]
        global globalConfig       := ObjFromPtr(A_Args[2])
        global globalStatus       := ObjFromPtr(A_Args[3])
        global globalInputStatus  := ObjFromPtr(A_Args[4])
        global globalInputConfigs := ObjFromPtr(A_Args[5])

        if (!globalInputStatus.Has(inputID) || !globalInputConfigs.Has(inputID)) {
            ExitApp()
        }

        global thisInput   := []
        global thisHotkeys := Map()
        global thisMouse   := Map()
        
        global hotkeyTimers := []

        global buttonTime   := globalStatus["input"]["buttonTime"]
        global maxConnected := globalInputConfigs[inputID]["maxConnected"]

        global mouseStatus := Map("lclick", 0, "rclick", 0, "mclick", 0)
        global hscrollCount  := 0
        global vscrollCount  := 0

        global currHotkeys := ""
        global currStatus  := ""

        ; ----- FUNCTIONS -----

        ; sends a key to the current program
        ;   key - key to send
        ;
        ; returns null
        ProgramSend(key, time := -1) {
            global globalStatus

            if (globalStatus["currProgram"]["hwnd"] = 0) {
                return
            }

            WindowSend(key, globalStatus["currProgram"]["hwnd"], time, true)
        }

        ; updates the global input status
        ;  index - index of the input
        ;
        ; returns null
        updateGlobalStatus(index) {
            global inputID
            global globalInputStatus
            global thisInput
            
            for key, value in thisInput[index].OwnProps() {
                if (key = "vibrating") {
                    continue
                }

                globalInputStatus[inputID][index][key] := ObjDeepClone(value)
            }
        }

        ; removes timer id from running timers
        ;  index - index of input
        ;  button - unique button pressed
        ;
        ; returns null
        removeTimer(index, button) {
            global hotkeyTimers

            i := 1
            loop hotkeyTimers.Length {
                if (hotkeyTimers[i] = index . "-" . button) {
                    hotkeyTimers.RemoveAt(i)
                }
                else {
                    i += 1
                }
            }
        }

        ; check & find most specific hotkey that matches input state
        ;  button - button that was matched
        ;  hotkeys - currHotkeys as set by program
        ;  status - status result from input
        ; 
        ; returns array of button combo pressed & function from hotkeys based on input
        checkHotkeys(button, hotkeys, status) {
            ; creates the hotkeyData in the appropriate format
            createHotkeyData(hotkey) {
                down := ""
                up   := ""
                time := ""

                for key, value in hotkeys.hotkeys[hotkey] {
                    if (StrLower(key) = "down") {
                        down := value
                    }
                    else if (StrLower(key) = "up") {
                        up := value
                    }
                    else if (StrLower(key) = "time") {
                        time := value
                    }
                }

                return {
                    hotkey: StrSplit(hotkey, ["&", "|"]), 
                    modifier: hotkeys.modifiers[hotkey],
                    function: down,
                    release: up, 
                    time: time
                }
            }

            if (!hotkeys.buttonTree.Has(button)) {
                return -1
            }

            ; masking array of hotkeys from other branches in buttontree 
            ; used to check that current pressed key combo is actually a child
            ; of the buttontree[button]
            notCheckArr := []
            for key, value in hotkeys.buttonTree {
                if (key = button) {
                    continue
                }

                loop value.length {
                    currArr := StrSplit(value[A_Index], ["&", "|"])
                    if (inArray(button, currArr)) {
                        notCheckArr.Push(value[A_Index])
                    }
                }
            }

            maxInvalidAmp := 0
            for item in notCheckArr {
                if (item = "") {
                    continue
                }

                hotkeyList := StrSplit(item, ["&", "|"])

                if (inputCheckStatus(hotkeyList, status) && hotkeyList.Length > maxInvalidAmp) {
                    maxInvalidAmp := hotkeyList.Length
                }
            }

            maxValidAmp := 0
            maxValidItem := ""
            for item in hotkeys.buttonTree[button] {
                if (item = "") {
                    continue
                }

                hotkeyList := StrSplit(item, ["&", "|"])

                if (inputCheckStatus(hotkeyList, status) && hotkeyList.Length > maxValidAmp) {
                    maxValidAmp := hotkeyList.Length
                    maxValidItem := item
                }
            }

            ; if the button combo is from a different buttontree branch
            ; or if no valid button combos found
            if (maxInvalidAmp > maxValidAmp || maxValidAmp = 0) {
                return -1
            }

            return createHotkeyData(maxValidItem)
        }

        ; either adds a hotkey to the buffer or internalStatus
        ;  hotkeyFunction - function string to run
        ;  forceSend - whether or not to skip buffer
        ;
        ; returns null
        sendHotkey(hotkeyFunction, forceSend := false) {
            global globalStatus

            if (hotkeyFunction = "") {
                return
            }

            if (SubStr(hotkeyFunction, 1, 5) = "Send " && globalStatus["currProgram"]["id"] = globalStatus["input"]["source"]
                && !globalStatus["suspendScript"] && !globalStatus["desktopmode"]) {
                
                hotkeyFunction := StrReplace(hotkeyFunction, "Send ", "ProgramSend ",,, 1)
            }
            
            try {
                runFunction(hotkeyFunction)
            }
            catch {
                globalStatus["input"]["buffer"].Push(hotkeyFunction)
            }
        }

        ; adjusts an axis value to be 0-1.0 respecting deadzone
        ;  axisVal - value of axis
        ;  deadzone - size of deadzone
        ;
        ; returns adjusted value
        adjustAxis(axisVal, deadzone) {
            if (axisVal > 0) {
                return ((axisVal - deadzone) * (1 / (1 - deadzone)))
            }
            else if (axisVal < 0) {
                return ((axisVal + deadzone) * (1 / (1 - deadzone)))
            }
            else {
                return 0
            }
        }

        ; ----- MAIN -----

        mouseTimerRunning := false

        ; intialize input type & devices
        inputInit := %globalInputConfigs[inputID]["className"]%.initialize()
        loop maxConnected {
            thisInput.Push(%globalInputConfigs[inputID]["className"]%(inputInit, A_Index - 1, globalInputConfigs[inputID]))
            
            updateGlobalStatus(A_Index)
            globalInputStatus[inputID][A_Index]["vibrating"] := false
        }

        SetTimer(DeviceStatusTimer, Round(globalConfig["General"]["AvgLoopSleep"] * 2.5))

        loop {
            currStatus := globalStatus["currProgram"]["id"] . globalStatus["currGui"] . globalStatus["loadscreen"]["show"]

            thisHotkeys := (globalStatus["input"]["hotkeys"].Has(inputID))
                ? globalStatus["input"]["hotkeys"][inputID]
                : Map()

            thisMouse := (globalStatus["input"]["mouse"].Has(inputID))
                ? globalStatus["input"]["mouse"][inputID]
                : Map()

            ; enable/disable the mouse listener timer if the program uses the mouse
            if (thisMouse.Count > 0) {
                if (!mouseTimerRunning) {
                    SetTimer(MouseTimer, 15)
                    mouseTimerRunning := true
                }
            }
            else {
                if (mouseTimerRunning) {
                    hscrollCount := 0
                    vscrollCount := 0

                    SetTimer(MouseTimer, 0)
                    mouseTimerRunning := false
                }
            }
            
            currHotkeys := optimizeHotkeys(thisHotkeys)
            buttonTime  := globalStatus["input"]["buttonTime"]

            ; check each input device
            loop maxConnected {
                currIndex := A_Index

                status := thisInput[currIndex].getStatus()     
                updateGlobalStatus(currIndex)    

                if (!thisInput[currIndex].connected) {
                    continue
                }

                ; check if any of the unique keys from buttonTree are being pressed
                for key, value in currHotkeys.buttonTree {
                    currButton := key
                    currButtonTime := (currHotkeys.buttonTimes.Has(currButton)) ? currHotkeys.buttonTimes[currButton] : buttonTime

                    if (!inArray(currIndex . "-" . currButton, hotkeyTimers) && inputCheckStatus(currButton, status)) {                       
                        if (currButtonTime > 0) {
                            SetTimer(ButtonTimer.Bind(currButton, currButtonTime, currIndex, currStatus), Neg(currButtonTime))
                        }
                        else {
                            ButtonTimer(currButton, currButtonTime, currIndex, currStatus)
                        }

                        hotkeyTimers.Push(currIndex . "-" . currButton)
                    }
                }
            }

            ; close if main is no running
            if (!WinHidden(MAINNAME) || exitThread) {
                SetTimer(DeviceStatusTimer, 0)

                loop thisInput.Length {
                    thisInput[A_Index].destroyDevice()
                }

                %globalInputConfigs[inputID]["className"]%.destroy()

                ; clean object of any reference to this thread (allows ObjRelease in main)
                loop globalInputStatus[inputID].Length {
                    globalInputStatus[inputID][A_Index] := 0
                }
                
                ExitApp()
            }

            Sleep(16)
        }

        ; ----- TIMERS -----

        ButtonTimer(button, time, index, status) {   
            Critical("Off")

            global globalStatus     
            global thisInput

            global currHotkeys
            global buttonTime
            global hotkeyTimers

            inputStatus := thisInput[index].getStatus()

            if (!inputCheckStatus(button, inputStatus)) {
                SetTimer(WaitButtonTimer.Bind(button, index, -1, status, 0), -25)
                
                return
            }

            hotkeyData := checkHotkeys(button, currHotkeys, inputStatus)

            if (hotkeyData = -1) {
                SetTimer(WaitButtonTimer.Bind(button, index, -1, status, 0), -25)
                return
            }

            if (hotkeyData.time != "" && (time - hotkeyData.time) > 0) {
                SetTimer(ButtonTimer.Bind(button, hotkeyData.time, index, status), Neg(time - hotkeyData.time))
                return
            }

            sendHotkey(hotkeyData.function)

            SetTimer(WaitButtonTimer.Bind(button, index, hotkeyData, status, 0), -25)
            return
        }

        WaitButtonTimer(button, index, hotkeyData, status, loopCount) {
            Critical("On")
            
            global globalStatus
            global thisInput
            global currStatus

            if (hotkeyData = -1) {
                removeTimer(index, button)
                return
            }

            if (inputCheckStatus(button, thisInput[index].getStatus())) {
                if (status = currStatus) {
                    if (hotkeyData.function = "program.exit") {
                        ; the nuclear option
                        if (loopCount > 120) {
                            winList := WinGetList()
                            loop winList.Length {
                                currPath := WinGetProcessPath(winList[A_Index])
                                currProcess := WinGetProcessName(winList[A_Index])

                                if (!WinActive(winList[A_Index]) || currProcess = "explorer.exe" || currPath = A_AhkPath) {
                                    continue
                                }
                                
                                try ProcessKill(WinGetPID(winList[A_Index]))
                                try ProcessKill(WinGetPID(MAINNAME))

                                removeTimer(index, button)
                                return
                            }
                        }
                    }
                    else if (hotkeyData.modifier = "repeat") {
                        if (loopCount > 12) {
                            sendHotkey(hotkeyData.function)
                        }
                    }
                    else if (hotkeyData.modifier = "hold") {
                        sendHotkey(hotkeyData.function, true)
                    }
                }

                SetTimer(WaitButtonTimer.Bind(button, index, hotkeyData, status, loopCount + 1), -25)
            }
            else {
                if (status = currStatus) {
                    if (hotkeyData.modifier = "repeat" || hotkeyData.modifier = "hold") {
                        toDelete := []
                        loop globalStatus["input"]["buffer"].Length {
                            if (globalStatus["input"]["buffer"][A_Index] = hotkeyData.function) {
                                toDelete.Push(A_Index)
                            }
                        }
                        
                        if (toDelete.Length > 1) {
                            loop toDelete.Length {
                                globalStatus["input"]["buffer"].RemoveAt(toDelete[A_Index] - (A_Index - 1))
                            }
                        }
                    }
    
                    ; trigger release function if it exists
                    sendHotkey(hotkeyData.release)
                }

                removeTimer(index, button)
            }

            return
        }

        MouseTimer() {
            global thisInput
            
            global mouseStatus
            global hscrollCount
            global vscrollCount

            currMouse := thisMouse
            deadzone := (currMouse.Has("deadzone")) ? currMouse["deadzone"] : 0.15
            
            xvel    := 0
            yvel    := 0
            hscroll := 0
            vscroll := 0

            MouseGetPos(&xpos, &ypos)

            monitorW := 0

            ; get width of monitor mouse is in to keep motion smooth between monitors
            loop MonitorGetCount() {
                MonitorGet(A_Index, &ML, &MT, &MR, &MB)

                if (xpos >= ML && xpos <= MR && ypos >= MT && ypos <= MB) {
                    monitorW := Floor(Abs(MR - ML))
                    break
                }
            }

            checkX := currMouse.Has("x")
            checkY := currMouse.Has("y")
            checkH := currMouse.Has("hscroll")
            checkV := currMouse.Has("vscroll")

            checkL := currMouse.Has("lclick")
            checkR := currMouse.Has("rclick")
            checkM := currMouse.Has("mclick")

            loop maxConnected {
                currStatusData := thisInput[A_Index].getStatus()
                if (!thisInput[A_Index].connected) {
                    continue
                }

                ; check mouse move x axis
                if (checkX) {
                    currAxis := Integer(currMouse["x"])
                    inverted := false

                    if (currAxis < 0) {
                        currAxis := Abs(currAxis)
                        inverted := true
                    }

                    axis := currStatusData["axis"][currAxis]
                    if (Abs(axis) > deadzone) {
                        xvel := (inverted) ? (xvel - axis) : (xvel + axis)
                    }                   
                }
                ; check mouse move y axis
                if (checkY) {
                    currAxis := Integer(currMouse["y"])
                    inverted := false

                    if (currAxis < 0) {
                        currAxis := Abs(currAxis)
                        inverted := true
                    }

                    axis := currStatusData["axis"][currAxis]
                    if (Abs(axis) > deadzone) {
                        yvel := (inverted) ? (yvel - axis) : (yvel + axis)
                    }
                }

                ; check mouse horizontal scroll axis
                if (checkH) {
                    currAxis := Integer(currMouse["hscroll"])
                    inverted := false

                    if (currAxis < 0) {
                        currAxis := Abs(currAxis)
                        inverted := true
                    }

                    axis := currStatusData["axis"][currAxis]
                    if (Abs(axis) > deadzone) {
                        hscroll := (inverted) ? (hscroll - axis) : (hscroll + axis)
                    }
                }
                ; check mouse vertical scroll axis
                if (checkV) {
                    currAxis := Integer(currMouse["vscroll"])
                    inverted := false

                    if (currAxis < 0) {
                        currAxis := Abs(currAxis)
                        inverted := true
                    }

                    axis := currStatusData["axis"][currAxis]
                    if (Abs(axis) > deadzone) {
                        vscroll := (inverted) ? (vscroll - axis) : (vscroll + axis)
                    }
                }

                ; check left click button
                if (checkL) {
                    if (currStatusData["buttons"][Integer(currMouse["lclick"])]) {
                        if (!(mouseStatus["lclick"] & (2 ** A_Index))) {
                            MouseClick("Left",,,,, "D")
                            mouseStatus["lclick"] := mouseStatus["lclick"] | (2 ** A_Index)
                        }
                    }
                    else {
                        if (mouseStatus["lclick"] & (2 ** A_Index)) {
                            MouseClick("Left",,,,, "U")
                            mouseStatus["lclick"] := mouseStatus["lclick"] ^ (2 ** A_Index)
                        }
                    }
                }
                ; check right click button
                if (checkR) {
                    if (currStatusData["buttons"][Integer(currMouse["rclick"])]) {
                        if (!(mouseStatus["rclick"] & (2 ** A_Index))) {
                            MouseClick("Right",,,,, "D")
                            mouseStatus["rclick"] := mouseStatus["rclick"] | (2 ** A_Index)
                        }
                    }
                    else {
                        if (mouseStatus["rclick"] & (2 ** A_Index)) {
                            MouseClick("Right",,,,, "U")
                            mouseStatus["rclick"] := mouseStatus["rclick"] ^ (2 ** A_Index)
                        }
                    }
                }
                ; check middle click button
                if (checkM) {
                    if (currStatusData["buttons"][Integer(currMouse["mclick"])]) {
                        if (!(mouseStatus["mclick"] & (2 ** A_Index))) {
                            MouseClick("Middle",,,,, "D")
                            mouseStatus["mclick"] := mouseStatus["mclick"] | (2 ** A_Index)
                        }
                    }
                    else {
                        if (mouseStatus["mclick"] & (2 ** A_Index)) {
                            MouseClick("Middle",,,,, "U")
                            mouseStatus["mclick"] := mouseStatus["mclick"] ^ (2 ** A_Index)
                        }
                    }
                }
            }

            ; move the mou
            xvel := Round((adjustAxis(xvel, deadzone) * (0.015 * monitorW)))
            yvel := Round((adjustAxis(yvel, deadzone) * (0.015 * monitorW)))

            if (xvel != 0 || yvel != 0) {
                MouseMove(xvel, yvel,, "R")
            }
            
            ; only send scroll actions every x timer cycles
            ; otherwise it will scroll way too fast
            hscroll := Round(adjustAxis(hscroll, deadzone) * 3)
            vscroll := Round(adjustAxis(vscroll, deadzone) * 3)
            
            if (Abs(hscrollCount * hscroll) > 6) {
                if (hscroll > 0) {
                    MouseClick("WheelRight")
                }
                else if (hscroll < 0) {
                    MouseClick("WheelLeft")
                }
                
                hscrollCount := 0
            }
            if (Abs(vscrollCount * vscroll) > 6) {
                if (vscroll > 0) {
                    MouseClick("WheelDown")
                }
                else if (vscroll < 0) {
                    MouseClick("WheelUp")
                }

                vscrollCount := 0
            }

            hscrollCount += 1
            vscrollCount += 1

            return
        }

        DeviceStatusTimer() {
            global inputID
            global globalInputConfigs
            global globalInputStatus
            global thisInput

            loop globalInputConfigs[inputID]["maxConnected"] {
                globalVibe := globalInputStatus[inputID][A_Index]["vibrating"]
                if (globalVibe != thisInput[A_Index].vibrating) {
                    if (globalVibe) {
                        thisInput[A_Index].startVibration()
                    }
                    else {
                        thisInput[A_Index].stopVibration()
                    }

                    thisInput[A_Index].vibrating := globalVibe
                }

                thisInput[A_Index].checkConnectionType()
                thisInput[A_Index].checkBatteryLevel()

                updateGlobalStatus(A_Index)
            }

            return
        }
    )"
    , inputID . " " . globalConfigPtr . " " . globalStatusPtr . " " . globalInputStatusPtr . " " . globalInputConfigsPtr
    , "inputThread")

    SetWorkingDir(restoreScriptDir)
    return ref
}

; creates a thread that checks the current status of main & updates the globalStatus hotkeys appropriately
;  globalConfigPtr - ptr to globalConfig
;  globalStatusPtr - ptr to globalStatus
;  globalInputConfigsPtr - ptr to globalInputConfigs
;  globalRunningPtr - ptr to globalRunning
;
; returns ptr to the thread reference
hotkeyThread(globalConfigPtr, globalStatusPtr, globalInputConfigsPtr, globalRunningPtr) {
    restoreScriptDir := A_ScriptDir

    ref := ThreadObj("
    (   
        #Include lib\std.ahk
        #Include lib\input\hotkeys.ahk
        
        Critical("Off")

        ; --- GLOBAL VARIABLES ---

        global exitThread := false

        ; variables are global to be accessed in timers
        global globalConfig       := ObjFromPtr(A_Args[1])
        global globalStatus       := ObjFromPtr(A_Args[2])
        global globalInputConfigs := ObjFromPtr(A_Args[3])
        global globalRunning      := ObjFromPtr(A_Args[4])

        ; initialize default hotkeys
        desktopmodeHotkeys  := Map()
        desktopmodeMouse    := Map()
        kbmmodeHotkeys      := Map()
        kbmmodeMouse        := Map()

        programHotkeys      := Map()
        guiHotkeys          := Map()

        ; set default hotkeys from input plugins
        for key, value in globalInputConfigs {
            ; add desktopmode hotkeys
            if (value.Has("desktopmode")) {
                if (value["desktopmode"].Has("hotkeys")) {
                    desktopmodeHotkeys[key] := value["desktopmode"]["hotkeys"]
                }
                if (value["desktopmode"].Has("mouse")) {
                    desktopmodeMouse[key] := value["desktopmode"]["mouse"]
                }
            }

            ; add kbmmode hotkeys
            if (value.Has("kbmmode")) {
                if (value["kbmmode"].Has("hotkeys")) {
                    kbmmodeHotkeys[key] := value["kbmmode"]["hotkeys"]
                }
                if (value["kbmmode"].Has("mouse")) {
                    kbmmodeMouse[key] := value["kbmmode"]["mouse"]
                }
            }

            ; add default program hotkeys
            if (value.Has("programHotkeys") && value["programHotkeys"].Has("default")) {
                programHotkeys[key] := value["programHotkeys"]["default"]
            }

            ; add default & individual gui hotkeys
            if (value.Has("interfaceHotkeys") && value["interfaceHotkeys"].Has("default")) {
                guiHotkeys[key] := value["interfaceHotkeys"]["default"]
            }
        }

        loopSleep := Round(globalConfig["General"]["AvgLoopSleep"] / 2)

        loop {
            currSuspended := globalStatus["suspendScript"] || globalStatus["desktopmode"]
            hotkeySource  := globalStatus["input"]["source"]

            currProgram := globalStatus["currProgram"]["id"]
            currGui     := globalStatus["currGui"]

            currHotkeys := Map()
            currMouse   := Map()

            if (hotkeySource = currGui) {
                currHotkeys := ObjDeepClone(guiHotkeys)

                for key, value in globalInputConfigs {
                    if (value.Has("interfaceHotkeys") && value["interfaceHotkeys"].Has(currGui)) {
                        currHotkeys[key] := addHotkeys(currHotkeys[key], value["interfaceHotkeys"][currGui])
                    }
                }

                globalStatus["input"]["buttonTime"] := 0
            }

            else if (hotkeySource = "suspended") {
                currHotkeys := ObjDeepClone(programHotkeys)
            }

            else if (hotkeySource = "desktopmode") {
                currHotkeys := ObjDeepClone(desktopmodeHotkeys)
                currMouse   := ObjDeepClone(desktopmodeMouse)

                globalStatus["input"]["buttonTime"] := 0
            }

            else if (hotkeySource != "" && !currSuspended) {
                if (hotkeySource = "error") {
                    currHotkeys := ObjDeepClone(kbmmodeHotkeys)
                    currMouse   := ObjDeepClone(kbmmodeMouse)

                    globalStatus["input"]["buttonTime"] := 0
                }

                else if (hotkeySource = "kbmmode") {
                    if (currProgram != "" && globalRunning.Has(currProgram)) {
                        currHotkeys := ObjDeepClone(programHotkeys)
                    }

                    for key, value in globalInputConfigs {
                        currHotkeys[key] := addHotkeys((currHotkeys.Has(key)) ? currHotkeys[key] : Map(), kbmmodeHotkeys[key])
                    }

                    currMouse := ObjDeepClone(kbmmodeMouse)

                    globalStatus["input"]["buttonTime"] := 0
                }

                else if (hotkeySource = currProgram && globalRunning.Has(currProgram)) {
                    currHotkeys := ObjDeepClone(programHotkeys)

                    checkHotkeys := globalRunning[currProgram].hotkeys.Count > 0
                    checkMouse   := globalRunning[currProgram].mouse.Count > 0
                    for key, value in globalInputConfigs {
                        if (checkHotkeys) {
                            currHotkeys[key] := addHotkeys(currHotkeys[key], globalRunning[currProgram].hotkeys)
                            if (value.Has("programHotkeys") && value["programHotkeys"].Has(currProgram)) {
                                currHotkeys[key] := addHotkeys(currHotkeys[key], value["programHotkeys"][currProgram])
                            }

                            globalStatus["input"]["buttonTime"] := Min(globalStatus["input"]["buttonTime"], globalRunning[currProgram].hotkeyButtonTime)
                        }
    
                        if (checkMouse) {
                            currMouse[key] := globalRunning[currProgram].mouse
                        }
                    }
                }
            }

            ; close if main is no running
            if (!WinHidden(MAINNAME) || exitThread) {
                ; clean object of any reference to this thread (allows ObjRelease in main)
                for key, value in globalStatus["input"] {
                    globalStatus["input"][key] := 0
                }

                ExitApp()
            }

            ; --- UPDATE HOTKEYS & MOUSE ---
            globalStatus["input"]["hotkeys"] := currHotkeys
            globalStatus["input"]["mouse"]   := currMouse

            Sleep(loopSleep)
        }
    )"
    , globalConfigPtr . " " . globalStatusPtr . " " . globalInputConfigsPtr . " " . globalRunningPtr
    , "hotkeyThread")

    SetWorkingDir(restoreScriptDir)
    return ref
}

; creates a thread that interfaces with miscellaneous features
;  globalConfigPtr - ptr to globalConfig
;  globalStatusPtr - ptr to globalStatus
;
; returns ptr to the thread reference
miscThread(globalConfigPtr, globalStatusPtr) {
    restoreScriptDir := A_ScriptDir

    global globalConfig

    includeString := ""
    if (globalConfig.Has("Overrides") && globalConfig["Overrides"].Has("loadscreen")) {
        loadscreenClass := globalConfig["Overrides"]["loadscreen"]
        
        if (loadscreenClass != "" && globalConfig["Plugins"].Has("AHKPluginDir") && globalConfig["Plugins"]["AHKPluginDir"] != "") {
            loop files (validateDir(globalConfig["Plugins"]["AHKPluginDir"]) . "*.ahk"), "R" {
                contents := fileOrString(A_LoopFileFullPath)

                if (RegExMatch(contents, "U) *class *" . regexClean(loadscreenClass))) {
                    includeString .= "#Include " . A_LoopFileShortPath . "`n"
                }
            }
        }
    }
    
    ref := ThreadObj(includeString . "
    (   
        #Include lib\std.ahk
        #Include lib\gui\std.ahk
        #Include lib\gui\constants.ahk
        #Include lib\gui\interface.ahk
        #Include lib\gui\interfaces\loadscreen.ahk

        ; #WinActivateForce
        
        Critical("Off")

        ; --- GLOBAL VARIABLES ---

        global exitThread := false

        ; variables are global to be accessed in timers
        global globalConfig := ObjFromPtr(A_Args[1])
        global globalStatus := ObjFromPtr(A_Args[2])

        ; fake globalRunning & globalGuis for loadscreen
        global globalRunning := Map()
        global globalGuis    := Map()

        ; set gui variables from config for loadscreen
        setGUIConstants()
        
        currLoadText   := globalStatus["loadscreen"]["text"]
        currLoadShow   := globalStatus["loadscreen"]["show"]
        currLoadEnable := globalStatus["loadscreen"]["enable"]

        allowLoadScreen := globalConfig["GUI"].Has("EnableLoadScreen") && globalConfig["GUI"]["EnableLoadScreen"]
        forceLoadScreen := globalConfig["General"].Has("ForceActivateWindow") && globalConfig["General"]["ForceActivateWindow"]
        bypassFirewall  := globalConfig["General"].Has("BypassFirewallPrompt") && globalConfig["General"]["BypassFirewallPrompt"]
        disableTaskbar  := globalConfig["General"].Has("HideTaskbar") && globalConfig["General"]["HideTaskbar"]

        createInterface("loadscreen", false,, globalStatus["loadscreen"]["text"])

        loopSleep := Round(globalConfig["General"]["AvgLoopSleep"] / 1.5)

        loop {
            if (!globalStatus["suspendScript"] && !globalStatus["desktopmode"]) {
                ; check status of load screen & update if appropriate
                if (allowLoadScreen) {
                    loadShown := WinShown(INTERFACES["loadscreen"]["wndw"])

                    if (globalStatus["loadscreen"]["enable"]) {
                        ; if loadscreen is supposed to be active window
                        if (globalStatus["loadscreen"]["show"]) {
                            if (!globalGuis["loadscreen"].controlsVisible) {
                                globalGuis["loadscreen"].restoreControls()
                                MouseMove(percentWidth(1), percentHeight(1))
                            }

                            ; create loadscreen if doesn't exist
                            if (!loadShown) {
                                globalGuis["loadscreen"].updateText(globalStatus["loadscreen"]["text"])      
                                globalGuis["loadscreen"].Show()
                            }

                            if (forceLoadScreen) {
                                ; activate overrideWNDW if it exists
                                if (globalStatus["loadscreen"]["overrideWNDW"] != "" && WinShown(globalStatus["loadscreen"]["overrideWNDW"])) {
                                    WinActivateForeground(globalStatus["loadscreen"]["overrideWNDW"])
                                }
                                ; activate message if it exists
                                else if (WinShown(INTERFACES["message"]["wndw"])) {
                                    WinActivateForeground(INTERFACES["message"]["wndw"])
                                }
                                ; activate loadscreen
                                else {
                                    activateLoadScreen()
                                }
                            }
                        }
                        else {
                            ; if loadscreen active but not "showing" (aka forced on)
                            if (WinActive(INTERFACES["loadscreen"]["wndw"])) {
                                if (!globalGuis["loadscreen"].controlsVisible) {
                                    globalGuis["loadscreen"].restoreControls()
                                    MouseMove(percentWidth(1), percentHeight(1))
                                }
                            }
                            else if (globalGuis["loadscreen"].controlsVisible) {
                                globalGuis["loadscreen"].hideControls()
                            }
                        }
    
                        ; update loadscreen text if it has been changed
                        if (loadShown && currLoadText != globalStatus["loadscreen"]["text"]) {                            
                            if (globalGuis.Has("loadscreen")) {
                                globalGuis["loadscreen"].updateText(globalStatus["loadscreen"]["text"])       
                                currLoadText := globalStatus["loadscreen"]["text"]
                            }
                        }
    
                        currLoadEnable := true
                        currLoadShow := globalStatus["loadscreen"]["show"]
                    }
                    else if (loadShown) {
                        hideLoadScreen()
                        currLoadEnable := false
                    }
                }

                ; check that sound driver hasn't crashed
                if (SoundGetMute()) {
                    SoundSetMute(false)
                }
            
                ; automatically accept firewall
                if (bypassFirewall && WinShown("Windows Security Alert")) {
                    WinActivateForeground("Windows Security Alert")
                    Sleep(50)
                    Send "{Enter}"
                }
            
                ; check that taskbar is hidden
                if (disableTaskbar && taskbarExists()) {
                    hideTaskbar()
                }
            }
            else {
                if (disableTaskbar && !taskbarExists()) {
                    showTaskbar()
                }

                ; destroy load screen if it should not exist (desktopmode)
                if (allowLoadScreen && currLoadEnable && !globalStatus["loadscreen"]["enable"]) {
                    hideLoadScreen()
                    currLoadEnable := false
                }
            }

            ; close if main is no running
            if (!WinHidden(MAINNAME) || exitThread) {
                ExitApp()
            }

            Sleep(loopSleep)
        }
    )"
    , globalConfigPtr . " " . globalStatusPtr
    , "miscThread")

    SetWorkingDir(restoreScriptDir)
    return ref
}