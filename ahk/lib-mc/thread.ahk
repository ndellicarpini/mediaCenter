; creates the thread that does actions based on current mainStatus & mainControllers
;  configShare - mainConfig as gotten as a ComObject through ObjShare
;  statusShare - mainStatus as gotten as a ComObject through ObjShare 
;  controllerShare - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that does x based on mainStatus
hotkeyThread(configShare, statusShare, controllerShare) {
    return ThreadObj(dynamicInclude
    (
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\xinput.ahk
        #Include lib-mc\hotkeys.ahk

        setCurrentWinTitle('hotkeyThread')

        ; --- GLOBAL VARIABLES ---
        ; variables are global to be accessed in timers
        global configShare     := ObjShare(" configShare ")
        global statusShare     := ObjShare(" statusShare ")
        global controllerShare := ObjShare(" controllerShare ")

        global currProgram := statusShare['currProgram']
        global currPause := statusShare['pause']

        global currHotkeys := defaultHotkeys(configShare, controllerShare[0])
        global currController := -1
        global currButton := ''

        loopSleep := Round(configShare['General']['AvgLoopSleep'] / 2)

        ; checks the controller status for hotkeys in currHotkeys
        checkButtons() {
            global

            ; time user needs to hold button to trigger hotkey function
            buttonTime := 80

            if (!currHotkeys.Has('uniqueKeys') || !currHotkeys.Has('hotkeys')) {
                return
            }

            for item in currHotkeys['uniqueKeys'] {
                status := xCheckAllControllers(controllerShare, item,, true)
                if (status[1]) {
                    currController := status[2]
                    currButton := item

                    SetTimer 'ButtonTimer', (-1 * buttonTime)
                    while (xCheckController(controllerShare[currController], currButton)) {
                        Sleep(5)
                    }
                    SetTimer 'ButtonTimer', 0
                }
            }
        }

        ; --- MAIN LOOP ---
        loop {
            ; if paused use pause hotkeys
            if (currPause != statusShare['pause']) {
                currPause := statusShare['pause']

                if (currPause) {
                    ; TODO - create buttons
                }
                else {
                    currHotkeys := defaultHotkeys(configShare, controllerShare[0]) 
                }
            }

            ; if in program use program hotkeys
            else if (currProgram != statusShare['currProgram']) {
                currProgram := statusShare['currProgram']

                if (currProgram != '') {
                    currHotkeys := addHotkeys(currHotkeys, statusShare['openPrograms'][currProgram].hotkeys, controllerShare[0])
                }
                else {
                    currHotkeys := defaultHotkeys(configShare, controllerShare[0])
                }
            }

            ; only check buttons if script not suspended
            if (!statusShare['suspendScript']) {
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
            hotkeyInfo := checkHotkeys(currButton, currHotkeys['hotkeys'], controllerShare[currController])

            ; if invalid hotkey info -> ignore hotkey
            if (hotkeyInfo = -1) {
                return
            }

            ; check hardcoded defaults because theres really no better way to do this
            if (hotkeyInfo[2] = 'Pause') {
                if (statusShare['pause']) {
                    ; TODO - close pause screen

                    MsgBox('im free')
                }
                else {
                    ; TODO - open pause screen

                    MsgBox('im paused')
                }

                statusShare['pause'] := !statusShare['pause']
            }
            else if (hotkeyInfo[2] = 'Exit') {
                if (currProgram != '') {
                    statusShare['openPrograms'][currProgram].exit()
                }

                ; if user holds button for a long time, kill everything
                SetTimer 'NuclearTimer', -3000
                while (currProgram = statusShare['currProgram'] && xCheckController(controllerShare[currController], hotkeyInfo[1])) {
                    Sleep(5)
                }
                SetTimer 'NuclearTimer', 0
            }

            ; otherwise just run function
            else {
                runFunction(hotkeyInfo[2])
            }

            ; wait for user to release buttons
            while (xCheckController(controllerShare[currController], hotkeyInfo[1])) {
                Sleep(5)
            }

            return
        }

        NuclearTimer() {
            global

            ProcessKill(statusShare['openPrograms'][currProgram].getPID())

            ; TODO - gui notification that drastic measures have been taken

            ProcessKill(WinGetPID(WinHidden(MAINNAME)))

            return
        }

        "
    ))
}

; creates the thread to monitor which programs are running & updates mode appropriately
;  configShare - mainConfig as gotten as a ComObject through ObjShare
;  statusShare - mainStatus as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that checks running programs
programThread(configShare, statusShare, programShare) {
    return ThreadObj(dynamicInclude
    (   
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\program.ahk

        setCurrentWinTitle('programThread')

        configShare  := ObjShare(" configShare ")
        statusShare  := ObjShare(" statusShare ")
        programShare := ObjShare(" programShare ")

        loopSleep := configShare['General']['AvgLoopSleep']

        loop {
            forceActivate   := configShare['General']['ForceActivateWindow']
            currProgram     := statusShare['currProgram']
            overrideProgram := statusShare['overrideProgram']

            ; close if main is no running
            if (!WinHidden(MAINNAME)) {
                ExitApp()
            }

            ; infinite loop during suspention
            if (statusShare['suspendScript']) {
                Sleep(loopSleep)
                continue
            }

            ; focus override program
            if (overrideProgram != '') {

                ; need to create override program if doesn't exist
                if (!statusShare['openPrograms'].Has(overrideProgram)) {
                    statusShare := createProgram(overrideProgram, statusShare, programShare,, false)
                }

                else {
                    if (statusShare['openPrograms'][overrideProgram].exists()) {
                        if (forceActivate) {
                            statusShare['openPrograms'][overrideProgram].restore()
                        }
                    }
                    else {
                        statusShare['overrideProgram'] := ''
                        statusShare['openPrograms'].Delete(overrideProgram)
                        statusShare['openPrograms'] := addKeyListString(statusShare['openPrograms'])
                    }
                }
            }

            ; activate load screen if its supposed to be shown
            else if (statusShare['load']['show']) {
                ; TODO - load screen activate
            }


            ; current program is set
            else if (currProgram != '') {

                ; need to create current program if doesn't exist
                if (!statusShare['openPrograms'].Has(currProgram)) {
                    statusShare := createProgram(overrideProgram, statusShare, programShare, false, false)
                } 

                else {
                    ; focus currProgram if it exists
                    if (statusShare['openPrograms'][currProgram].exists()) {
                        if (forceActivate) {
                            statusShare['openPrograms'][currProgram].restore()
                        }
                    }
                    else {
                        statusShare['currProgram'] := ''
                        statusShare['openPrograms'].Delete(currProgram)
                        statusShare['openPrograms'] := addKeyListString(statusShare['openPrograms'])

                        prevTime := 0
                        prevProgram := ''
                        for key in StrSplit(statusShare['openPrograms']['keys'], ',') {
                            if (key != currProgram && statusShare['openPrograms'][key].time > prevTime) {
                                prevProgram := key
                                prevTime := statusShare['openPrograms'][key].time
                            }
                        }

                        ; restore previous program if open
                        if (prevProgram != '') {
                            statusShare['currProgram'] := prevProgram
                        }

                        ; updates currProgram if a program exists, else create the default program if no prev program exists
                        else {
                            openProgram := checkAllPrograms(programShare)
                            if (openProgram != '') {
                                statusShare := createProgram(openProgram, statusShare, programShare, false)
                            }

                            else if (configShare['Programs'].Has('Default') && configShare['Programs']['Default'] != '') {
                                statusShare := createProgram(configShare['Programs']['Default'], statusShare, programShare)
                            }
                        }
                    }
                }
            }

            ; no current program
            else {
                openProgram := checkAllPrograms(programShare)
                if (openProgram != '') {
                    statusShare := createProgram(openProgram, statusShare, programShare, false)
                }

                else if (configShare['Programs'].Has('Default') && configShare['Programs']['Default'] != '') {
                    statusShare := createProgram(configShare['Programs']['Default'], statusShare, programShare)
                }
            }

            Sleep(loopSleep)
        }
        "
    ))
}

; creates the controller thread to check the input status of each connected controller
;  controllerShare - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that checks controller statuses
controllerThread(configShare, controllerShare) {
    return ThreadObj(
    (
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\xinput.ahk   
        
        setCurrentWinTitle('controllerThread')
        
        configShare     := ObjShare(" configShare ")
        controllerShare := ObjShare(" controllerShare ")

        loopSleep := Round(configShare['General']['AvgLoopSleep'] / 3)

        loop {
            for key in StrSplit(controllerShare['keys'], ',') {
                controllerShare[Integer(key)].update()
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