#SingleInstance Force
#WarnContinuableException Off

; ----- DO NOT EDIT: DYNAMIC INCLUDE START -----
#Include lib-custom\boot.ahk
#Include lib-custom\browser.ahk
#Include lib-custom\games.ahk
#Include lib-custom\loadscreen.ahk
#Include lib-custom\pausescreen.ahk
; ----- DO NOT EDIT: DYNAMIC INCLUDE END   -----
; TODO - NEED TO SETUP WAY TO TURN THESE INCLUDES INTO A VARIABLE &
;        APPLY IT TO THREADS

#Include lib-mc\confio.ahk
#Include lib-mc\thread.ahk
#Include lib-mc\display.ahk
#Include lib-mc\std.ahk
#Include lib-mc\xinput.ahk
#Include lib-mc\messaging.ahk

setCurrentWinTitle("MediaCenterMain")

global mainMessage := []
enableMainMessageListener()

; ----- READ GLOBAL CONFIG -----
globalConfig := readGlobalConfig()

threads := Map()
mainConfig := Map()
mainStatus := Map()

; initialize basic status features
; TODO - ensure pause screen shows the correct options based on mode?
; (maybe pull exec from mode -> currExecutables)
mainStatus["suspendScript"] := false
mainStatus["pause"] := false

mainStatus["mode"]     := ""
mainStatus["override"] := ""

mainStatus["load"] := Map()
mainStatus["load"]["show"] := false
mainStatus["load"]["text"] := "Now Loading..."

; setup status and config as maps rather than config objects for multithreading
for key, value in globalConfig.subConfigs {
    configObj := Map()
    statusObj := Map()
    
    ; if getting monitor config -> convert to monitorH and monitorW
    if (key = "Display") {
        temp := getDisplaySize(globalConfig.subConfigs["Display"])
        configObj["MonitorW"] := temp[1]
        configObj["MonitorH"] := temp[2]

        mainConfig[key] := configObj
        continue
    }
    
    ; for each subconfig (not monitor), convert to appropriate config & status objects
    for key2, value2, in value.items {
        
        ; check if subconfig is called ListX, if so read each value as a file
        if (InStr(key, "List")
        && InStr(key2, "_EXE", true) || InStr(key2, "_WNDW", true)) {
            if (IsObject(value2)) {
                tempMap := Map()
                for item in value2 {
                    tempItem := readConfig(item, "").items
                    
                    for execString, blank in tempItem {
                        tempMap[execString] := blank
                    }
                }

                configObj[key2] := tempMap
            }
            else {
                configObj[key2] := readConfig(value2, "").items
            }
        }
        else {
            configObj[key2] := value2
        }

        if (InStr(key, "executables", false) 
        && (InStr(key2, "_EXE", false) || InStr(key2, "_WNDW", false))) {
            
            statusObj[(StrSplit(key2, "_")[1])] := ""
        }
    }

    mainConfig[key] := configObj

    ; add any items from config are considered executables to status
    if (InStr(key, "executables", false)) {
        
        currKey := key
        if (InStr(key, "list", false)) {
            currKey := StrReplace(key, "list",, false)
        }

        if (mainStatus.Has("curr" . currKey)) {
            for key2, value2 in statusObj {
                mainStatus["curr" . currKey][key2] := value2
            }
        }
        else {
            mainStatus[("curr" . key)] := statusObj
        }
    }
}

; pre running program thread intialize xinput
xLib := xLoadLib(mainConfig["General"]["XInputDLL"])
mainControllers := xInitialize(xLib, mainConfig["General"]["MaxXInputControllers"])

; adds the list of keys to the map as a string so that the map can be enumerated
; despite being a ComObject in the threads
mainConfig      := addKeyListString(mainConfig)
mainStatus      := addKeyListString(mainStatus)
mainControllers := addKeyListString(mainControllers)

; ----- START CONTROLLER THEAD -----
threads["controllerThread"] := controllerThread(ObjShare(mainConfig), ObjShare(mainControllers))

; ----- START PROGRAM -----
threads["programThread"] := programThread(ObjShare(mainConfig), ObjShare(mainStatus))
; threads["loopThread"] := "check for loop program running"

; Sleep(30000)

; loop {
;     ;perform actions based on mode & main message

;     if (mainMessage != []) {
;         ; do something based on main message
;         mainMessage := []
;     }

;     MsgBox(mainControllers[0].A)

;     ; need sleep in order to 
;     Sleep(mainConfig["General"]["AvgLoopSleep"])
; }

Sleep(10000)

disableMainMessageListener()
CloseAllThreads(threads)
xFreeLib(xLib)

Sleep(100)
ExitApp()