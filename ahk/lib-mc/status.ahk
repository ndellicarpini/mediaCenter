; activates the window only if the window is not active
;  window - window to activate based on WinTitle
;
; returns null
WinCheckActivate(window, mainConfig, type := "") {
    ; check status if minimized

    ; after restored, if force window activate on -> clean activate
    

}

; minimizes the window
;  window - window to minimize based on WinTitle
;
; returns null
WinCheckMinimize(window, mainConfig, type := "") {

}

; finds a function from an executable name
;  mainConfig - configuration of main
;  type - the executable type to be checked (Home, Browser, Game, etc)
;  funcName - the name of the function to be checked
;
; returns full name of function to be called
getExecFunction(mainConfig, type, funcName) {
    for key in StrSplit(mainConfig['keys']) {
        if (InStr(key, "executable", false)) {
            if (InStr(mainConfig[key]['keys'], type . "_" . funcName, true)) {
                return mainConfig[key][type . "_" . funcName]
            }
        }
    }

    return ""
}


; updates the mode & activates the appropriate window if appropriate
;  mainConfig - configuration of main
;  mainStatus - current status of main
;
; return null
updateMode(mainConfig, mainStatus) {
    for key in StrSplit(mainConfig['General']['PriorityOrder']['keys'], ',') {   
        currKey := mainConfig['General']['PriorityOrder'][key]                  
        currExec := mainStatus['currExecutables'][currKey]

        ; set mode based on priority order
        if (currExec != '') {

            ; if override 
            if (InStr(currKey, 'Override')) {
                mainStatus['override'] := currExec
            }

            mainStatus['mode'] := currKey
            WinCheckActivate(currExec, mainConfig, currKey)

            break
        }
    }
}