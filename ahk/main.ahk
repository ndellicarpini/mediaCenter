#SingleInstance Force
#WarnContinuableException Off

; ----- DYNAMIC INCLUDE START -----
#Include lib-custom\boot.ahk
#Include lib-custom\loadscreen.ahk
#Include lib-custom\pause.ahk
; -----  DYNAMIC INCLUDE END  -----

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

mainStatus["paused"] := false
mainStatus["mode"] := ""
mainStatus["override"] := ""

mainStatus["modifier"] := Map()
mainStatus["modifier"]["multi"] := false

mainStatus["suspendScript"] := false

; setup status and config 
for key, value in globalConfig.subConfigs {
    configObj := Map()
    statusObj := Map()
    
    ; if getting monitor config -> convert to monitorH and monitorW
    if (key = "Monitor") {
        temp := getDisplaySize(globalConfig.subConfigs["Display"])
        configObj["MonitorW"] := temp[1]
        configObj["MonitorH"] := temp[2]
        
        continue
    }

    ; for each subconfig (not monitor), convert to appropriate config & status objects
    for key2, value2, in value.items {
        
        ; check if subconfig is called ListX, if so read each value as a file
        if (InStr(key, "List")) {
            if (IsObject(value2)) {
                tempMap := Map()
                for item in value2 {
                    tempItem := readConfig(item, "").items
                    
                    for key4, value4 in tempItem {
                        tempMap[key4] := value4
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
        
            if (InStr(key, "Executables") && !InStr(key2, "Dir")) {
                statusObj[key2] := ""
            }
        }
    }

    mainConfig[key] := configObj

    ; check if executables in list are running
    if (InStr(key, "Executables") && !InStr(key, "List")) {
        mainStatus[("curr" . key)] := statusObj
    }
}

; adds ListX to currX status where X is the same
for key, value in mainConfig {
    if (InStr(key, "List") && Type(mainConfig[key]) = "Map" 
    && mainStatus.Has("curr" . StrReplace(key, "List"))) {
        for key2, value2 in mainConfig[key] {
            mainStatus["curr" . StrReplace(key, "List")][(StrSplit(key2, "_")[1])] := ""
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

cuntfig := readMultiCfg("config\consoles.mcfg", ["Arcade", "Playstation 3"])
MsgBox(cuntfig.subConfigs["Playstation 3"].items["dir"])

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