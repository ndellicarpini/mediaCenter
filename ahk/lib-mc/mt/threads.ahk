; creates the controller thread to check the input status of each connected controller
;  globalControllers - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that checks controller statuses
controllerThread(globalConfig, globalControllers) {
    ref := ThreadObj(
    (
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\xinput.ahk
        
        SetCurrentWinTitle('controllerThread')

        global exitThread := false
        
        global globalConfig      := ObjShare(" globalConfig ")
        global globalControllers := " globalControllers "

        xLibrary := dllLoadLib('xinput1_3.dll')
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
                dllFreeLib(xLibrary)
                ExitApp()
            }

            Sleep(loopSleep)
        }
        "
    ))

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

        SetCurrentWinTitle('hotkeyThread')

        SetKeyDelay 50, 100
        Critical 'Off'

        ; --- GLOBAL VARIABLES ---

        global exitThread := false

        ; variables are global to be accessed in timers
        global globalConfig      := ObjShare(" globalConfig ")
        global globalStatus      := " globalStatus "
        global globalControllers := " globalControllers "

        ; time user needs to hold button to trigger hotkey function
        global buttonTime  := getStatusParam('buttonTime')
        global currHotkeys := optimizeHotkeys(getStatusParam('currHotkeys'))

        global hotkeyBuffer  := []
        global runningTimers := []
        global currStatus    := ''

        ; removes timer id from running timers
        ;  port - port of controller
        ;  button - unique button pressed
        ;
        ; returns null
        removeTimer(port, button) {
            global runningTimers

            loop runningTimers.Length {
                if (runningTimers[A_Index] = port . button) {
                    runningTimers.RemoveAt(A_Index)
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

            currHotkeys := optimizeHotkeys(getStatusParam('currHotkeys'))
            buttonTime  := getStatusParam('buttonTime')

            ; check hotkeys
            for key, value in currHotkeys.buttonTree {
                currButton := key
                currButtonTime := (currHotkeys.buttonTimes.Has(currButton)) ? currHotkeys.buttonTimes[currButton] : buttonTime
                
                loop maxControllers {
                    currController := A_Index - 1

                    if (!inArray(currController . currButton, runningTimers) && xCheckStatus(currButton, currController, globalControllers)) {                       
                        if (currButtonTime > 0) {
                            SetTimer(ButtonTimer.Bind(currButton, currButtonTime, currController, loopStatus), (-1 * currButtonTime))
                        }
                        else {
                            ButtonTimer(currButton, currButtonTime, currController, loopStatus)
                        }

                        runningTimers.Push(currController . currButton)
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
            global runningTimers

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
            global runningTimers
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

        "
    ))

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
            
            SetCurrentWinTitle('functionThread')

            ; --- GLOBAL VARIABLES ---

            global exitThread := false

            ; variables are global to be accessed in timers
            global globalConfig      := ObjShare(" globalConfig ")
            global globalStatus      := " globalStatus "

            loopSleep := Round(globalConfig['General']['AvgLoopSleep'] / 3)

            loop {
                function := getStatusParam('threadedFunction')

                if (function != '') {
                    runFunction(function)

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
    ))

    global MAINSCRIPTDIR
    SetWorkingDir(MAINSCRIPTDIR)

    return ref
}