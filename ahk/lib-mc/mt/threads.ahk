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

                ; copy battery type & level to buffer
                batteryStatus := xGetBattery(port, xGetBatteryPtr)
                copyBufferData(batteryStatus.Ptr, globalControllers + (port * 20) + 1, 2)

                ; gets vibration setting & activates/deactivates if needed
                newVibration := NumGet(globalControllers + (port * 20) + 3, 0, 'UChar')
                if (currVibration[A_Index] != newVibration) {
                    currVibration[A_Index] := xSetVibration(port, xSetVibrationPtr, newVibration)
                }

                ; copy button status to buffer
                copyBufferData(controllerStatus.Ptr, globalControllers + (port * 20) + 4, 16)
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

        setCurrentWinTitle('hotkeyThread')

        SetKeyDelay 80, 60

        ; --- GLOBAL VARIABLES ---

        global exitThread := false

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

        ; either adds a hotkey to the buffer or internalStatus
        ;  hotkeyFunction - function string to send to main
        ;
        ; returns null
        sendHotkey(hotkeyFunction) {
            global hotkeyBuffer

            if (hotkeyFunction = '') {
                return
            }

            ; check if can just send input or need to buffer
            if (getStatusParam('internalMessage') != '') {
                hotkeyBuffer.Push(hotkeyFunction)
            }
            else {
                setStatusParam('internalMessage', hotkeyFunction)
            }
        }

        maxControllers := globalConfig['General']['MaxXInputControllers']
        loopSleep := Round(globalConfig['General']['AvgLoopSleep'] / 4)

        ; --- MAIN LOOP ---
        loop {
            currHotkeys := optimizeHotkeys(getStatusParam('currHotkeys'))
            buttonTime  := getStatusParam('buttonTime')

            ; if hotkeys are not valid, just skip
            if (!currHotkeys.Has('uniqueKeys') || !currHotkeys.Has('hotkeys')) {
                Sleep(loopSleep)
                continue
            }

            ; check hotkeys
            for item in currHotkeys['uniqueKeys'] {
                currButton := item

                loop maxControllers {
                    currController := A_Index - 1

                    if (xCheckStatus(currButton, currController, globalControllers)) {                       
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
            if (!WinHidden(MAINNAME) || exitThread) {
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
            if ((hotkeyData.function = 'Pause' && currLoad) 
                || ((hotkeyData.function = 'Exit' || InStr(hotkeyData.function, '.exit')) && getStatusParam('pause') && !getStatusParam('errorShow'))) {
                currController := -1
                currButton := ''

                return
            }

            ; check if can just send input or need to buffer
            sendHotkey(hotkeyData.function)

            ; if user holds button for a long time, kill everything
            if (hotkeyData.function = 'Exit' || InStr(hotkeyData.function, '.exit')) {
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

            ; trigger release function if it exists
            sendHotkey(hotkeyData.release)

            currController := -1
            currButton := ''

            return
        }

        ; timer for the delayed 2nd add to hotkey buffer
        ; starts RepeatFastTimer
        RepeatTimer() {
            global hotkeyData
            global hotkeyBuffer

            sendHotkey(hotkeyData.function)

            SetTimer(RepeatFastTimer, 40)
            return
        }

        ; timer for repeated function adds to buffer at short interval 
        RepeatFastTimer() {
            global hotkeyData
            global hotkeyBuffer

            sendHotkey(hotkeyData.function)

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