; creates the thread that does actions based on current mainStatus & mainControllers
;  localConfig - mainConfig as gotten as a ComObject through ObjShare
;  localStatus - mainStatus as gotten as a ComObject through ObjShare 
;  localControllers - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that does x based on mainStatus
hotkeyThread(localConfig, localStatus, localControllers) {
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
        global localStatus      := ObjShare(" localStatus ")
        global localConfig      := cleanComMap(ObjShare(" localConfig "))
        global localControllers := cleanComMap(ObjShare(" localControllers "))

        global currProgram  := localStatus['currProgram']
        global currOverride := localStatus['overrideProgram']

        global currPause    := localStatus['pause']
        global currLoad     := localStatus['load']['show']
        global currError    := localStatus['error']['show']

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
            updateStatus := !(currLoad = localStatus['load']['show'] && currError = localStatus['error']['show'] && currPause = localStatus['pause'] 
                            && currProgram = localStatus['currProgram'] && currOverride = localStatus['overrideProgram'])

            if (updateStatus) {
                currProgram  := localStatus['currProgram']
                currOverride := localStatus['overrideProgram']

                currPause    := localStatus['pause']
                currLoad     := localStatus['load']['show']
                currError    := localStatus['error']['show']
                
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
                    currHotkeys := addHotkeys(currHotkeys, localStatus['openPrograms'][currOverride].hotkeys, localControllers[0])
                }
    
                ; if in program use program hotkeys
                else if (currProgram != '') {
                    currHotkeys := addHotkeys(currHotkeys, localStatus['openPrograms'][currProgram].hotkeys, localControllers[0])
                }             
            }

            ; only check buttons if script not suspended
            if (!localStatus['suspendScript']) {
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
                if (localStatus['pause']) {
                    ; TODO - close pause screen

                    MsgBox('im free')
                }
                else {
                    ; TODO - open pause screen

                    MsgBox('im paused')
                }

                localStatus['pause'] := !localStatus['pause']
            }
            else if (hotkeyInfo[2] = 'Exit') {
                if (localStatus['error']['show']) {
                    CloseErrorMsg(localStatus['error']['wndw'])
                }

                else if (currProgram != '') {
                    localStatus['openPrograms'][currProgram].exit()
                }

                ; if user holds button for a long time, kill everything
                SetTimer 'NuclearTimer', -3000
                while (currProgram = localStatus['currProgram'] && xCheckController(localControllers[currController], hotkeyInfo[1])) {
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
            if (!killed && localStatus['error']['show']) {
                try {
                    errorPID := WinGetPID('ahk_id ' localStatus['error']['wndw'])
                    ProcessKill(errorPID)

                    killed := true
                }
            }

            if (!killed && currProgram != '') {
                ProcessKill(localStatus['openPrograms'][currProgram].getPID())
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
programThread(localConfig, localStatus, localPrograms) {
    return ThreadObj(dynamicInclude
    (   
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\program.ahk

        setCurrentWinTitle('programThread')

        global localStatus     := ObjShare(" localStatus ")
        global localConfig     := cleanComMap(ObjShare(" localConfig "))
        global localPrograms    := cleanComMap(ObjShare(" localPrograms "))

        loopSleep   := localConfig['General']['AvgLoopSleep']
        checkErrors := localConfig['Programs'].Has('ErrorList') && localConfig['Programs']['ErrorList'] != ''

        loop {
            forceActivate   := localConfig['General']['ForceActivateWindow']
            currProgram     := localStatus['currProgram']
            overrideProgram := localStatus['overrideProgram']

            ; infinite loop during suspention
            if (localStatus['suspendScript']) {
                Sleep(loopSleep)
                continue
            }

            if (checkErrors) {
                resetTMM := A_TitleMatchMode

                SetTitleMatchMode 2
                for key in StrSplit(localConfig['Programs']['ErrorList']['keys'], ',') {

                    wndwHWND := WinShown(localConfig['Programs']['ErrorList'][key])
                    if (wndwHWND > 0) {
                        localStatus['error']['show'] := true
                        localStatus['error']['wndw'] := wndwHWND
                    }
                }
                SetTitleMatchMode resetTMM
            }

            ; focus error window
            if (localStatus['error']['show']) {
                if (WinShown('ahk_id ' localStatus['error']['wndw'])) {
                    if (forceActivate && !WinActive('ahk_id ' localStatus['error']['wndw'])) {
                        WinActivate('ahk_id ' localStatus['error']['wndw'])
                    }
                }
                else {
                    localStatus['error']['show'] := false
                    localStatus['error']['wndw'] := 0
                }
            }

            ; focus override program
            else if (overrideProgram != '') {

                ; need to create override program if doesn't exist
                if (!localStatus['openPrograms'].Has(overrideProgram)) {
                    createProgram(overrideProgram, localStatus, localPrograms,, false)
                }

                else {
                    if (localStatus['openPrograms'][overrideProgram].exists()) {
                        if (forceActivate) {
                            localStatus['openPrograms'][overrideProgram].restore()
                        }
                    }
                    else {
                        localStatus['overrideProgram'] := ''
                        localStatus['openPrograms'].Delete(overrideProgram)
                        localStatus['openPrograms'] := addKeyListString(localStatus['openPrograms'])
                    }
                }
            }

            ; activate load screen if its supposed to be shown
            else if (localStatus['load']['show']) {
                ; TODO - load screen activate
            }

            ; current program is set
            else if (currProgram != '') {

                ; need to create current program if doesn't exist
                if (!localStatus['openPrograms'].Has(currProgram)) {
                    createProgram(overrideProgram, localStatus, localPrograms, false, false)
                } 

                else {
                    ; focus currProgram if it exists
                    if (localStatus['openPrograms'][currProgram].exists()) {
                        if (forceActivate) {
                            localStatus['openPrograms'][currProgram].restore()
                        }
                    }
                    else {
                        localStatus['currProgram'] := ''
                        localStatus['openPrograms'].Delete(currProgram)
                        localStatus['openPrograms'] := addKeyListString(localStatus['openPrograms'])

                        prevTime := 0
                        prevProgram := ''
                        for key in StrSplit(localStatus['openPrograms']['keys'], ',') {
                            if (key != currProgram && localStatus['openPrograms'][key].time > prevTime) {
                                prevProgram := key
                                prevTime := localStatus['openPrograms'][key].time
                            }
                        }

                        ; restore previous program if open
                        if (prevProgram != '') {
                            localStatus['currProgram'] := prevProgram
                        }

                        ; updates currProgram if a program exists, else create the default program if no prev program exists
                        else {
                            openProgram := checkAllPrograms(localPrograms)
                            if (openProgram != '') {
                                createProgram(openProgram, localStatus, localPrograms, false)
                            }

                            else if (localConfig['Programs'].Has('Default') && localConfig['Programs']['Default'] != '') {
                                createProgram(localConfig['Programs']['Default'], localStatus, localPrograms)
                            }
                        }
                    }
                }
            }

            ; no current program
            else {
                openProgram := checkAllPrograms(localPrograms)
                if (openProgram != '') {
                    createProgram(openProgram, localStatus, localPrograms, false)
                }

                else if (localConfig['Programs'].Has('Default') && localConfig['Programs']['Default'] != '') {
                    createProgram(localConfig['Programs']['Default'], localStatus, localPrograms)
                }
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
        
        global localConfig     := cleanComMap(ObjShare(" localConfig "))
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