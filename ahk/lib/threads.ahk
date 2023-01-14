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
    tempConfig := globalConfig
    
    includeString := ""
    if (tempConfig["Plugins"].Has("InputPluginDir") && tempConfig["Plugins"]["InputPluginDir"] != "") {
        loop files (validateDir(tempConfig["Plugins"]["InputPluginDir"]) . "*.ahk"), "R" {
            includeString .= "#Include " . A_LoopFileShortPath . "`n"
        }
    }

    ref := ThreadObj(includeString . "
    (
        #Include lib\std.ahk
        #Include lib\hotkeys.ahk
        #Include lib\input.ahk

        SetKeyDelay 50, 50
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

            loop hotkeyTimers.Length {
                if (hotkeyTimers[A_Index] = index . button) {
                    hotkeyTimers.RemoveAt(A_Index)
                    break
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
                    time: time,
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

                if (inputCheckStatus(hotkeyList, status)) {
                    maxInvalidAmp := hotkeyList.Length
                }
            }

            checkArr := hotkeys.buttonTree[button]

            maxValidAmp := 0
            maxValidItem := ""
            for item in checkArr {
                if (item = "") {
                    continue
                }

                hotkeyList := StrSplit(item, ["&", "|"])

                if (inputCheckStatus(hotkeyList, status)) {
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

        loopSleep := Round(globalConfig["General"]["AvgLoopSleep"] / 4)

        ; intialize input type & devices
        inputInit := %globalInputConfigs[inputID]["className"]%.initialize()
        loop maxConnected {
            thisInput.Push(%globalInputConfigs[inputID]["className"]%(inputInit, A_Index - 1, globalInputConfigs[inputID]))
            
            updateGlobalStatus(A_Index)
            globalInputStatus[inputID][A_Index]["vibrating"] := false
        }

        SetTimer(DeviceStatusTimer, globalConfig["General"]["AvgLoopSleep"] * 2)

        loop {
            currStatus := globalStatus["currProgram"] . globalStatus["currGui"] . globalStatus["loadscreen"]["show"]

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

                    if (!inArray(currIndex . currButton, hotkeyTimers) && inputCheckStatus(currButton, status)) {                       
                        if (currButtonTime > 0) {
                            SetTimer(ButtonTimer.Bind(currButton, currButtonTime, currIndex, currStatus), (-1 * currButtonTime))
                        }
                        else {
                            ButtonTimer(currButton, currButtonTime, currIndex, currStatus)
                        }

                        hotkeyTimers.Push(currIndex . currButton)
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

            Sleep(loopSleep)
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
                removeTimer(index, button)
                return
            }

            hotkeyData := checkHotkeys(button, currHotkeys, inputStatus)

            if (hotkeyData = -1) {
                removeTimer(index, button)
                return
            }

            if (!((hotkeyData.function = "Exit" || InStr(hotkeyData.function, ".exit")) && globalStatus["pause"])) {
                if (hotkeyData.time != "" && (time - hotkeyData.time) > 0) {
                    SetTimer(ButtonTimer.Bind(button, hotkeyData.time, index, status), (-1 * (time - hotkeyData.time)))
                    return
                }

                sendHotkey(hotkeyData.function)
                SetTimer(WaitButtonTimer.Bind(button, index, hotkeyData, status, 0), -25)
            }
            else {
                removeTimer(index, button)
            }

            return
        }

        WaitButtonTimer(button, index, hotkeyData, status, loopCount) {
            Critical("On")
            
            global globalStatus
            global thisInput
            global hotkeyTimers
            global currStatus

            if (inputCheckStatus(button, thisInput[index].getStatus())) {
                if (status = currStatus) {
                    if (hotkeyData.function = "program.exit") {
                        ; the nuclear option
                        if (loopCount > 120) {
                            winList := WinGetList()
                            loop winList.Length {
                                currPath := WinGetProcessPath("ahk_id " winList[A_Index])
                                currProcess := WinGetProcessName("ahk_id " winList[A_Index])

                                if (currProcess = "explorer.exe" || currPath = A_AhkPath) {
                                    continue
                                }

                                try ProcessKill(WinGetPID("ahk_id " winList[A_Index]))
                                break
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
                    if (hotkeyData.modifier = "repeat") {
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
                    currAxis := currMouse["x"]
                    inverted := false

                    if (SubStr(currAxis, 1, 1) = "-") {
                        currAxis := SubStr(currAxis, 2)
                        inverted := true
                    }

                    if (currStatusData["axis"].Has(currAxis)) {
                        axis := currStatusData["axis"][currAxis]
                        if (Abs(axis) > deadzone) {
                            xvel := (inverted) ? (xvel - axis) : (xvel + axis)
                        }
                    }                    
                }
                ; check mouse move y axis
                if (checkY) {
                    currAxis := currMouse["y"]
                    inverted := false

                    if (SubStr(currAxis, 1, 1) = "-") {
                        currAxis := SubStr(currAxis, 2)
                        inverted := true
                    }

                    if (currStatusData["axis"].Has(currAxis)) {
                        axis := currStatusData["axis"][currAxis]
                        if (Abs(axis) > deadzone) {
                            yvel := (inverted) ? (yvel - axis) : (yvel + axis)
                        }
                    }
                }

                ; check mouse horizontal scroll axis
                if (checkH) {
                    currAxis := currMouse["hscroll"]
                    inverted := false

                    if (SubStr(currAxis, 1, 1) = "-") {
                        currAxis := SubStr(currAxis, 2)
                        inverted := true
                    }

                    if (currStatusData["axis"].Has(currAxis)) {
                        axis := currStatusData["axis"][currAxis]
                        if (Abs(axis) > deadzone) {
                            hscroll := (inverted) ? (hscroll - axis) : (hscroll + axis)
                        }
                    }
                }
                ; check mouse vertical scroll axis
                if (checkV) {
                    currAxis := currMouse["vscroll"]
                    inverted := false

                    if (SubStr(currAxis, 1, 1) = "-") {
                        currAxis := SubStr(currAxis, 2)
                        inverted := true
                    }

                    if (currStatusData["axis"].Has(currAxis)) {
                        axis := currStatusData["axis"][currAxis]
                        if (Abs(axis) > deadzone) {
                            vscroll := (inverted) ? (vscroll - axis) : (vscroll + axis)
                        }
                    }
                }

                ; check left click button
                if (checkL) {
                    if (inArray(currMouse["lclick"], currStatusData["buttons"])) {
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
                    if (inArray(currMouse["rclick"], currStatusData["buttons"])) {
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
                    if (inArray(currMouse["mclick"], currStatusData["buttons"])) {
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
        #Include lib\hotkeys.ahk
        
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
                    desktopmodeHotkeys := addHotkeys(desktopmodeHotkeys, Map(key, value["desktopmode"]["hotkeys"]))
                }
                if (value["desktopmode"].Has("mouse")) {
                    desktopmodeMouse[key] := value["desktopmode"]["mouse"]
                }
            }

            ; add kbmmode hotkeys
            if (value.Has("kbmmode")) {
                if (value["kbmmode"].Has("hotkeys")) {
                    kbmmodeHotkeys := addHotkeys(kbmmodeHotkeys, Map(key, value["kbmmode"]["hotkeys"]))
                }
                if (value["kbmmode"].Has("mouse")) {
                    kbmmodeMouse[key] := value["kbmmode"]["mouse"]
                }
            }

            ; add default program hotkeys
            if (value.Has("programHotkeys")) {
                programHotkeys := addHotkeys(programHotkeys, Map(key, value["programHotkeys"]))
            }

            ; add default interface hotkeys
            if (value.Has("interfaceHotkeys")) {
                guiHotkeys := addHotkeys(guiHotkeys, Map(key, value["interfaceHotkeys"]))
            }
        }

        loopSleep := Round(globalConfig["General"]["AvgLoopSleep"])

        loop {
            currSuspended := globalStatus["suspendScript"]
            hotkeySource  := globalStatus["input"]["source"]

            currProgram := globalStatus["currProgram"]
            currGui     := globalStatus["currGui"]

            currHotkeys := Map()
            currMouse   := Map()

            if (hotkeySource = "desktopmode") {
                globalStatus["input"]["buttonTime"] := 0

                currHotkeys := desktopmodeHotkeys
                currMouse   := desktopmodeMouse
            }

            else if (hotkeySource = currGui) {
                currHotkeys := guiHotkeys
                globalStatus["input"]["buttonTime"] := 0
            }

            else if (hotkeySource = "suspended") {
                currHotkeys := programHotkeys
            }

            else if (hotkeySource != "" && !currSuspended) {
                if (hotkeySource = "error") {
                    globalStatus["input"]["buttonTime"] := 0

                    currHotkeys := kbmmodeHotkeys
                    currMouse   := kbmmodeMouse
                }

                else if (hotkeySource = "kbmmode") {
                    globalStatus["input"]["buttonTime"] := 0

                    if (currProgram != "" && globalRunning.Has(currProgram)) {
                        currHotkeys := programHotkeys
                    }

                    currHotkeys := addHotkeys(currHotkeys, kbmmodeHotkeys)
                    currMouse   := kbmmodeMouse
                }

                else if (hotkeySource = currProgram && globalRunning.Has(currProgram)) {
                    currHotkeys := programHotkeys

                    if (globalRunning[currProgram].hotkeys.Count > 0) {
                        currHotkeys := addHotkeys(currHotkeys, globalRunning[currProgram].hotkeys)
                        globalStatus["input"]["buttonTime"] := globalRunning[currProgram].hotkeyButtonTime
                    }

                    if (globalRunning[currProgram].mouse.Count > 0) {
                        currMouse := globalRunning[currProgram].mouse
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

    ref := ThreadObj("
    (   
        #Include lib\std.ahk
        #Include lib\gui\std.ahk
        #Include lib\gui\constants.ahk
        #Include lib\gui\loadscreen.ahk
        
        Critical("Off")

        ; --- GLOBAL VARIABLES ---

        global exitThread := false

        ; variables are global to be accessed in timers
        global globalConfig := ObjFromPtr(A_Args[1])
        global globalStatus := ObjFromPtr(A_Args[2])

        ; set gui variables from config for loadscreen
        parseGUIConfig(globalConfig["GUI"])
        
        currLoadText   := globalStatus["loadscreen"]["text"]
        currLoadShow   := globalStatus["loadscreen"]["show"]
        currLoadEnable := globalStatus["loadscreen"]["enable"]

        allowLoadScreen := globalConfig["GUI"].Has("EnableLoadScreen") && globalConfig["GUI"]["EnableLoadScreen"]
        bypassFirewall  := globalConfig["General"].Has("BypassFirewallPrompt") && globalConfig["General"]["BypassFirewallPrompt"]
        hideTaskbar     := globalConfig["General"].Has("HideTaskbar") && globalConfig["General"]["HideTaskbar"]

        loopSleep := Round(globalConfig["General"]["AvgLoopSleep"] / 1.5)

        loop {
            if (!globalStatus["suspendScript"]) {
                ; check status of load screen & update if appropriate
                if (allowLoadScreen) {
                    loadShown := WinShown(INTERFACES["loadscreen"]["wndw"])

                    if (globalStatus["loadscreen"]["enable"]) {
                        ; if loadscreen is supposed to be active window
                        if (globalStatus["loadscreen"]["show"]) {
                            ; create loadscreen if doesn't exist
                            if (!loadShown) {
                                createLoadScreen()
                            }

                            ; activate overrideWNDW if it exists
                            if (globalStatus["loadscreen"]["overrideWNDW"] != "" 
                                && WinShown(globalStatus["loadscreen"]["overrideWNDW"])) {
                                
                                WinActivate(globalStatus["loadscreen"]["overrideWNDW"])
                            }
                            ; activate loadscreen
                            else {
                                activateLoadScreen()
                            }
    
                            currLoadShow := globalStatus["loadscreen"]["show"]
                        }
    
                        ; update loadscreen text if it has been changed
                        if (loadShown && currLoadText != globalStatus["loadscreen"]["text"]) {
                            loadGuiObj := getGUI(INTERFACES["loadscreen"]["wndw"])
                            
                            if (loadGuiObj) {
                                loadGuiObj["LoadText"].Text := globalStatus["loadscreen"]["text"]
                                loadGuiObj["LoadText"].Redraw()
        
                                currLoadText := globalStatus["loadscreen"]["text"]
                            }
                        }
    
                        currLoadEnable := true
                    }
                    else if (loadShown) {
                        destroyLoadScreen()
                        currLoadEnable := false
                    }
                }

                ; check that sound driver hasn't crashed
                if (SoundGetMute()) {
                    SoundSetMute(false)
                }
            
                ; automatically accept firewall
                if (bypassFirewall && WinShown("Windows Security Alert")) {
                    WinActivate("Windows Security Alert")
                    Sleep(50)
                    Send "{Enter}"
                }
            
                ; check that taskbar is hidden
                if (hideTaskbar && WinShown("ahk_class Shell_TrayWnd")) {
                    try WinHide("ahk_class Shell_TrayWnd")
                }
            }
            else {
                if (hideTaskbar && !WinShown("ahk_class Shell_TrayWnd")) {
                    try WinShow("ahk_class Shell_TrayWnd")
                }

                ; destroy load screen if it should not exist (desktopmode)
                if (allowLoadScreen && currLoadEnable && !globalStatus["loadscreen"]["enable"]) {
                    destroyLoadScreen()
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