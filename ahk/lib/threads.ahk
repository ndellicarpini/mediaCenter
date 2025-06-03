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

    ref := Worker(includeString . "
    (
        #Include lib\std.ahk
        #Include lib\input\hotkeys.ahk
        #Include lib\input\input.ahk
        #Include lib\input\devices.ahk

        prevDPIContext := DllCall("SetThreadDpiAwarenessContext", "Ptr", -3, "Ptr")
        CoordMode "Mouse", "Screen"
        Critical("Off")
        
        global exitThread := false

        global mainPID            := A_Args[1]
        global inputID            := A_Args[2]
        global globalConfig       := ObjFromPtr(A_Args[3])
        global globalStatus       := ObjFromPtr(A_Args[4])
        global globalInputStatus  := ObjFromPtr(A_Args[5])
        global globalInputConfigs := ObjFromPtr(A_Args[6])

        if (!globalInputStatus.Has(inputID) || !globalInputConfigs.Has(inputID)) {
            return
        }

        global thisInput   := []
        global thisHotkeys := Map()
        global thisMouse   := Map()

        global currConnected := []
        global currHotkeyInput := Map()
        global currMouseInput  := Map()
            
        global buttonTime := globalStatus["input"]["buttonTime"]

        ; ----- FUNCTIONS -----

        ; sends a key to the current program
        ;   key - key to send
        ;
        ; returns null
        ProgramSend(key, time := -1) {
            global globalStatus

            if (globalStatus["currProgram"]["exe"] = "") {
                return
            }

            WindowSend(key, "ahk_exe " globalStatus["currProgram"]["exe"], time, true)
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

            if (SubStr(hotkeyFunction, 1, 5) = "Send " && globalStatus["currProgram"]["id"] != ""
                && !globalStatus["currGui"] && !globalStatus["suspendScript"] && !globalStatus["desktopmode"]) {
                
                hotkeyFunction := StrReplace(hotkeyFunction, "Send ", "ProgramSend ",,, 1)
            }
            
            try {
                runFunction(hotkeyFunction)
            }
            catch {
                globalStatus["input"]["buffer"].Push(hotkeyFunction)
            }
        }

        ; removes a hotkey from the currHotkeyInput and sends up command
        ;  key - hotkey to remove
        ;  currIndex - port of controller to remove from
        ;
        ; returns null
        removeHotkey(key, currIndex) {
            global globalStatus
            global currHotkeyInput

            if (currHotkeyInput[currIndex][key]["sent"]) {
                ; clean up input buffer from hold/repeat spam
                if (currHotkeyInput[currIndex][key]["modifier"] = "[HOLD]" || currHotkeyInput[currIndex][key]["modifier"] = "[REPEAT]") {
                    toDelete := []
                    loop globalStatus["input"]["buffer"].Length {
                        try {
                            if (globalStatus["input"]["buffer"][A_Index] = currHotkeyInput[currIndex][key]["down"]) {
                                toDelete.Push(A_Index)
                            }
                        }
                    }
                    
                    if (toDelete.Length > 1) {
                        loop toDelete.Length {
                            try globalStatus["input"]["buffer"].RemoveAt(toDelete[A_Index] - (A_Index - 1))
                        }
                    }
                }
                
                ; send button release function
                if (!currHotkeyInput[currIndex][key]["blocked"]) {
                    sendHotkey(currHotkeyInput[currIndex][key]["up"])
                }
            }

            ; remove from currHotkeyInput if button no longer pressed
            currHotkeyInput[currIndex].Delete(key)
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
        inputInterval := 14
        maxConnected  := globalInputConfigs[inputID]["maxConnected"]

        inputInit   := %globalInputConfigs[inputID]["className"]%.initialize()
        ; intialize input type & devices
        loop maxConnected {
            thisInput.Push(%globalInputConfigs[inputID]["className"]%(inputInit, A_Index - 1, globalInputConfigs[inputID]))
            currConnected.Push(thisInput[A_Index].connected)
            
            updateGlobalStatus(A_Index)
            globalInputStatus[inputID][A_Index]["vibrating"] := false

            currHotkeyInput[A_Index] := Map()
            currMouseInput[A_Index] := Map(
                "lclick", 0,
                "rclick", 0,
                "mclick", 0,
                "hscroll", 0,
                "vscroll", 0)
        }

        SetTimer(DeviceStatusTimer, Round(globalConfig["General"]["AvgLoopSleep"] * 2.5))
        loopSleep := Round(globalConfig["General"]["AvgLoopSleep"])

        loop {
            ; close if main is no running
            if (!ProcessExist(mainPID)) {
                return
            }

            buttonTime := globalStatus["input"]["buttonTime"]

            if (globalStatus["input"]["hotkeys"].Has(inputID)) {
                try thisHotkeys := optimizeHotkeys(globalStatus["input"]["hotkeys"][inputID], buttonTime)
            }
            if (globalStatus["input"]["mouse"].Has(inputID)) {
                try thisMouse := globalStatus["input"]["mouse"][inputID]
            }

            loop maxConnected {
                currIndex := A_Index
                status := thisInput[currIndex].getStatus()     
                updateGlobalStatus(currIndex)

                ; check if the device is connected
                if (!thisInput[currIndex].connected) {
                    if (currConnected[currIndex]) {
                        currConnected[currIndex] := false
                    }

                    continue
                }

                ; initialize the device if newly connected
                if (!currConnected[currIndex]) {
                    thisInput[currIndex].initDevice()
                    currConnected[currIndex] := true
                }

                ; check all current status hotkeys
                for key, value in thisHotkeys {
                    ; check that button is pressed
                    hotkeyResult := checkHotkey(key, status, thisHotkeys, currHotkeyInput[currIndex])
                    hotkeyPressed := currHotkeyInput[currIndex].Has(key)

                    ; add hotkey to currently pressed list
                    if (!hotkeyPressed) {
                        ; if hotkey isn't perfect match -> ignore
                        if (hotkeyResult != "full") {
                            continue
                        }

                        ; initialize pressed button in currHotkeyInput list
                        currHotkeyInput[currIndex][key] := Map(
                            "modifier", value["modifier"],
                            "down", value["down"],
                            "up", value["up"],
                            "time", value["time"],
                            "startTime", A_TickCount,
                            "blocked", false,
                            "sent", false)

                        ; set custom PATTERN params
                        if (currHotkeyInput[currIndex][key]["modifier"] = "[PATTERN]") {
                            currHotkeyInput[currIndex][key]["patternPos"] := 1
                            currHotkeyInput[currIndex][key]["patternWait"] := true
                            currHotkeyInput[currIndex][key]["patternCount"] := StrSplit(key, ",").Length
                            currHotkeyInput[currIndex][key]["patternTime"] := currHotkeyInput[currIndex][key]["time"]
                            currHotkeyInput[currIndex][key]["time"] := 9999999
                        }
                        ; set custom REPEAT params
                        else if (currHotkeyInput[currIndex][key]["modifier"] = "[REPEAT]") {
                            currHotkeyInput[currIndex][key]["repeatTime"] := currHotkeyInput[currIndex][key]["time"]
                            currHotkeyInput[currIndex][key]["time"] := buttonTime
                        }
                    }
                    else {
                        ; perform custom pattern logic
                        if (currHotkeyInput[currIndex][key]["modifier"] = "[PATTERN]" 
                            && currHotkeyInput[currIndex][key]["startTime"] + currHotkeyInput[currIndex][key]["patternTime"] > A_TickCount) {

                            ; if user has released previous key, set patternWait to false
                            if (currHotkeyInput[currIndex][key]["patternWait"] && (hotkeyResult = "partial" || hotkeyResult = "")) {
                                currHotkeyInput[currIndex][key]["patternWait"] := false
                            }
                            ; update patternPos and set patternWait to true
                            else if (!currHotkeyInput[currIndex][key]["patternWait"] && hotkeyResult = "patternNext") {
                                currHotkeyInput[currIndex][key]["patternPos"] += 1
                                currHotkeyInput[currIndex][key]["patternWait"] := true

                                ; if pattern complete -> set time to 0 to immediately trigger
                                if (currHotkeyInput[currIndex][key]["patternPos"] >= currHotkeyInput[currIndex][key]["patternCount"]) {
                                    currHotkeyInput[currIndex][key]["time"] := 0
                                }
                            }

                            continue
                        }

                        ; hotkey released after being sent
                        if (hotkeyResult != "full") {
                            removeHotkey(key, currIndex)
                        }
                    }
                }

                ; check pressed hotkeys if any have been held long enough
                for key, value in currHotkeyInput[currIndex] {
                    ; hotkey is no longer supported by current state
                    if (!thisHotkeys.Has(key)) {
                        ; removeHotkey(key, currIndex)
                        continue
                    }

                    ; key hasn't been held long enough
                    if (value["startTime"] + value["time"] > A_TickCount) {
                        continue
                    }

                    toSend := "-1"
                    ; send repeat function
                    if (value["modifier"] = "[REPEAT]") {
                        ; set delay for 2nd send of the function
                        if (!value["sent"]) {
                            value["time"] := value["repeatTime"]
                        }
                        ; set delay for 3+ sends of the function
                        else {
                            value["time"] := 25
                        }

                        toSend := value["down"]
                        value["startTime"] := A_TickCount
                    }
                    ; send hold function
                    else if (value["modifier"] = "[HOLD]") {
                        ; set delay for all following function sends
                        value["time"] := 25

                        toSend := value["down"]
                        value["startTime"] := A_TickCount
                    }
                    else if (!value["sent"]) {
                        toSend := value["down"]
                    }
                    
                    if (toSend != "-1") {
                        ignoreInput := false
                        numAmpersand := StrSplit(key, "&").Length 
                        ; check if key combination using the hotkey is being pressed, and prioritize it
                        for key2, value2 in currHotkeyInput[currIndex] {
                            if (key != key2 && (InStr(key, "&") || InStr(key2, "&")) 
                                && (InStr(key, key2) || InStr(key2, key)) && value2["modifier"] != "[PATTERN]") {
                                
                                ; always block pausemenu from opening when using as "up"
                                if (StrLower(value2["up"]) = "pausemenu") {
                                    value2["blocked"] := true
                                    continue
                                }

                                numAmpersand2 := StrSplit(key2, "&").Length 
                                ; don't block inferior input if already sent & has down function (usually for {key up})
                                if (numAmpersand > numAmpersand2) {
                                    if (value2["down"] = "" || !value2["sent"]) {
                                        value2["blocked"] := true
                                    }
                                }
                                else if (value["down"] = "" || !value["sent"]) {
                                    value["blocked"] := true
                                }
                            }
                        }

                        ; run hotkey down function
                        if (!value["blocked"]) {
                            sendHotkey(toSend, value["modifier"] = "[HOLD]")
                            value["sent"] := true
                        }
                    }

                    ; go nuclear once exit key has been held for 5 seconds
                    if (A_TickCount - value["startTime"] > 4900 && StrLower(value["down"]) = "program.exit") {                            
                        value["startTime"] := A_TickCount

                        if (globalStatus["currProgram"]["exe"] != "") {
                            try ProcessKill(globalStatus["currProgram"]["exe"])
                        }
                        else {
                            winList := WinGetList()
                            loop winList.Length {
                                currPath := WinGetProcessPath(winList[A_Index])
                                currProcess := WinGetProcessName(winList[A_Index])
        
                                if (!WinActive(winList[A_Index]) || currProcess = "explorer.exe" || currPath = A_AhkPath) {
                                    continue
                                }
                                
                                try ProcessKill(WinGetPID(winList[A_Index]))
                                break
                            }
                        }
                    }
                }

                ; move mouse if program supports it
                if (thisMouse.Count > 0) {
                    deadzone := (thisMouse.Has("deadzone")) ? thisMouse["deadzone"] : 0.15
                    xvel    := 0
                    yvel    := 0
                    hscroll := 0
                    vscroll := 0

                    MouseGetPos(&xpos, &ypos)

                    monitorMult := 0

                    ; get width of monitor mouse is in to keep motion smooth between monitors
                    loop MonitorGetCount() {
                        MonitorGet(A_Index, &ML, &MT, &MR, &MB)

                        if (xpos >= ML && xpos <= MR && ypos >= MT && ypos <= MB) {
                            monitorW := Floor(Abs(MR - ML))
                            monitorH := FLoor(Abs(MB - MT))

                            monitorMult := (monitorW * (1.777778 / (monitorW / monitorH))) * 0.012
                            break
                        }
                    }

                    checkX := thisMouse.Has("x")
                    checkY := thisMouse.Has("y")
                    checkH := thisMouse.Has("hscroll")
                    checkV := thisMouse.Has("vscroll")

                    checkL := thisMouse.Has("lclick")
                    checkR := thisMouse.Has("rclick")
                    checkM := thisMouse.Has("mclick")

                    ; check mouse move x axis
                    if (checkX) {
                        currAxis := Integer(thisMouse["x"])
                        inverted := false

                        if (currAxis < 0) {
                            currAxis := Abs(currAxis)
                            inverted := true
                        }

                        axis := status["axis"][currAxis]
                        if (Abs(axis) > deadzone) {
                            xvel := (inverted) ? (xvel - axis) : (xvel + axis)
                        }                   
                    }
                    ; check mouse move y axis
                    if (checkY) {
                        currAxis := Integer(thisMouse["y"])
                        inverted := false

                        if (currAxis < 0) {
                            currAxis := Abs(currAxis)
                            inverted := true
                        }

                        axis := status["axis"][currAxis]
                        if (Abs(axis) > deadzone) {
                            yvel := (inverted) ? (yvel - axis) : (yvel + axis)
                        }
                    }

                    ; check mouse horizontal scroll axis
                    if (checkH) {
                        currAxis := Integer(thisMouse["hscroll"])
                        inverted := false

                        if (currAxis < 0) {
                            currAxis := Abs(currAxis)
                            inverted := true
                        }

                        axis := status["axis"][currAxis]
                        if (Abs(axis) > deadzone) {
                            hscroll := (inverted) ? (hscroll - axis) : (hscroll + axis)
                        }
                    }
                    ; check mouse vertical scroll axis
                    if (checkV) {
                        currAxis := Integer(thisMouse["vscroll"])
                        inverted := false

                        if (currAxis < 0) {
                            currAxis := Abs(currAxis)
                            inverted := true
                        }

                        axis := status["axis"][currAxis]
                        if (Abs(axis) > deadzone) {
                            vscroll := (inverted) ? (vscroll - axis) : (vscroll + axis)
                        }
                    }

                    ; check left click button
                    if (checkL) {
                        if (status["buttons"][Integer(thisMouse["lclick"])]) {
                            if (!(currMouseInput[currIndex]["lclick"] & (2 ** A_Index))) {
                                MouseClick("Left",,,,, "D")
                                currMouseInput[currIndex]["lclick"] := currMouseInput[currIndex]["lclick"] | (2 ** A_Index)
                            }
                        }
                        else {
                            if (currMouseInput[currIndex]["lclick"] & (2 ** A_Index)) {
                                MouseClick("Left",,,,, "U")
                                currMouseInput[currIndex]["lclick"] := currMouseInput[currIndex]["lclick"] ^ (2 ** A_Index)
                            }
                        }
                    }
                    ; check right click button
                    if (checkR) {
                        if (status["buttons"][Integer(thisMouse["rclick"])]) {
                            if (!(currMouseInput[currIndex]["rclick"] & (2 ** A_Index))) {
                                MouseClick("Right",,,,, "D")
                                currMouseInput[currIndex]["rclick"] := currMouseInput[currIndex]["rclick"] | (2 ** A_Index)
                            }
                        }
                        else {
                            if (currMouseInput[currIndex]["rclick"] & (2 ** A_Index)) {
                                MouseClick("Right",,,,, "U")
                                currMouseInput[currIndex]["rclick"] := currMouseInput[currIndex]["rclick"] ^ (2 ** A_Index)
                            }
                        }
                    }
                    ; check middle click button
                    if (checkM) {
                        if (status["buttons"][Integer(thisMouse["mclick"])]) {
                            if (!(currMouseInput[currIndex]["mclick"] & (2 ** A_Index))) {
                                MouseClick("Middle",,,,, "D")
                                currMouseInput[currIndex]["mclick"] := currMouseInput[currIndex]["mclick"] | (2 ** A_Index)
                            }
                        }
                        else {
                            if (currMouseInput[currIndex]["mclick"] & (2 ** A_Index)) {
                                MouseClick("Middle",,,,, "U")
                                currMouseInput[currIndex]["mclick"] := currMouseInput[currIndex]["mclick"] ^ (2 ** A_Index)
                            }
                        }
                    }

                    ; move the mouse
                    xvel := Round((adjustAxis(xvel, deadzone) * monitorMult))
                    yvel := Round((adjustAxis(yvel, deadzone) * monitorMult))

                    if (xvel != 0 || yvel != 0) {
                        MouseMove(xvel, yvel,, "R")
                    }
                    
                    ; only send scroll actions every x timer cycles
                    ; otherwise it will scroll way too fast
                    hscroll := Round(adjustAxis(hscroll, deadzone) * 3)
                    vscroll := Round(adjustAxis(vscroll, deadzone) * 3)
                    
                    if (Abs(currMouseInput[currIndex]["hscroll"] * hscroll) > 6) {
                        if (hscroll > 0) {
                            MouseClick("WheelRight")
                        }
                        else if (hscroll < 0) {
                            MouseClick("WheelLeft")
                        }
                        
                        currMouseInput[currIndex]["hscroll"] := 0
                    }
                    if (Abs(currMouseInput[currIndex]["vscroll"] * vscroll) > 6) {
                        if (vscroll > 0) {
                            MouseClick("WheelDown")
                        }
                        else if (vscroll < 0) {
                            MouseClick("WheelUp")
                        }

                        currMouseInput[currIndex]["vscroll"] := 0
                    }

                    currMouseInput[currIndex]["hscroll"] += 1
                    currMouseInput[currIndex]["vscroll"] += 1
                }
            }

            Sleep(inputInterval)
        }

        return

        ; ----- TIMERS -----
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
    , " " . mainPID . " " . inputID . " " . globalConfigPtr . " " . globalStatusPtr . " " . globalInputStatusPtr . " " . globalInputConfigsPtr . " "
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

    ref := Worker("
    (   
        #Include lib\std.ahk
        #Include lib\input\hotkeys.ahk
        #Include lib\input\input.ahk
        
        Critical("Off")

        ; --- GLOBAL VARIABLES ---

        ; variables are global to be accessed in timers
        global mainPID            := A_Args[1]
        global globalConfig       := ObjFromPtr(A_Args[2])
        global globalStatus       := ObjFromPtr(A_Args[3])
        global globalInputConfigs := ObjFromPtr(A_Args[4])
        global globalRunning      := ObjFromPtr(A_Args[5])

        ; initialize default hotkeys
        defaultHotkeys      := Map()
        defaultMouse        := Map()
        guiHotkeys          := Map()

        desktopmodeHotkeys  := Map()
        desktopmodeMouse    := Map()
        kbmmodeHotkeys      := Map()
        kbmmodeMouse        := Map()

        emptyHotkeys := Map()
        emptyMouse   := Map()

        ; set default hotkeys from input plugins
        for key, value in globalInputConfigs {
            emptyHotkeys[key] := Map()
            emptyMouse[key] := Map()

            ; add default program hotkeys
            if (value.Has("default")) {
                if (value["default"].Has("hotkeys")) {
                    defaultHotkeys[key] := value["default"]["hotkeys"]
                }
                if (value["default"].Has("mouse")) {
                    defaultMouse[key] := value["default"]["mouse"]
                }
            }

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

            ; add default & individual gui hotkeys
            if (value.Has("interfaceHotkeys") && value["interfaceHotkeys"].Has("default")) {
                guiHotkeys[key] := value["interfaceHotkeys"]["default"]
            }
        }

        loopSleep := Round(globalConfig["General"]["AvgLoopSleep"] / 2)

        loop {
            currSuspended   := globalStatus["suspendScript"]
            currDesktopMode := globalStatus["desktopmode"]
            currKBMMode     := globalStatus["kbmmode"]

            currProgram := globalStatus["currProgram"]["id"]
            currGui     := globalStatus["currGui"]

            currHotkeys := ObjDeepClone(defaultHotkeys)
            currMouse   := ObjDeepClone(emptyMouse)

            if (currGui != "") {
                currHotkeys := ObjDeepClone(guiHotkeys)

                for key, value in globalInputConfigs {
                    if (value.Has("interfaceHotkeys") && value["interfaceHotkeys"].Has(currGui)) {
                        currHotkeys[key] := addHotkeys(currHotkeys[key], value["interfaceHotkeys"][currGui])
                    }
                }

                globalStatus["input"]["buttonTime"] := 0
            }

            else if (currDesktopMode && !currSuspended) {
                currHotkeys := ObjDeepClone(desktopmodeHotkeys)
                currMouse   := ObjDeepClone(desktopmodeMouse)

                globalStatus["input"]["buttonTime"] := 0
            }

            else if (globalStatus["loadscreen"]["show"] && !currSuspended) {
                currHotkeys := ObjDeepClone(defaultHotkeys)

                if (globalStatus["kbmmode"]) {
                    for key, value in globalInputConfigs {
                        currHotkeys[key] := addHotkeys((currHotkeys.Has(key)) ? currHotkeys[key] : Map(), kbmmodeHotkeys[key])
                    }

                    currMouse := ObjDeepClone(kbmmodeMouse)

                    globalStatus["input"]["buttonTime"] := 0
                }
            }

            else if (currProgram != "" && globalRunning.Has(currProgram) && !currSuspended) {
                try {
                    currHotkeys := ObjDeepClone(defaultHotkeys)

                    if (globalStatus["kbmmode"]) {
                        for key, value in globalInputConfigs {
                            currHotkeys[key] := addHotkeys((currHotkeys.Has(key)) ? currHotkeys[key] : Map(), kbmmodeHotkeys[key])
                        }
    
                        currMouse := ObjDeepClone(kbmmodeMouse)
    
                        globalStatus["input"]["buttonTime"] := 0
                    }
                    else {
                        checkHotkeys := globalRunning[currProgram].hotkeys.Count > 0
                        checkMouse   := globalRunning[currProgram].mouse.Count > 0
                        for key, value in globalInputConfigs {
                            if (checkHotkeys) {
                                currHotkeys[key] := addHotkeys(currHotkeys[key], globalRunning[currProgram].hotkeys)
                                if (value.Has("defaultHotkeys") && value["defaultHotkeys"].Has(currProgram)) {
                                    currHotkeys[key] := addHotkeys(currHotkeys[key], value["defaultHotkeys"][currProgram])
                                }
    
                                globalStatus["input"]["buttonTime"] := Min(globalStatus["input"]["buttonTime"], globalRunning[currProgram].hotkeyButtonTime)
                            }
        
                            if (checkMouse) {
                                currMouse[key] := globalRunning[currProgram].mouse
                            }
                        }
                    }
                }
            }

            ; --- UPDATE HOTKEYS & MOUSE ---
            globalStatus["input"]["hotkeys"] := currHotkeys
            globalStatus["input"]["mouse"]   := currMouse

            Sleep(loopSleep)

            ; close if main is no running
            if (!ProcessExist(mainPID)) {
                return
            }
        }
    )"
    , " " . mainPID . " " . globalConfigPtr . " " . globalStatusPtr . " " . globalInputConfigsPtr . " " . globalRunningPtr
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
    
    ref := Worker(includeString . "
    (   
        #Include lib\std.ahk
        #Include lib\gui\std.ahk
        #Include lib\gui\constants.ahk
        #Include lib\gui\interface.ahk
        #Include lib\gui\interfaces\loadscreen.ahk

        ; #WinActivateForce
        
        Critical("Off")

        ; --- GLOBAL VARIABLES ---

        ; variables are global to be accessed in timers
        global mainPID      := A_Args[1]
        global globalConfig := ObjFromPtr(A_Args[2])
        global globalStatus := ObjFromPtr(A_Args[3])

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
                                HideMouseCursor()
                            }

                            ; create loadscreen if doesn't exist
                            if (!loadShown) {
                                globalGuis["loadscreen"].updateText(globalStatus["loadscreen"]["text"])      
                                globalGuis["loadscreen"].Show()

                                activateLoadScreen()
                                Sleep(100)
                            }

                            if (forceLoadScreen) {
                                currGui := globalStatus["currGui"]

                                ; activate overrideWNDW if it exists
                                if (globalStatus["loadscreen"]["overrideWNDW"] != "" && WinShown(globalStatus["loadscreen"]["overrideWNDW"])) {
                                    WinActivateForeground(globalStatus["loadscreen"]["overrideWNDW"])
                                }
                                ; activate loadscreen
                                else if (currGui = "" || !WinShown(INTERFACES[currGui]["wndw"])) {
                                    activateLoadScreen()
                                }
                            }
                        }
                        else {
                            ; if loadscreen active but not "showing" (aka forced on)
                            if (WinActive(INTERFACES["loadscreen"]["wndw"])) {
                                if (!globalGuis["loadscreen"].controlsVisible) {
                                    globalGuis["loadscreen"].restoreControls()
                                    HideMouseCursor()
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

            Sleep(loopSleep)

            ; close if main is no running
            if (!ProcessExist(mainPID)) {
                return
            }
        }
    )"
    , " " . mainPID . " " . globalConfigPtr . " " . globalStatusPtr
    , "miscThread")

    SetWorkingDir(restoreScriptDir)
    return ref
}