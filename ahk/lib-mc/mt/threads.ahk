; creates the controller thread to check the input status of each connected controller
;  globalControllers - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that checks controller statuses
controllerThread(globalConfig, globalControllers, xLibrary) {
    ref := ThreadObj(
    (
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\xinput.ahk

        global exitThread := false
        
        global globalConfig      := ObjShare(" globalConfig ")
        global globalControllers := " globalControllers "
        xLibrary := " xLibrary "

        xGetStatusPtr := 0
        xGetBatteryPtr := 0
        xSetVibrationPtr := 0
        
        if (xLibrary != 0) {
            xGetStatusPtr := DllCall('GetProcAddress', 'UInt', xLibrary, 'UInt', 100)
            xGetBatteryPtr := DllCall('GetProcAddress', 'UInt', xLibrary, 'AStr', 'XInputGetBatteryInformation')
            xSetVibrationPtr := DllCall('GetProcAddress', 'UInt', xLibrary, 'AStr', 'XInputSetState')
        }
        else {
            ErrorMsg('Failed to initialize xinput', true)
        }

        maxControllers := globalConfig['General']['MaxXInputControllers']
        loopSleep := Round(globalConfig['General']['AvgLoopSleep'] / 5)

        currVibration := []
        loop maxControllers {
            currVibration.Push(0)
        }

        delayCount := -1
        maxDelayCount := 250

        loop {
            ; --- CONTROLLER BUFFER ---
            ; UChar - connected status (0/1)
            ; UChar - battery type (0/1/2/3/FF)
            ; UChar - battery status (0/1/2/3)
            ; UChar - vibration status (0/1)
            ; 16bytes - controller status data

            loop maxControllers {
                port := A_Index - 1

                ; gets connected & button status of controller
                controllerStatus := xGetStatus(port, xGetStatusPtr)

                ; controller not connected
                if (controllerStatus = -1) {
                    copyBufferData(Buffer(20, 0).Ptr, globalControllers + (port * 20), 20)

                    continue
                }

                ; copy connected status to buffer
                NumPut('UChar', 1, globalControllers + (port * 20), 0)

                ; gets vibration setting & activates/deactivates if needed
                newVibration := NumGet(globalControllers + (port * 20) + 3, 0, 'UChar')
                if (currVibration[A_Index] != newVibration) {
                    currVibration[A_Index] := xSetVibration(port, xSetVibrationPtr, newVibration)
                }

                ; copy button status to buffer
                copyBufferData(controllerStatus.Ptr, globalControllers + (port * 20) + 4, 16)

                if (delayCount = -1 || delayCount > maxDelayCount) {
                    ; copy battery type & level to buffer
                    batteryStatus := xGetBattery(port, xGetBatteryPtr)
                    copyBufferData(batteryStatus.Ptr, globalControllers + (port * 20) + 1, 2)
                    
                    delayCount := 0
                }

                delayCount += 1
            }

            ; close if main is no running
            if (!WinHidden(MAINNAME) || exitThread) {
                ExitApp()
            }

            Sleep(loopSleep)
        }
        "
    ),, "controllerThread")

    global MAINSCRIPTDIR
    SetWorkingDir(MAINSCRIPTDIR)

    return ref
}

