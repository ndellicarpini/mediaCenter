; creates the thread that does actions based on current mainStatus & mainControllers
;  configShare - mainConfig as gotten as a ComObject through ObjShare
;  statusShare - mainStatus as gotten as a ComObject through ObjShare 
;  controllerShare - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that does x based on mainStatus
hotkeyThread(configShare, statusShare, controllerShare) {
    ; TODO - new "current exe" using last launched exe (based on time) rather than priority

    return ThreadObj(dynamicInclude
    (
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\xinput.ahk

        ; --- GLOBAL VARIABLES ---
        ; variables are global to be accessed in timers
        global configShare     := ObjShare(" configShare ")
        global statusShare     := ObjShare(" statusShare ")
        global controllerShare := ObjShare(" controllerShare ")

        global homeButtonStatus := []

        global loopSleep := configShare['General']['AvgLoopSleep'] / 2

        ; --- MAIN LOOP ---
        loop {
            if (!statusShare['suspendScript']) {
                
                ; check home button (TODO - CHANGE TO HOME INSTEAD OF A)
                homeButtonStatus := xCheckAllControllers(controllerShare,, true, 'A')
                
                if (homeButtonStatus[1]) {
                    SetTimer 'HomeButtonTimer', (-1.2 * configShare['General']['AvgLoopSleep'])
                    while (controllerShare[homeButtonStatus[2]].A) {
                        Sleep(loopSleep / 4)
                    }
                    SetTimer 'HomeButtonTimer', 0
                }
                
            }

            ; close if main is no running
            if (!WinHidden(MAINNAME)) {
                ExitApp()
            }

            Sleep(loopSleep)
        }

        ; --- TIMERS ---
        HomeButtonTimer() {
            if (xCheckController(controllerShare[homeButtonStatus[2]],, 'RT')) {
                MsgBox('RT too')
            }
            else if (xCheckController(controllerShare[homeButtonStatus[2]],, 'LT')) {
                MsgBox('LT deez nuts')
            }
            else {
                activatePauseScreen()
            }
        }
        "
    ))
}

; creates the thread to monitor which programs are running & updates mode appropriately
;  configShare - mainConfig as gotten as a ComObject through ObjShare
;  statusShare - mainStatus as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that checks running programs
programThread(configShare, statusShare) {
    return ThreadObj(dynamicInclude
    (   
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\status.ahk

        configShare := ObjShare(" configShare ")
        statusShare := ObjShare(" statusShare ")

        loopSleep := configShare['General']['AvgLoopSleep']

        execMaps := Map()
        for key in StrSplit(configShare['keys'], ',') {
            if (InStr(key, 'executable', false) && Type(configShare[key] = 'Map')) {
                tempMap := Map()

                for key2 in StrSplit(configShare[key]['keys'], ',') {
                    if (InStr(key2, '_exe', false) || InStr(key2, '_wndw', false)) {
                        tempMap[key2] := configShare[key][key2]
                    }
                }

                execMaps[key] := tempMap
            }
        }
    
        loop {
            if (!statusShare['suspendScript']) {

                ; check which programs are running based on values taken from global.txt
                for key, value in execMaps {
                    isList := false
                    currKey := key
                    
                    if (InStr(key, 'list', false)) {
                        isList := true
                        currKey := StrReplace(key, 'list',, false)
                    }
    
                    if (isList) {
                        for key2, value2 in value {
                            if (InStr(key2, '_EXE', true)) {
                                statusShare['curr' . currKey][(StrSplit(key2, '_')[1])] := checkEXEList(value2)
                            }
                            else if (InStr(key2, '_WNDW', true)) {
                                statusShare['curr' . currKey][(StrSplit(key2, '_')[1])] := checkWNDWList(value2)
                            }
                        }
                    }
                    else {
                        for key2, value2 in value {
                            if (InStr(key2, '_EXE', true)) {
                                statusShare['curr' . currKey][(StrSplit(key2, '_')[1])] := ProcessExist(value2) ? value2 : ''
                            }
                            else if (InStr(key2, '_WNDW', true)) {
                                statusShare['curr' . currKey][(StrSplit(key2, '_')[1])] := WinShown(value2) ? value2 : ''
                            }
                        }
                    }                
                }
    
                ; switch the mode based on running programs
                if (statusShare['override'] != '') {
                    ; check if program specified as override is still running, if not clear override
                    if (statusShare['currExecutables'][(statusShare['override'])] != '') {
                        WinCheckActivate(statusShare['currExecutables'][(statusShare['override'])], configShare, statusShare['override'])
                    }
                    else {
                        statusShare['override'] := ''
                    }
                }
                else {
                    if (statusShare['load']['show']) {
                        %configShare['LoadScreen']['Update']%(statusShare['load']['text'], configShare['General']['ForceActivateWindow'])
                    }
                    else if (statusShare['pause']) {
                        ; check if pause screen exist 
                        if (configShare['General']['ForceActivateWindow'] && %configShare['PauseScreen']['Exist']%()) {
                            %configShare['PauseScreen']['Activate']%()
                        }
                        else {
                            statusShare['pause'] := false
                        }
                    }
                    else {
                        updateMode(configShare, statusShare)
                    }
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
;  controllerShare - mainControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that checks controller statuses
controllerThread(configShare, controllerShare) {
    return ThreadObj(
    (
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\xinput.ahk        
        
        configShare     := ObjShare(" configShare ")
        controllerShare := ObjShare(" controllerShare ")

        loopSleep := configShare['General']['AvgLoopSleep'] / 3

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