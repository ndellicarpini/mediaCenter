; creates the thread to monitor which programs are running & updates mode appropriately
;  configShare - gConfig as gotten as a ComObject through ObjShare
;  statusShare - gStatus as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that checks running programs
programThread(configShare, statusShare) {
    return ThreadObj(
    (
        "
        #Include lib-mc\std.ahk

        configShare := ObjShare(" configShare ")
        statusShare := ObjShare(" statusShare ")

        loopSleep := configShare['General']['AvgLoopSleep']
        
        loop {
            for key in StrSplit(statusShare['keys'], ',') {
                
                ; check for status starting with curr (supposed to be programs to be checked if running)
                if (InStr(key, 'curr') && IsObject(statusShare[key])) {
                    configKey := StrReplace(key, 'curr')
                    
                    ; if program is running, set variable in curr[Status]
                    if (configShare.Has(configKey) && IsObject(configShare[configKey])) {
                        for key2 in StrSplit(configShare[configKey]['keys'], ',') {   
                            
                            if (statusShare[key].Has(key2)) {
                                statusShare[key][key2] := ProcessExist(configShare[configKey][key2]) ? configShare[configKey][key2] : ''
                            }
                        }
                    }

                    Sleep(loopSleep)

                    ; if there is list of type of program, use checkexe/wndwlist
                    if (configShare.Has('List' . configKey)) {
                        listKey := 'List' . configKey
                        
                        for key2 in StrSplit(configShare[listKey]['keys'], ',') {
                            listKeyArr := StrSplit(key2, '_')

                            if (statusShare[key].Has(listKeyArr[1])) {
                                if (StrLower(listKeyArr[2]) = 'exe') {
                                    statusShare[key][listKeyArr[1]] := checkEXEList(configShare[listKey][key2])
                                }
                                else if (StrLower(listKeyArr[2]) = 'wndw') {
                                    statusShare[key][listKeyArr[1]] := checkWNDWList(configShare[listKey][key2])
                                }
                            }
                        }                         
                    }
                }
            }

            ; mode switcher
            ; need to come up with a procedure for handling when multitasking is enabled

            if (!statusShare['modifier']['multi']) {
                if (statusShare['override'] != '') {
                    
                    ; check if program specified as override is still running, if not clear override
                    if (statusShare['currExecutables'][(statusShare['override'])] != '') {
                        statusShare['mode'] := statusShare['override']
                    }
                    else {
                        statusShare['override'] := ''
                    }
                }
                else {
                    for key in StrSplit(configShare['General']['PriorityOrder']['keys'], ',') {                        

                        ; set mode based on priority order
                        if (statusShare['currExecutables'][(configShare['General']['PriorityOrder'][key])] != '') {
                            if (key = 'Override') {
                                statusShare['override'] := configShare['General']['PriorityOrder'][key]
                            }

                            statusShare['mode'] := configShare['General']['PriorityOrder'][key]
                            break
                        }
                    }
                }
            }

            if (!mediaCenterRunning()) {
                ExitApp()
            }

            Sleep(loopSleep)
        }
        "
    ))
}

; creates the controller thread to check the input status of each connected controller
;  controllerShare - gControllers as gotten as a ComObject through ObjShare
;
; returns the ThreadObj that checks controller statuses
controllerThread(configShare, controllerShare) {
    return ThreadObj(
    (
        "
        #Include lib-mc\std.ahk
        #Include lib-mc\xinput.ahk
        
        configShare := ObjShare(" configShare ")
        controllerShare := ObjShare(" controllerShare ")

        loopSleep := configShare['General']['AvgLoopSleep'] / 3

        loop {
            for key in StrSplit(controllerShare['keys'], ',') {
                controllerShare[Integer(key)].update()
            }

            if (!mediaCenterRunning()) {
                ExitApp()
            }

            Sleep(loopSleep)
        }
        "
    ))
}

; closes all threads
;  threads - map of all current threads
;
; returns null
CloseAllThreads(threads) {
    for key, value in threads {
        try {
            value.ExitApp()
        }
        catch {
            continue
        }
    }
}