; creates the thread that does actions based on current mainStatus & mainControllers
;  globalConfig - mainConfig as gotten as a ComObject through ObjShare
;  globalStatus - mainStatus as gotten as a ComObject through ObjShare 
;  globalControllers - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that does x based on mainStatus
hotkeyThread(globalConfig, globalStatus, globalControllers) {
    ref := ThreadObj(
    (
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\xinput.ahk
        #Include lib-mc\hotkeys.ahk

        #Include lib-mc\mt\status.ahk

        #Include lib-mc\gui\constants.ahk

        SetKeyDelay 50, 100
        CoordMode 'Mouse', 'Screen'
        Critical 'Off'

        ; --- GLOBAL VARIABLES ---

        global exitThread := false

        ; variables are global to be accessed in timers
        global globalConfig      := ObjShare(" globalConfig ")
        global globalStatus      := " globalStatus "
        global globalControllers := " globalControllers "

        global currHotkeys := optimizeHotkeys(getStatusParam('currHotkeys'))
        global buttonTime  := getStatusParam('buttonTime')

        global hotkeyBuffer := []
        global hotkeyTimers := []

        global mouseStatus := Map('lclick', 0, 'rclick', 0, 'mclick', 0)
        global hscrollCount  := 0
        global vscrollCount  := 0

        global currStatus := ''

        ; --- FUNCTIONS ---

        ; removes timer id from running timers
        ;  port - port of controller
        ;  button - unique button pressed
        ;
        ; returns null
        removeTimer(port, button) {
            global hotkeyTimers

            loop hotkeyTimers.Length {
                if (hotkeyTimers[A_Index] = port . button) {
                    hotkeyTimers.RemoveAt(A_Index)
                    break
                }
            }
        }

        ; trys to run the hotkey internally, if fails sends to main
        ;  hotkeyFunction - function string to run
        ;
        ; returns null
        runHotkey(hotkeyFunction) {
            try {
                runFunction(hotkeyFunction)
            }
            catch {
                setStatusParam('internalMessage', hotkeyFunction)
            }
        }

        ; either adds a hotkey to the buffer or internalStatus
        ;  hotkeyFunction - function string to run
        ;  forceSend - whether or not to skip buffer
        ;
        ; returns null
        sendHotkey(hotkeyFunction, forceSend := false) {
            global hotkeyBuffer

            if (hotkeyFunction = '') {
                return
            }

            if (forceSend) {
                runHotkey(hotkeyFunction)
                return
            }

            ; check if can just send input or need to buffer
            if (getStatusParam('internalMessage') != '' && !getStatusParam('loadShow')) {
                hotkeyBuffer.Push(hotkeyFunction)
            }
            else {
                runHotkey(hotkeyFunction)
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

        mouseTimerRunning := false

        maxControllers := globalConfig['General']['MaxXInputControllers']
        loopSleep := Round(globalConfig['General']['AvgLoopSleep'] / 4)

        ; --- MAIN LOOP ---
        loop {
            loopStatus := getStatusParam('currProgram') . getStatusParam('currGui') 
                . getStatusParam('errorShow') . getStatusParam('loadShow')

            if (loopStatus != currStatus) {
                currStatus := loopStatus
                hotkeyBuffer := []

                continue
            }

            ; enable/disable the mouse listener timer if the program uses the mouse
            if (getStatusParam('currMouse').Count > 0 && !WinShown(GUIKEYBOARDTITLE)) {
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
            
            currHotkeys := optimizeHotkeys(getStatusParam('currHotkeys'))
            buttonTime  := getStatusParam('buttonTime')

            for key, value in currHotkeys.buttonTree {
                currButton := key
                currButtonTime := (currHotkeys.buttonTimes.Has(currButton)) ? currHotkeys.buttonTimes[currButton] : buttonTime
                
                loop maxControllers {
                    currController := A_Index - 1

                    if (!inArray(currController . currButton, hotkeyTimers) && xCheckStatus(currButton, currController, globalControllers)) {                       
                        if (currButtonTime > 0) {
                            SetTimer(ButtonTimer.Bind(currButton, currButtonTime, currController, loopStatus), (-1 * currButtonTime))
                        }
                        else {
                            ButtonTimer(currButton, currButtonTime, currController, loopStatus)
                        }

                        hotkeyTimers.Push(currController . currButton)
                    }
                }
            }
            
            ; if hotkeyBuffer has items, prioritize sending buffered inputs
            if (hotkeyBuffer.Length > 0 && getStatusParam('internalMessage') = '') {
                runHotkey(hotkeyBuffer.RemoveAt(1))
            }

            ; close if main is no running
            if (!WinHidden(MAINNAME) || exitThread) {
                ExitApp()
            }
            
            Sleep(loopSleep)
        }

        ; --- TIMERS ---
        ButtonTimer(button, time, port, status) {   
            Critical 'Off'

            global globalStatus     
            global globalControllers

            global currHotkeys
            global buttonTime

            global hotkeyBuffer
            global hotkeyTimers

            if (!xCheckStatus(button, port, globalControllers)) {
                removeTimer(port, button)
                return
            }

            hotkeyData := checkHotkeys(button, currHotkeys, port, globalControllers)

            if (hotkeyData = -1) {
                removeTimer(port, button)
                return
            }

            if (!((hotkeyData.function = 'Exit' || InStr(hotkeyData.function, '.exit')) && getStatusParam('pause') && !getStatusParam('errorShow'))) {
                if (hotkeyData.time != '' && (time - hotkeyData.time) > 0) {
                    SetTimer(ButtonTimer.Bind(button, hotkeyData.time, port, status), (-1 * (time - hotkeyData.time)))
                    return
                }

                sendHotkey(hotkeyData.function)
                SetTimer(WaitButtonTimer.Bind(button, port, hotkeyData, status, 0), -25)
            }
            else {
                removeTimer(port, button)
            }

            return
        }

        WaitButtonTimer(button, port, hotkeyData, status, loopCount) {
            global globalControllers

            global hotkeyBuffer
            global hotkeyTimers
            global currStatus

            Critical 'On'

            if (xCheckStatus(hotkeyData.hotkey, port, globalControllers)) {
                if (status = currStatus) {
                    if (hotkeyData.function = 'ExitProgram') {
                        if (loopCount > 120) {
                            ; A_ScriptDir is the location of the dlls
                            ; need to trim out bin\x64w
                            directory := ''
                            
                            dirArr := StrSplit(A_ScriptDir, '\')
                            loop (dirArr.Length - 2) {
                                directory .= dirArr[A_Index] . '\'
                            }

                            Run A_AhkPath . A_Space . 'send2Main.ahk Nuclear', directory, 'Hide'
                            
                            hotkeyBuffer := []
                            Sleep(1000)
                        }
                    }
                    else if (hotkeyData.modifier = 'repeat') {
                        if (loopCount > 12) {
                            sendHotkey(hotkeyData.function)
                        }
                    }
                    else if (hotkeyData.modifier = 'hold') {
                        sendHotkey(hotkeyData.function, true)
                    }
                }

                SetTimer(WaitButtonTimer.Bind(button, port, hotkeyData, status, loopCount + 1), -25)
            }
            else {
                if (status = currStatus) {
                    if (hotkeyData.modifier = 'repeat') {
                        hotkeyBuffer := []
                    }
    
                    ; trigger release function if it exists
                    sendHotkey(hotkeyData.release)
                }

                removeTimer(port, button)
            }

            return
        }

        MouseTimer() {
            global mouseStatus
            global hscrollCount
            global vscrollCount

            Critical 'Off'

            currMouse := getStatusParam('currMouse')
            deadzone := (currMouse.Has('deadzone')) ? currMouse['deadzone'] : 0.15
            
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

            checkX := currMouse.Has('x')
            checkY := currMouse.Has('y')
            checkH := currMouse.Has('hscroll')
            checkV := currMouse.Has('vscroll')

            checkL := currMouse.Has('lclick')
            checkR := currMouse.Has('rclick')
            checkM := currMouse.Has('mclick')

            loop maxControllers {
                currController := A_Index - 1
                if (!xGetConnected(currController, globalControllers)) {
                    continue
                }

                currStatusData := xGetPortBuffer(currController, globalControllers)

                ; check mouse move x axis
                if (checkX) {
                    currAxis := currMouse['x']
                    inverted := false

                    if (SubStr(currAxis, 1, 1) = '-') {
                        currAxis := SubStr(currAxis, 2)
                        inverted := true
                    }

                    axis := xCheckAxis(currStatusData, currAxis)
                    if (Abs(axis) > deadzone) {
                        xvel := (inverted) ? (xvel - axis) : (xvel + axis)
                    }
                }
                ; check mouse move y axis
                if (checkY) {
                    currAxis := currMouse['y']
                    inverted := false

                    if (SubStr(currAxis, 1, 1) = '-') {
                        currAxis := SubStr(currAxis, 2)
                        inverted := true
                    }

                    axis := xCheckAxis(currStatusData, currAxis)
                    if (Abs(axis) > deadzone) {
                        yvel := (inverted) ? (yvel - axis) : (yvel + axis)
                    }
                }

                ; check mouse horizontal scroll axis
                if (checkH) {
                    currAxis := currMouse['hscroll']
                    inverted := false

                    if (SubStr(currAxis, 1, 1) = '-') {
                        currAxis := SubStr(currAxis, 2)
                        inverted := true
                    }

                    axis := xCheckAxis(currStatusData, currAxis)
                    if (Abs(axis) > deadzone) {
                        hscroll := (inverted) ? (hscroll - axis) : (hscroll + axis)
                    }
                }
                ; check mouse vertical scroll axis
                if (checkV) {
                    currAxis := currMouse['vscroll']
                    inverted := false

                    if (SubStr(currAxis, 1, 1) = '-') {
                        currAxis := SubStr(currAxis, 2)
                        inverted := true
                    }

                    axis := xCheckAxis(currStatusData, currAxis)
                    if (Abs(axis) > deadzone) {
                        vscroll := (inverted) ? (vscroll - axis) : (vscroll + axis)
                    }
                }

                ; check left click button
                if (checkL) {
                    if (xCheckButton(currStatusData, currMouse['lclick'])) {
                        if (!(mouseStatus['lclick'] & (2 ** currController))) {
                            MouseClick('Left',,,,, 'D')
                            mouseStatus['lclick'] := mouseStatus['lclick'] | (2 ** currController)
                        }
                    }
                    else {
                        if (mouseStatus['lclick'] & (2 ** currController)) {
                            MouseClick('Left',,,,, 'U')
                            mouseStatus['lclick'] := mouseStatus['lclick'] ^ (2 ** currController)
                        }
                    }
                }
                ; check right click button
                if (checkR) {
                    if (xCheckButton(currStatusData, currMouse['rclick'])) {
                        if (!(mouseStatus['rclick'] & (2 ** currController))) {
                            MouseClick('Right',,,,, 'D')
                            mouseStatus['rclick'] := mouseStatus['rclick'] | (2 ** currController)
                        }
                    }
                    else {
                        if (mouseStatus['rclick'] & (2 ** currController)) {
                            MouseClick('Right',,,,, 'U')
                            mouseStatus['rclick'] := mouseStatus['rclick'] ^ (2 ** currController)
                        }
                    }
                }
                ; check middle click button
                if (checkM) {
                    if (xCheckButton(currStatusData, currMouse['mclick'])) {
                        if (!(mouseStatus['mclick'] & (2 ** currController))) {
                            MouseClick('Middle',,,,, 'D')
                            mouseStatus['mclick'] := mouseStatus['mclick'] | (2 ** currController)
                        }
                    }
                    else {
                        if (mouseStatus['mclick'] & (2 ** currController)) {
                            MouseClick('Middle',,,,, 'U')
                            mouseStatus['mclick'] := mouseStatus['mclick'] ^ (2 ** currController)
                        }
                    }
                }
            }

            ; move the mouse
            xvel := Round((adjustAxis(xvel, deadzone) * (0.015 * monitorW)))
            yvel := Round((adjustAxis(yvel, deadzone) * (0.015 * monitorW)))

            if (xvel != 0 || yvel != 0) {
                MouseMove(xvel, yvel,, 'R')
            }
            
            ; only send scroll actions every x timer cycles
            ; otherwise it will scroll way too fast
            hscroll := Round(adjustAxis(hscroll, deadzone) * 3)
            vscroll := Round(adjustAxis(vscroll, deadzone) * 3)
            
            if (Abs(hscrollCount * hscroll) > 6) {
                if (hscroll > 0) {
                    MouseClick('WheelRight')
                }
                else if (hscroll < 0) {
                    MouseClick('WheelLeft')
                }
                
                hscrollCount := 0
            }
            if (Abs(vscrollCount * vscroll) > 6) {
                if (vscroll > 0) {
                    MouseClick('WheelDown')
                }
                else if (vscroll < 0) {
                    MouseClick('WheelUp')
                }

                vscrollCount := 0
            }

            hscrollCount += 1
            vscrollCount += 1

            return
        }

        "
    ),, "hotkeyThread")

    global MAINSCRIPTDIR
    SetWorkingDir(MAINSCRIPTDIR)

    return ref
}

; run function in separate thread
;  text - string name of function to run
;  params - spread args to pass to function
;
; returns null
functionThread(globalConfig, globalStatus) {
    ref := ThreadObj(
    (
        "        
        #Include lib-mc\std.ahk
        #Include lib-mc\mt\status.ahk

        ; --- GLOBAL VARIABLES ---

        global exitThread := false

        ; variables are global to be accessed in timers
        global globalConfig      := ObjShare(" globalConfig ")
        global globalStatus      := " globalStatus "

        loopSleep := Round(globalConfig['General']['AvgLoopSleep'] / 3)

        loop {
            function := getStatusParam('threadedFunction')

            if (function != '') {
                try runFunction(function)

                if (function = getStatusParam('threadedFunction')) {
                    setStatusParam('threadedFunction', '')
                }
            }

            ; close if main is no running
            if (!WinHidden(MAINNAME) || exitThread) {
                ExitApp()
            }

            Sleep(loopSleep)
        }
        "
    ),, "functionThread")

    global MAINSCRIPTDIR
    SetWorkingDir(MAINSCRIPTDIR)

    return ref
}