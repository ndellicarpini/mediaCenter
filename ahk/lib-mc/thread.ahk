; creates the thread that does actions based on current mainStatus & mainControllers
;  globalConfig - mainConfig as gotten as a ComObject through ObjShare
;  globalStatus - mainStatus as gotten as a ComObject through ObjShare 
;  globalControllers - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that does x based on mainStatus
hotkeyThread(globalConfig, globalStatus, globalControllers, globalRunning) {
    return ThreadObj(dynamicInclude
    (
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\xinput.ahk
        #Include lib-mc\hotkeys.ahk
        #Include lib-mc\gui\std.ahk

        setCurrentWinTitle('hotkeyThread')

        SetKeyDelay 80, 60

        ; --- GLOBAL VARIABLES ---
        ; time user needs to hold button to trigger hotkey function
        global buttonTime := 70

        ; variables are global to be accessed in timers
        global globalStatus      := cleanComMap(ObjShare(" globalStatus "))
        global globalConfig      := cleanComMap(ObjShare(" globalConfig "))
        global globalControllers := cleanComMap(ObjShare(" globalControllers "))

        global globalRunning     := ObjShare(" globalRunning ")

        parseGUIConfig(globalConfig['GUI'])

        global currProgram  := StrGet(globalStatus['currProgram'])
        global currOverride := StrGet(globalStatus['overrideProgram'])

        global currPause    := NumGet(globalStatus['pause'], 0, 'UChar')
        global currLoad     := NumGet(globalStatus['loadShow'], 0, 'UChar')
        global currError    := NumGet(globalStatus['errorShow'], 0, 'UChar')

        global currHotkeys := defaultHotkeys(globalConfig, globalControllers[0])
        global currController := -1
        global currButton := ''

        loopSleep := Round(globalConfig['General']['AvgLoopSleep'] / 4)

        ; checks the controller status for hotkeys in currHotkeys
        checkButtons() {
            global

            if (!currHotkeys.Has('uniqueKeys') || !currHotkeys.Has('hotkeys')) {
                return
            }

            for item in currHotkeys['uniqueKeys'] {
                status := xCheckAllControllers(globalControllers, item,, true)
                if (status[1]) {
                    currController := status[2]
                    currButton := item

                    SetTimer 'ButtonTimer', (-1 * buttonTime)
                    while (xCheckController(globalControllers[currController], currButton)) {
                        Sleep(5)
                    }
                    SetTimer 'ButtonTimer', 0
                }
            }
        }

        ; --- MAIN LOOP ---
        loop {
            updateStatus := !(currLoad = NumGet(globalStatus['loadShow'], 0, 'UChar') && currError = NumGet(globalStatus['errorShow'], 0, 'UChar') && currPause = NumGet(globalStatus['pause'], 0, 'UChar') 
                            && currProgram = StrGet(globalStatus['currProgram']) && currOverride = StrGet(globalStatus['overrideProgram']))

            if (updateStatus) {
                currProgram  := StrGet(globalStatus['currProgram'])
                currOverride := StrGet(globalStatus['overrideProgram'])

                currPause    := NumGet(globalStatus['pause'], 0, 'UChar')
                currLoad     := NumGet(globalStatus['loadShow'], 0, 'UChar')
                currError    := NumGet(globalStatus['errorShow'], 0, 'UChar')
                
                currHotkeys := defaultHotkeys(globalConfig, globalControllers[0]) 

                ; if error only enable closing error
                if (currError) {  
                    errorHotkeys := Map()
                    errorHotkeys['A|B'] := 'Exit'

                    errorHotkeys := addKeyListString(errorHotkeys)

                    currHotkeys := addHotkeys(currHotkeys, errorHotkeys, globalControllers[0])
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
                    currHotkeys := addHotkeys(currHotkeys, globalRunning[currOverride].hotkeys, globalControllers[0])
                }
    
                ; if in program use program hotkeys
                else if (currProgram != '') {
                    currHotkeys := addHotkeys(currHotkeys, globalRunning[currProgram].hotkeys, globalControllers[0])
                }             
            }

            ; only check buttons if script not suspended
            if (!NumGet(globalStatus['suspendScript'], 0, 'UChar')) {
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
            hotkeyInfo := checkHotkeys(currButton, currHotkeys['hotkeys'], globalControllers[currController])

            ; if invalid hotkey info -> ignore hotkey
            if (hotkeyInfo = -1) {
                return
            }

            ; check hardcoded defaults because theres really no better way to do this
            if (hotkeyInfo[2] = 'Pause') {
                if (NumGet(globalStatus['pause'], 0, 'UChar')) {
                    ; TODO - close pause screen
                    
                    if (getGUI(NumGet(globalStatus['errorHWND'], 0, 'UInt'))) {
                        getGUI(NumGet(globalStatus['errorHWND'], 0, 'UInt')).Destroy()
                    }
                }
                else {
                    ; TODO - open pause screen

                    guiMessage('PAUSE ME OOOO', 1000)
                }

                NumPut('UChar', !NumGet(globalStatus['pause'], 0, 'UChar'), globalStatus['pause'])
            }
            else if (hotkeyInfo[2] = 'Exit') {
                if (NumGet(globalStatus['errorShow'], 0, 'UChar')) {
                    errorHWND := NumGet(globalStatus['errorHWND'], 0, 'UInt')
                    errorGUI := getGUI(errorHWND)

                    if (errorGUI) {
                        errorGUI.Destroy()
                    }
                    else {
                        CloseErrorMsg(errorHWND)
                    }
                }

                else if (currProgram != '') {
                    globalRunning[currProgram].exit()
                }

                ; if user holds button for a long time, kill everything
                SetTimer 'NuclearTimer', -3000
                while (currProgram = StrGet(globalStatus['currProgram']) && xCheckController(globalControllers[currController], hotkeyInfo[1])) {
                    Sleep(5)
                }
                SetTimer 'NuclearTimer', 0
            }

            ; otherwise just run function
            else {
                runFunction(hotkeyInfo[2])
            }

            ; wait for user to release buttons
            while (xCheckController(globalControllers[currController], hotkeyInfo[1])) {
                Sleep(5)
            }

            return
        }

        NuclearTimer() {
            global

            killed := false
            if (!killed && NumGet(globalStatus['errorShow'], 0, 'UChar')) {
                try {
                    errorPID := WinGetPID('ahk_id ' NumGet(globalStatus['errorHWND'], 0, 'UInt'))
                    ProcessKill(errorPID)

                    killed := true
                }
            }

            if (!killed && currProgram != '') {
                ProcessKill(globalRunning[currProgram].getPID())
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
;  globalConfig - mainConfig as gotten as a ComObject through ObjShare
;  globalStatus - mainStatus as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that checks running programs
programThread(globalConfig, globalStatus, globalPrograms, globalRunning) {
    return ThreadObj(dynamicInclude
    (   
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\program.ahk
        #Include lib-mc\gui\std.ahk

        setCurrentWinTitle('programThread')

        global globalStatus   := cleanComMap(ObjShare(" globalStatus "))
        global globalConfig   := cleanComMap(ObjShare(" globalConfig "))
        global globalPrograms := cleanComMap(ObjShare(" globalPrograms "))

        global globalRunning  := ObjShare(" globalRunning ")

        loopSleep   := globalConfig['General']['AvgLoopSleep'] * 2
        checkErrors := globalConfig['Programs'].Has('ErrorList') && globalConfig['Programs']['ErrorList'] != ''

        loop {
            forceActivate   := globalConfig['General']['ForceActivateWindow']
            currProgram     := StrGet(globalStatus['currProgram'])
            overrideProgram := StrGet(globalStatus['overrideProgram'])

            guiMessageShown := WinShown(GUIMESSAGETITLE)

            ; close if main is no running
            if (!WinHidden(MAINNAME)) {
                ExitApp()
            }

            ; infinite loop during suspention
            if (NumGet(globalStatus['suspendScript'], 0, 'UChar')) {
                Sleep(loopSleep)
                continue
            }

            ; if gui message exists
            if (guiMessageShown) {
                NumPut('UChar', true, globalStatus['errorShow'])
                NumPut('UInt', guiMessageShown, globalStatus['errorHWND'])
            }

            ; if errors should be detected, set error here
            if (checkErrors) {
                resetTMM := A_TitleMatchMode

                SetTitleMatchMode 2
                for key in StrSplit(globalConfig['Programs']['ErrorList']['keys'], ',') {

                    wndwHWND := WinShown(globalConfig['Programs']['ErrorList'][key])
                    if (wndwHWND > 0) {
                        NumPut('UChar', true, globalStatus['errorShow'])
                        NumPut('UInt', wndwHWND, globalStatus['errorHWND'])
                    }
                }
                SetTitleMatchMode resetTMM
            }

            ; focus error window
            if (NumGet(globalStatus['errorShow'], 0, 'UChar')) {
                errorHWND := NumGet(globalStatus['errorHWND'], 0, 'UInt')

                if (WinShown('ahk_id ' errorHWND)) {
                    if (forceActivate && !WinActive('ahk_id ' errorHWND)) {
                        WinActivate('ahk_id ' errorHWND)
                    }
                }
                else {
                    NumPut('UChar', false, globalStatus['errorShow'])
                    NumPut('UInt', 0, globalStatus['errorHWND'])
                }
            }

            ; focus override program
            else if (overrideProgram != '') {

                ; need to create override program if doesn't exist
                if (!globalRunning.Has(overrideProgram)) {
                    createProgram(overrideProgram, globalStatus, globalRunning, globalPrograms,, false)
                }

                else {
                    if (globalRunning[overrideProgram].exists()) {
                        if (forceActivate) {
                            try globalRunning[overrideProgram].restore()
                        }
                    }
                    else {
                        StrPut('', globalStatus['overrideProgram'])
                        globalRunning.Delete(overrideProgram)
                        addKeyListString(globalRunning)
                    }
                }
            }

            ; activate load screen if its supposed to be shown
            else if (NumGet(globalStatus['loadShow'], 0, 'UChar')) {
                ; TODO - load screen activate
            }

            ; current program is set
            else if (currProgram != '') {

                ; need to create current program if doesn't exist
                if (!globalRunning.Has(currProgram)) {
                    createProgram(overrideProgram, globalStatus, globalRunning, globalPrograms, false, false)
                } 

                else {
                    ; focus currProgram if it exists
                    if (globalRunning[currProgram].exists()) {
                        if (forceActivate) {
                            try globalRunning[currProgram].restore()
                        }
                    }
                    else {
                        StrPut('', globalStatus['currProgram'])
                        globalRunning.Delete(currProgram)
                        addKeyListString(globalRunning)

                        prevTime := 0
                        prevProgram := ''
                        for key in StrSplit(globalRunning['keys'], ',') {
                            if (key != currProgram && globalRunning[key].time > prevTime) {
                                prevProgram := key
                                prevTime := globalRunning[key].time
                            }
                        }

                        ; restore previous program if open
                        if (prevProgram != '') {
                            StrPut(prevProgram, globalStatus['currProgram'])
                        }

                        ; updates currProgram if a program exists, else create the default program if no prev program exists
                        else {
                            openProgram := checkAllPrograms(globalPrograms)
                            if (openProgram != '') {
                                createProgram(openProgram, globalStatus, globalRunning, globalPrograms, false)
                            }

                            else if (globalConfig['Programs'].Has('Default') && globalConfig['Programs']['Default'] != '') {
                                createProgram(globalConfig['Programs']['Default'], globalStatus, globalRunning, globalPrograms)
                            }
                        }
                    }
                }
            }

            ; no current program
            else {
                openProgram := checkAllPrograms(globalPrograms)
                if (openProgram != '') {
                    createProgram(openProgram, globalStatus, globalRunning, globalPrograms, false)
                }

                else if (globalConfig['Programs'].Has('Default') && globalConfig['Programs']['Default'] != '') {
                    createProgram(globalConfig['Programs']['Default'], globalStatus, globalRunning, globalPrograms)
                }
            }

            Sleep(loopSleep)
        }
        "
    ))
}

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
        global globalControllers := cleanComMap(ObjShare(" globalControllers "))

        loopSleep := Round(globalConfig['General']['AvgLoopSleep'] / 5)

        loop {
            for key in StrSplit(globalControllers['keys'], ',') {
                globalControllers[Integer(key)].update()
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