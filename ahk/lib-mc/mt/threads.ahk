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
        
        setCurrentWinTitle('controllerThread')
        
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

        loop {
            controllerStatus := xGetStatus(maxControllers, xGetStatusPtr)
            batteryStatus    := xGetBattery(maxControllers, xGetBatteryPtr)
            currVibration    := xSetVibration(maxControllers, xSetVibrationPtr, currVibration, globalControllers)
            loop maxControllers {
                port := A_Index - 1

                NumPut('UChar', batteryStatus[A_Index], globalControllers + (port * 18) + 1, 0)
                copyBufferData(controllerStatus[A_Index].Ptr, globalControllers + (port * 18) + 2, 16)
            }

            ; close if main is no running
            if (!WinHidden(MAINNAME)) {
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

        setCurrentWinTitle('hotkeyThread')

        SetKeyDelay 80, 60

        ; --- GLOBAL VARIABLES ---

        ; variables are global to be accessed in timers
        global globalConfig      := ObjShare(" globalConfig ")
        global globalStatus      := " globalStatus "
        global globalControllers := " globalControllers "

        ; time user needs to hold button to trigger hotkey function
        global buttonTime := getStatusParam('buttonTime')

        global currHotkeys := optimizeHotkeys(getStatusParam('currHotkeys'))
        global currController := -1
        global currButton := ''

        global hotkeyData := {}
        global hotkeyBuffer := []

        maxControllers := globalConfig['General']['MaxXInputControllers']
        loopSleep := Round(globalConfig['General']['AvgLoopSleep'] / 4)

        ; --- MAIN LOOP ---
        loop {
            ; only check buttons if script not suspended
            if (getStatusParam('suspendScript')) {
                Sleep(loopSleep)
                continue
            }

            currHotkeys := optimizeHotkeys(getStatusParam('currHotkeys'))
            buttonTime  := getStatusParam('buttonTime')

            ; if hotkeys are not valid, just skip
            if (!currHotkeys.Has('uniqueKeys') || !currHotkeys.Has('hotkeys')) {
                Sleep(loopSleep)
                continue
            }

            ; check hotkeys
            for item in currHotkeys['uniqueKeys'] {
                loop maxControllers {
                    if (xCheckStatus(item, (A_Index - 1), globalControllers)) {
                        currController := A_Index - 1
                        currButton := item

                        SetTimer(ButtonTimer, (-1 * buttonTime))
                        while (xCheckStatus(currButton, currController, globalControllers)) {
                            Sleep(5)
                        }
                        SetTimer(ButtonTimer, 0)
                    }
                }
            }
            
            ; if hotkeyBuffer has items, prioritize sending buffered inputs
            if (hotkeyBuffer.Length > 0) {
                if (getStatusParam('internalMessage') = '') {
                    setStatusParam('internalMessage', hotkeyBuffer.RemoveAt(1))
                }
            }

            ; close if main is no running
            if (!WinHidden(MAINNAME)) {
                ExitApp()
            }
            
            Sleep(loopSleep)
        }

        ; --- TIMERS ---
        ButtonTimer() {   
            global globalStatus     
            global globalControllers

            global currHotkeys
            global currController
            global currButton

            global hotkeyData
            global hotkeyBuffer

            currProgram  := getStatusParam('currProgram')
            currGui      := getStatusParam('currGui')
            currError    := getStatusParam('errorHwnd')
            currLoad     := getStatusParam('loadShow')

            hotkeyData := checkHotkeys(currButton, currHotkeys, currController, globalControllers)

            if (hotkeyData = -1) {
                currController := -1
                currButton := ''

                return
            }

            ; TODO - think about if hard-coded disable pause when loading is good
            ;      - now also exit is hard-coded off when paused
            if ((hotkeyData.function = 'Pause' && currLoad) || (hotkeyData.function = 'Exit' && getStatusParam('pause'))) {
                currController := -1
                currButton := ''

                return
            }

            ; check if can just send input or need to buffer
            if (getStatusParam('internalMessage') != '') {
                hotkeyBuffer.Push(hotkeyData.function)
            }
            else {
                setStatusParam('internalMessage', hotkeyData.function)
            }

            ; if user holds button for a long time, kill everything
            if (hotkeyData.function = 'Exit') {
                SetTimer(NuclearTimer, -3000)
                while ((currProgram = getStatusParam('currProgram') || currGui = getStatusParam('currGui')
                    || currError = getStatusParam('errorHwnd' || currLoad = getStatusParam('loadShow')))
                    && xCheckStatus(hotkeyData.hotkey, currController, globalControllers)) {
                    
                    Sleep(5)
                }
                SetTimer(NuclearTimer, 0)
            }

            ; forces internalMessage = function while hotkey is held 
            if (hotkeyData.modifier = 'hold') {
                while (xCheckStatus(hotkeyData.hotkey, currController, globalControllers)) {
                    if (getStatusParam('internalMessage') = '') {
                        setStatusParam('internalMessage', hotkeyData.function)
                    }
                    
                    Sleep(loopSleep)
                }
            }

            ; after a delay, repeatedly adds new function call to hotkey buffer while hotkey is held
            else if (hotkeyData.modifier = 'repeat') {
                SetTimer(RepeatTimer, -400)

                while (xCheckStatus(hotkeyData.hotkey, currController, globalControllers)) {
                    Sleep(5)
                }

                ; clear hotkey buffer when button is released
                hotkeyBuffer := []
                SetTimer(RepeatTimer, 0)
                SetTimer(RepeatFastTimer, 0)
            }

            ; loop while hotkey is held
            else {
                while (xCheckStatus(hotkeyData.hotkey, currController, globalControllers)) {
                    Sleep(5)
                }
            }

            currController := -1
            currButton := ''

            return
        }

        ; timer for the delayed 2nd add to hotkey buffer
        ; starts RepeatFastTimer
        RepeatTimer() {
            global hotkeyData
            global hotkeyBuffer

            ; check if can just send input or need to buffer
            if (getStatusParam('internalMessage') != '') {
                hotkeyBuffer.Push(hotkeyData.function)
            }
            else {
                setStatusParam('internalMessage', hotkeyData.function)
            }

            SetTimer(RepeatFastTimer, 40)
            return
        }

        ; timer for repeated function adds to buffer at short interval 
        RepeatFastTimer() {
            global hotkeyData
            global hotkeyBuffer

            ; check if can just send input or need to buffer
            if (getStatusParam('internalMessage') != '') {
                hotkeyBuffer.Push(hotkeyData.function)
            }
            else {
                setStatusParam('internalMessage', hotkeyData.function)
            }

            return
        }

        ; timer for after exit has been held for long enough
        NuclearTimer() {
            global globalStatus

            setStatusParam('internalMessage', 'Nuclear')
            return
        }

        "
    ))

    global MAINSCRIPTDIR
    SetWorkingDir(MAINSCRIPTDIR)

    return ref
}