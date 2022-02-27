; creates the controller thread to check the input status of each connected controller
;  globalControllers - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that checks controller statuses
controllerThread(globalConfig, globalControllers) {
    return ThreadObj(
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
                loop 2 {
                    NumPut('UInt64', NumGet(controllerStatus[port + 1].Ptr + (8 * (A_Index - 1)), 0, 'UInt64')
                        , globalControllers + (port * 18) + 2 + (8 * (A_Index - 1)), 0)
                }
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
}

; creates the thread that does actions based on current mainStatus & mainControllers
;  globalConfig - mainConfig as gotten as a ComObject through ObjShare
;  globalStatus - mainStatus as gotten as a ComObject through ObjShare 
;  globalControllers - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that does x based on mainStatus
hotkeyThread(globalConfig, globalStatus, globalControllers) {
    return ThreadObj(
    (
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\xinput.ahk
        #Include lib-mc\hotkeys.ahk

        #Include lib-mc\mt\status.ahk

        setCurrentWinTitle('hotkeyThread')

        SetKeyDelay 80, 60

        ; --- GLOBAL VARIABLES ---
        ; time user needs to hold button to trigger hotkey function
        global buttonTime := 70

        ; variables are global to be accessed in timers
        global globalConfig      := ObjShare(" globalConfig ")
        global globalStatus      := " globalStatus "
        global globalControllers := " globalControllers "

        global currHotkeys := optimizeHotkeys(getStatusParam('currHotkeys'))
        global currController := -1
        global currButton := ''

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

            global hotkeyBuffer

            currProgram  := getStatusParam('currProgram')
            currGui      := getStatusParam('currGui')
            currError    := getStatusParam('errorHwnd')
            currLoad     := getStatusParam('loadShow')

            hotkeyInfo := checkHotkeys(currButton, currHotkeys['hotkeys'], currController, globalControllers)
            if (hotkeyInfo = -1) {
                currController := -1
                currButton := ''

                return
            }

            ; TODO - think about if hard-coded disable pause when loading is good
            if (hotkeyInfo[2] = 'Pause' && currLoad) {
                currController := -1
                currButton := ''

                return
            }

            ; check if can just send input or need to buffer
            if (getStatusParam('internalMessage') != '') {
                hotkeyBuffer.Push(hotkeyInfo[2])
            }
            else {
                setStatusParam('internalMessage', hotkeyInfo[2])
            }

            ; if user holds button for a long time, kill everything
            if (hotkeyInfo[2] = 'Exit') {
                SetTimer(NuclearTimer, -3000)
                while ((currProgram = getStatusParam('currProgram') || currGui = getStatusParam('currGui')
                    || currError = getStatusParam('errorHwnd' || currLoad = getStatusParam('loadShow')))
                    && xCheckStatus(hotkeyInfo[1], currController, globalControllers)) {
                    
                    Sleep(5)
                }
                SetTimer(NuclearTimer, 0)
            }

            ; wait for user to release buttons
            while (xCheckStatus(hotkeyInfo[1], currController, globalControllers)) {
                Sleep(5)
            }

            currController := -1
            currButton := ''

            return
        }

        NuclearTimer() {
            global globalStatus

            setStatusParam('internalMessage', 'Nuclear')
            return
        }

        "
    ))
}