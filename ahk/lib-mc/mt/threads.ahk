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
        
        global globalConfig      := cleanComMap(ObjShare(" globalConfig "))
        global globalControllers := " globalControllers "

        xLibrary := dllLoadLib('xinput1_3.dll')
        xGetStatusPtr := 0
        
        if (xLibrary != 0) {
            xGetStatusPtr := DllCall('GetProcAddress', 'UInt', xLibrary, 'UInt', 100)
        }
        else {
            ErrorMsg('Failed to initialize xinput', true)
        }

        maxControllers := globalConfig['General']['MaxXInputControllers']
        loopSleep := Round(globalConfig['General']['AvgLoopSleep'] / 5)

        loop {
            controllerStatus := xGetStatus(maxControllers, xGetStatusPtr)
            loop controllerStatus.Length {
                port := A_Index - 1

                loop 2 {
                    NumPut('UInt64', NumGet(controllerStatus[port + 1].Ptr + (8 * (A_Index - 1)), 0, 'UInt64')
                        , globalControllers + (port * 16) + (8 * (A_Index - 1)), 0)
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
        global globalConfig      := cleanComMap(ObjShare(" globalConfig "))
        global globalStatus      := " globalStatus "
        global globalControllers := " globalControllers "

        global currProgram  := getStatusParam('currProgram')
        global currOverride := getStatusParam('overrideProgram')
        global currError    := getStatusParam('errorHwnd')

        global currLoad     := getStatusParam('loadShow')

        global currHotkeys := optimizeHotkeys(getStatusParam('currHotkeys'))
        global currController := -1
        global currButton := ''

        maxControllers := globalConfig['General']['MaxXInputControllers']
        loopSleep := Round(globalConfig['General']['AvgLoopSleep'] / 4)

        ; --- MAIN LOOP ---
        loop {
            currProgram  := getStatusParam('currProgram')
            currOverride := getStatusParam('overrideProgram')
            currError    := getStatusParam('errorHwnd')
    
            currLoad     := getStatusParam('loadShow')

            currHotkeys := optimizeHotkeys(getStatusParam('currHotkeys'))

            ; only check buttons if script not suspended
            if (getStatusParam('suspendScript')) {
                Sleep(loopSleep)
                continue
            }

            if (!currHotkeys.Has('uniqueKeys') || !currHotkeys.Has('hotkeys')) {
                Sleep(loopSleep)
                continue
            }

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

            ; close if main is no running
            if (!WinHidden(MAINNAME)) {
                ExitApp()
            }
            
            Sleep(loopSleep)
        }

        ; --- TIMERS ---
        ButtonTimer() {
            global

            hotkeyInfo := checkHotkeys(currButton, currHotkeys['hotkeys'], currController, globalControllers)

            if (hotkeyInfo[2] = 'Pause' && currLoad) {
                return
            }

            setStatusParam('internalMemo', hotkeyInfo[2])

            ; if user holds button for a long time, kill everything
            if (hotkeyInfo[2] = 'Exit') {
                SetTimer(NuclearTimer, -3000)
                while ((currProgram = getStatusParam('currProgram') 
                    || currOverride = getStatusParam('overrideProgram')
                    || currError = getStatusParam('errorHwnd'))
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
            global

            setStatusParam('internalMemo', 'Nuclear')
            return
        }

        "
    ))
}

; closes all threads
;  threads - map of all current threads
;
; returns null
closeAllThreads(threads) {
    for key, value in threads {
        try {
            value.ExitApp()
        }
        catch {
            continue
        }
    }
}