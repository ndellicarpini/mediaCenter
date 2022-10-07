; creates the controller thread to check the input status of each connected controller
;  globalControllers - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that checks controller statuses
controllerThread(controlID, globalConfig, globalStatus, globalPrograms, globalConsoles
    , globalRunning, globalGuis, globalControllers, globalControlConfigs) {
    
    dynamicIncludes := getDynamicIncludes("main.ahk")
    ref := ThreadObj(dynamicIncludes . "
    (
        #Include lib\confio.ahk
        #Include lib\std.ahk
        #Include lib\messaging.ahk
        #Include lib\program.ahk
        #Include lib\emulator.ahk
        #Include lib\data.ahk
        #Include lib\hotkeys.ahk
        #Include lib\desktop.ahk
        #Include lib\controller.ahk
        #Include lib\threads.ahk

        #Include lib\gui\std.ahk
        #Include lib\gui\constants.ahk
        #Include lib\gui\interface.ahk
        #Include lib\gui\choicedialog.ahk
        #Include lib\gui\loadscreen.ahk
        #Include lib\gui\pausemenu.ahk
        #Include lib\gui\volumemenu.ahk
        #Include lib\gui\controllermenu.ahk
        #Include lib\gui\programmenu.ahk
        #Include lib\gui\powermenu.ahk
        #Include lib\gui\keyboard.ahk

        global exitThread := false
        
        global controlID            := " controlID "
        global globalConfig         := ObjFromPtrAddRef(" globalConfig ")
        global globalStatus         := ObjFromPtrAddRef(" globalStatus ")
        global globalPrograms       := ObjFromPtrAddRef(" globalPrograms ")
        global globalRunning        := ObjFromPtrAddRef(" globalRunning ")
        global globalGuis           := ObjFromPtrAddRef(" globalGuis ")
        global globalControllers    := ObjFromPtrAddRef(" globalControllers ")
        global globalControlConfigs := ObjFromPtrAddRef(" globalControlConfigs ")

        global thisController := globalControllers[controlID]
        global thisConfig     := globalControlConfig[controlID]
        global thisHotkeys    := ''
        global thisMouse      := ''

        global buttonTime  := globalStatus['controller']['buttonTime']

        global hotkeyBuffer := []
        global hotkeyTimers := []

        global mouseStatus := Map('lclick', 0, 'rclick', 0, 'mclick', 0)
        global hscrollCount  := 0
        global vscrollCount  := 0

        global currHotkeys := ''
        global currStatus  := ''

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

        ; either adds a hotkey to the buffer or internalStatus
        ;  hotkeyFunction - function string to run
        ;  forceSend - whether or not to skip buffer
        ;
        ; returns null
        sendHotkey(hotkeyFunction, forceSend := false) {
            global globalStatus

            if (hotkeyFunction = '') {
                return
            }

            globalStatus['controller']['buffer'].Push(hotkeyFunction)
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

        maxControllers := globalControlConfig['maxConnected']
        loopSleep := Round(globalConfig['General']['AvgLoopSleep'] / 5)

        loop {
            currStatus := globalStatus['currProgram'] . globalStatus['currGui']
                . globalStatus['error']['show'] . globalStatus['loadscreen']['show']

            if (globalControllers.Has(controlID)) {
                thisController := globalControllers[controlID]
            }
            if (globalControlConfigs.Has(controlID)) {
                thisConfig := globalControlConfigs[controlID]
            }
            if (globalStatus['controller']['hotkeys'].Has(controlID)) {
                thisHotkeys := globalStatus['controller']['hotkeys'][controlID]
            }
            if (globalStatus['controller']['mouse'].Has(controlID)) {
                thisMouse := globalStatus['controller']['mouse'][controlID]
            }

            ; enable/disable the mouse listener timer if the program uses the mouse
            if (thisMouse.Count > 0 && !WinShown(GUIKEYBOARDTITLE)) {
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
            buttonTime  := globalStatus['controller']['buttonTime']

            for key, value in currHotkeys.buttonTree {
                currButton := key
                currButtonTime := (currHotkeys.buttonTimes.Has(currButton)) ? currHotkeys.buttonTimes[currButton] : buttonTime
                
                loop maxControllers {
                    currController := A_Index - 1

                    status := thisController[currController].getStatus()                    

                    if (!inArray(currController . currButton, hotkeyTimers) && controllerCheckStatus(currButton, status)) {                       
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
            global thisController

            global currHotkeys
            global buttonTime

            global hotkeyTimers

            controllerStatus := thisController[port].getStatus()

            if (controllerCheckStatus(button, controllerStatus)) {
                removeTimer(port, button)
                return
            }

            hotkeyData := checkHotkeys(button, currHotkeys, controllerStatus)

            if (hotkeyData = -1) {
                removeTimer(port, button)
                return
            }

            if (!((hotkeyData.function = 'Exit' || InStr(hotkeyData.function, '.exit')) && globalStatus['pause'] && !globalStatus['error']['show'])) {
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
            global thisController

            global hotkeyBuffer
            global hotkeyTimers
            global currStatus

            Critical 'On'

            if (controllerCheckStatus(button, thisController[port].getStatus())) {
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
            global thisController

            global mouseStatus
            global hscrollCount
            global vscrollCount

            Critical 'Off'

            currMouse := thisMouse
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
                currStatusData := thisController[currController].getStatus()
                if (!thisController[currController].connected) {
                    continue
                }

                ; check mouse move x axis
                if (checkX) {
                    currAxis := currMouse['x']
                    inverted := false

                    if (SubStr(currAxis, 1, 1) = '-') {
                        currAxis := SubStr(currAxis, 2)
                        inverted := true
                    }

                    if (currStatusData['axis'].Has(currAxis)) {
                        axis := currStatusData['axis'][currAxis]
                        if (Abs(axis) > deadzone) {
                            xvel := (inverted) ? (xvel - axis) : (xvel + axis)
                        }
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

                    if (currStatusData['axis'].Has(currAxis)) {
                        axis := currStatusData['axis'][currAxis]
                        if (Abs(axis) > deadzone) {
                            yvel := (inverted) ? (yvel - axis) : (yvel + axis)
                        }
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

                    if (currStatusData['axis'].Has(currAxis)) {
                        axis := currStatusData['axis'][currAxis]
                        if (Abs(axis) > deadzone) {
                            hscroll := (inverted) ? (hscroll - axis) : (hscroll + axis)
                        }
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

                    if (currStatusData['axis'].Has(currAxis)) {
                        axis := currStatusData['axis'][currAxis]
                        if (Abs(axis) > deadzone) {
                            vscroll := (inverted) ? (vscroll - axis) : (vscroll + axis)
                        }
                    }
                }

                ; check left click button
                if (checkL) {
                    if (inArray(currStatusData['buttons'], currMouse['lclick'])) {
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
                    if (inArray(currStatusData['buttons'], currMouse['rclick'])) {
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
                    if (inArray(currStatusData['buttons'], currMouse['mclick'])) {
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
    )",, "controllerThread")

    global MAINSCRIPTDIR
    SetWorkingDir(MAINSCRIPTDIR)

    return ref
}

; run function in separate thread
;  text - string name of function to run
;  params - spread args to pass to function
;
; returns null
actionThread(globalConfig, globalStatus, globalPrograms, globalConsoles
    , globalRunning, globalGuis, globalControllers, globalControlConfigs) {
    
    dynamicIncludes := getDynamicIncludes("main.ahk")
    ref := ThreadObj(dynamicIncludes . "
    (     
        #Include lib\confio.ahk
        #Include lib\std.ahk
        #Include lib\messaging.ahk
        #Include lib\program.ahk
        #Include lib\emulator.ahk
        #Include lib\data.ahk
        #Include lib\hotkeys.ahk
        #Include lib\desktop.ahk
        #Include lib\controller.ahk
        #Include lib\threads.ahk

        #Include lib\gui\std.ahk
        #Include lib\gui\constants.ahk
        #Include lib\gui\interface.ahk
        #Include lib\gui\choicedialog.ahk
        #Include lib\gui\loadscreen.ahk
        #Include lib\gui\pausemenu.ahk
        #Include lib\gui\volumemenu.ahk
        #Include lib\gui\controllermenu.ahk
        #Include lib\gui\programmenu.ahk
        #Include lib\gui\powermenu.ahk
        #Include lib\gui\keyboard.ahk

        ; --- GLOBAL VARIABLES ---

        global exitThread := false

        ; variables are global to be accessed in timers
        global globalConfig         := ObjFromPtrAddRef(" globalConfig ")
        global globalStatus         := ObjFromPtrAddRef(" globalStatus ")
        global globalPrograms       := ObjFromPtrAddRef(" globalPrograms ")
        global globalRunning        := ObjFromPtrAddRef(" globalRunning ")
        global globalGuis           := ObjFromPtrAddRef(" globalGuis ")
        global globalControllers    := ObjFromPtrAddRef(" globalControllers ")
        global globalControlConfigs := ObjFromPtrAddRef(" globalControlConfigs ")

        loopSleep := Round(globalConfig['General']['AvgLoopSleep'] / 3)

        loop {
            loopStatus := globalStatus['currProgram'] . globalStatus['currGui']
                . globalStatus['error']['show'] . globalStatus['loadscreen']['show']

            if (loopStatus != currStatus) {
                currStatus := loopStatus
                globalStatus['controller']['buffer'] := []

                continue
            }

            if (globalStatus['controller']['buffer'].Length > 0) {
                bufferedFunc := globalStatus['controller']['buffer'].Pop()

                ; update pause status & create/destroy pause menu
                if (StrLower(bufferedFunc) = 'pausemenu') {
                    if (!globalGuis.Has(GUIPAUSETITLE)) {
                        guiPauseMenu()
                    }
                    else {
                        globalGuis[GUIPAUSETITLE].Destroy()
                    }
                }

                ; exits the current error or program
                else if (StrLower(bufferedFunc) = 'exitprogram') {
                    if (globalStatus['error']['show']) {
                        errorHwnd := globalStatus['error']['hwnd']
                        errorGUI := getGUI(errorHwnd)

                        if (errorGUI) {
                            errorGUI.Destroy()
                        }
                        else {
                            CloseErrorMsg(errorHwnd)
                        }
                    }
                    else if (currProgram != '' && globalRunning[currProgram].allowExit) {
                        try globalRunning[currProgram].exit()

                        if (!globalRunning[currProgram].exists()) {
                            globalStatus['currProgram'] := ''
                        }
                    }
                }

                ; run current gui funcion
                else if (StrLower(SubStr(bufferedFunc, 1, 4)) = 'gui.') {
                    tempArr  := StrSplit(bufferedFunc, A_Space)
                    tempFunc := StrReplace(tempArr.RemoveAt(1), 'gui.', '') 

                    try globalGuis[currGui].%tempFunc%(tempArr*)
                }

                ; run current program function
                else if (StrLower(SubStr(bufferedFunc, 1, 8)) = 'program.') {
                    tempArr  := StrSplit(bufferedFunc, A_Space)
                    tempFunc := StrReplace(tempArr.RemoveAt(1), 'program.', '')
                    
                    if (tempFunc = 'pause' || tempFunc = 'resume' || tempFunc = 'minimize' 
                        || tempFunc = 'exit' || tempFunc = 'restore' || tempFunc = 'launch') {

                        try globalRunning[currProgram].%tempFunc%(tempArr*)
                    }
                    else {
                        SetTimer(WaitProgramResume.Bind(currProgram, tempFunc, tempArr), -50)
                    }
                }

                ; run function
                else {
                    try runFunction(bufferedFunc)
                }
            }

            ; close if main is no running
            if (!WinHidden(MAINNAME) || exitThread) {
                ExitApp()
            }

            Sleep(loopSleep)
        }
    )",, "actionThread")

    global MAINSCRIPTDIR
    SetWorkingDir(MAINSCRIPTDIR)

    return ref
}