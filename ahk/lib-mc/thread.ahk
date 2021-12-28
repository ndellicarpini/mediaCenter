; creates the thread that does actions based on current mainStatus & mainControllers
;  localConfig - mainConfig as gotten as a ComObject through ObjShare
;  localStatus - mainStatus as gotten as a ComObject through ObjShare 
;  localControllers - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that does x based on mainStatus
hotkeyThread(localConfig, localStatus, localControllers, localRunning) {
    return ThreadObj(dynamicInclude
    (
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\xinput.ahk
        #Include lib-mc\hotkeys.ahk

        setCurrentWinTitle('hotkeyThread')

        SetKeyDelay 80, 60

        ; --- GLOBAL VARIABLES ---
        ; variables are global to be accessed in timers
        global localStatus      := cleanComMap(ObjShare(" localStatus "))
        global localConfig      := cleanComMap(ObjShare(" localConfig "))
        global localControllers := cleanComMap(ObjShare(" localControllers "))

        global localRunning     := ObjShare(" localRunning ")

        global currProgram  := StrGet(localStatus['currProgram'])
        global currOverride := StrGet(localStatus['overrideProgram'])

        global currPause    := NumGet(localStatus['pause'], 0, 'UChar')
        global currLoad     := NumGet(localStatus['loadShow'], 0, 'UChar')
        global currError    := NumGet(localStatus['errorShow'], 0, 'UChar')

        global currHotkeys := defaultHotkeys(localConfig, localControllers[0])
        global currController := -1
        global currButton := ''

        loopSleep := Round(localConfig['General']['AvgLoopSleep'] / 3)

        ; checks the controller status for hotkeys in currHotkeys
        checkButtons() {
            global

            ; time user needs to hold button to trigger hotkey function
            buttonTime := 80

            if (!currHotkeys.Has('uniqueKeys') || !currHotkeys.Has('hotkeys')) {
                return
            }

            for item in currHotkeys['uniqueKeys'] {
                status := xCheckAllControllers(localControllers, item,, true)
                if (status[1]) {
                    currController := status[2]
                    currButton := item

                    SetTimer 'ButtonTimer', (-1 * buttonTime)
                    while (xCheckController(localControllers[currController], currButton)) {
                        Sleep(5)
                    }
                    SetTimer 'ButtonTimer', 0
                }
            }
        }

        ; --- MAIN LOOP ---
        loop {
            updateStatus := !(currLoad = NumGet(localStatus['loadShow'], 0, 'UChar') && currError = NumGet(localStatus['errorShow'], 0, 'UChar') && currPause = NumGet(localStatus['pause'], 0, 'UChar') 
                            && currProgram = StrGet(localStatus['currProgram']) && currOverride = StrGet(localStatus['overrideProgram']))

            if (updateStatus) {
                currProgram  := StrGet(localStatus['currProgram'])
                currOverride := StrGet(localStatus['overrideProgram'])

                currPause    := NumGet(localStatus['pause'], 0, 'UChar')
                currLoad     := NumGet(localStatus['loadShow'], 0, 'UChar')
                currError    := NumGet(localStatus['errorShow'], 0, 'UChar')
                
                currHotkeys := defaultHotkeys(localConfig, localControllers[0]) 

                ; if error only enable closing error
                if (currError) {  
                    errorHotkeys := Map()
                    errorHotkeys['A|B'] := 'Exit'

                    errorHotkeys := addKeyListString(errorHotkeys)

                    currHotkeys := addHotkeys(currHotkeys, errorHotkeys, localControllers[0])
                }
    
                ; if loading only enable exit
                else if (currLoad) {                        
                    for key, value in currHotkeys {
                        if (value != 'Exit') {
                            currHotkeys.Delete(key)
                        }
                    }
                }
    
                ; if paused use pause hotkeys 
                else if (currPause) {    
                    ; TODO - create buttons
                }
    
                ; if in override use program hotkeys
                else if (currOverride != '') {    
                    currHotkeys := addHotkeys(currHotkeys, localRunning[currOverride].hotkeys, localControllers[0])
                }
    
                ; if in program use program hotkeys
                else if (currProgram != '') {
                    currHotkeys := addHotkeys(currHotkeys, localRunning[currProgram].hotkeys, localControllers[0])
                }             
            }

            ; only check buttons if script not suspended
            if (!NumGet(localStatus['suspendScript'], 0, 'UChar')) {
                checkButtons()
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

            ; hotkeyInfo[1] = hotkeys pressed | hotkeyInfo[2] = corresponding function
            hotkeyInfo := checkHotkeys(currButton, currHotkeys['hotkeys'], localControllers[currController])

            ; if invalid hotkey info -> ignore hotkey
            if (hotkeyInfo = -1) {
                return
            }

            ; check hardcoded defaults because theres really no better way to do this
            if (hotkeyInfo[2] = 'Pause') {
                if (NumGet(localStatus['pause'], 0, 'UChar')) {
                    ; TODO - close pause screen

                    MsgBox('im free')
                }
                else {
                    ; TODO - open pause screen

                    MsgBox('im paused')
                }

                NumPut('UChar', !NumGet(localStatus['pause'], 0, 'UChar'), localStatus['pause'])
            }
            else if (hotkeyInfo[2] = 'Exit') {
                if (NumGet(localStatus['errorShow'], 0, 'UChar')) {
                    CloseErrorMsg(NumGet(localStatus['errorWndw'], 0, 'UInt'))
                }

                else if (currProgram != '') {
                    localRunning[currProgram].exit()
                }

                ; if user holds button for a long time, kill everything
                SetTimer 'NuclearTimer', -3000
                while (currProgram = StrGet(localStatus['currProgram']) && xCheckController(localControllers[currController], hotkeyInfo[1])) {
                    Sleep(5)
                }
                SetTimer 'NuclearTimer', 0
            }

            ; otherwise just run function
            else {
                runFunction(hotkeyInfo[2])
            }

            ; wait for user to release buttons
            while (xCheckController(localControllers[currController], hotkeyInfo[1])) {
                Sleep(5)
            }

            return
        }

        NuclearTimer() {
            global

            killed := false
            if (!killed && NumGet(localStatus['errorShow'], 0, 'UChar')) {
                try {
                    errorPID := WinGetPID('ahk_id ' NumGet(localStatus['errorWndw'], 0, 'UInt'))
                    ProcessKill(errorPID)

                    killed := true
                }
            }

            if (!killed && currProgram != '') {
                ProcessKill(localRunning[currProgram].getPID())
                killed := true
            }

            ; TODO - gui notification that drastic measures have been taken

            if (!killed) {
                ProcessKill(WinGetPID(WinHidden(MAINNAME)))
            }

            return
        }

        "
    ))
}

; creates the thread to monitor which programs are running & updates mode appropriately
;  localConfig - mainConfig as gotten as a ComObject through ObjShare
;  localStatus - mainStatus as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that checks running programs
programThread(localConfig, localStatus, localPrograms, localRunning) {
    return ThreadObj(dynamicInclude
    (   
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\program.ahk

        setCurrentWinTitle('programThread')

        global localStatus   := cleanComMap(ObjShare(" localStatus "))
        global localConfig   := cleanComMap(ObjShare(" localConfig "))
        global localPrograms := cleanComMap(ObjShare(" localPrograms "))

        global localRunning  := ObjShare(" localRunning ")

        loopSleep   := localConfig['General']['AvgLoopSleep'] * 2
        checkErrors := localConfig['Programs'].Has('ErrorList') && localConfig['Programs']['ErrorList'] != ''

        loop {
            forceActivate   := localConfig['General']['ForceActivateWindow']
            currProgram     := StrGet(localStatus['currProgram'])
            overrideProgram := StrGet(localStatus['overrideProgram'])

            ; close if main is no running
            if (!WinHidden(MAINNAME)) {
                ExitApp()
            }

            ; infinite loop during suspention
            if (NumGet(localStatus['suspendScript'], 0, 'UChar')) {
                Sleep(loopSleep)
                continue
            }

            if (checkErrors) {
                resetTMM := A_TitleMatchMode

                SetTitleMatchMode 2
                for key in StrSplit(localConfig['Programs']['ErrorList']['keys'], ',') {

                    wndwHWND := WinShown(localConfig['Programs']['ErrorList'][key])
                    if (wndwHWND > 0) {
                        NumPut('UChar', true, localStatus['errorShow'])
                        NumPut('UInt', wndwHWND, localStatus['errorWndw'])
                    }
                }
                SetTitleMatchMode resetTMM
            }

            ; focus error window
            if (NumGet(localStatus['errorShow'], 0, 'UChar')) {
                errorWndw := NumGet(localStatus['errorWndw'], 0, 'UInt')

                if (WinShown('ahk_id ' errorWndw)) {
                    if (forceActivate && !WinActive('ahk_id ' errorWndw)) {
                        WinActivate('ahk_id ' errorWndw)
                    }
                }
                else {
                    NumPut('UChar', false, localStatus['errorShow'])
                    NumPut('UInt', 0, localStatus['errorWndw'])
                }
            }

            ; focus override program
            else if (overrideProgram != '') {

                ; need to create override program if doesn't exist
                if (!localRunning.Has(overrideProgram)) {
                    createProgram(overrideProgram, localStatus, localRunning, localPrograms,, false)
                }

                else {
                    if (localRunning[overrideProgram].exists()) {
                        if (forceActivate) {
                            localRunning[overrideProgram].restore()
                        }
                    }
                    else {
                        StrPut('', localStatus['overrideProgram'])
                        localRunning.Delete(overrideProgram)
                        addKeyListString(localRunning)
                    }
                }
            }

            ; activate load screen if its supposed to be shown
            else if (NumGet(localStatus['loadShow'], 0, 'UChar')) {
                ; TODO - load screen activate
            }

            ; current program is set
            else if (currProgram != '') {

                ; need to create current program if doesn't exist
                if (!localRunning.Has(currProgram)) {
                    createProgram(overrideProgram, localStatus, localRunning, localPrograms, false, false)
                } 

                else {
                    ; focus currProgram if it exists
                    if (localRunning[currProgram].exists()) {
                        if (forceActivate) {
                            localRunning[currProgram].restore()
                        }
                    }
                    else {
                        StrPut('', localStatus['currProgram'])
                        localRunning.Delete(currProgram)
                        addKeyListString(localRunning)

                        prevTime := 0
                        prevProgram := ''
                        for key in StrSplit(localRunning['keys'], ',') {
                            if (key != currProgram && localRunning[key].time > prevTime) {
                                prevProgram := key
                                prevTime := localRunning[key].time
                            }
                        }

                        ; restore previous program if open
                        if (prevProgram != '') {
                            StrPut(prevProgram, localStatus['currProgram'])
                        }

                        ; updates currProgram if a program exists, else create the default program if no prev program exists
                        else {
                            openProgram := checkAllPrograms(localPrograms)
                            if (openProgram != '') {
                                createProgram(openProgram, localStatus, localRunning, localPrograms, false)
                            }

                            else if (localConfig['Programs'].Has('Default') && localConfig['Programs']['Default'] != '') {
                                createProgram(localConfig['Programs']['Default'], localStatus, localRunning, localPrograms)
                            }
                        }
                    }
                }
            }

            ; no current program
            else {
                openProgram := checkAllPrograms(localPrograms)
                if (openProgram != '') {
                    createProgram(openProgram, localStatus, localRunning, localPrograms, false)
                }

                else if (localConfig['Programs'].Has('Default') && localConfig['Programs']['Default'] != '') {
                    createProgram(localConfig['Programs']['Default'], localStatus, localRunning, localPrograms)
                }
            }

            Sleep(loopSleep)
        }
        "
    ))
}

; creates the controller thread to check the input status of each connected controller
;  localControllers - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that checks controller statuses
controllerThread(localConfig, localControllers) {
    return ThreadObj(
    (
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\xinput.ahk   
        
        setCurrentWinTitle('controllerThread')
        
        global localConfig      := cleanComMap(ObjShare(" localConfig "))
        global localControllers := cleanComMap(ObjShare(" localControllers "))

        loopSleep := Round(localConfig['General']['AvgLoopSleep'] / 4)

        loop {
            for key in StrSplit(localControllers['keys'], ',') {
                localControllers[Integer(key)].update()
            }

            ; close if main is no running
            if (!WinHidden(MAINNAME)) {
                ExitApp()
            }

            Sleep(loopSleep)
        }
        "
    ))
}

; 

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