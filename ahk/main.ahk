#SingleInstance Force
#WarnContinuableException Off

#Include lib-mc\confio.ahk
#Include lib-mc\thread.ahk
#Include lib-mc\display.ahk
#Include lib-mc\std.ahk
#Include lib-mc\xinput.ahk
#Include lib-mc\messaging.ahk

; might need to figure out dynamic includes uhhhhhh yut oh
setCurrentWinTitle("MediaCenterMain")
enableMainMessageListener()

; ----- READ GLOBAL CONFIG -----
globalConfig := readGlobalConfig()

threads := Map()
gConfig := Map()
gStatus := Map()

gStatus["paused"] := false
gStatus["mode"] := ""
gStatus["override"] := ""

gStatus["modifier"] := Map()
gStatus["modifier"]["multi"] := false

gStatus["suspendScript"] := false

for key, value in globalConfig.subConfigs {
    configObj := Map()
    statusObj := Map()
    
    if (key = "Monitor") {
        temp := getDisplaySize(globalConfig.subConfigs["Display"])
        configObj["MonitorW"] := temp[1]
        configObj["MonitorH"] := temp[2]
        
        continue
    }

    for key2, value2, in value.items {
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

    gConfig[key] := configObj

    ; check if executables in list are running
    if (InStr(key, "Executables")) {
        gStatus[("curr" . key)] := statusObj
    }
}

; adds lists to currExecutables
if (gStatus.Has("currExecutables") && gConfig.Has("ListExecutables")) {
    for key, value in gConfig["ListExecutables"] {
        gStatus["currExecutables"][(StrSplit(key, "_")[1])] := ""
    }
}

; pre running program thread intialize xinput
xLib := xLoadLib(gConfig["General"]["XInputDLL"])
gControllers := xInitialize(xLib, gConfig["General"]["MaxXInputControllers"])

; adds the list of keys to the map as a string so that the map can be enumerated
; despite being a ComObject in the threads
gConfig := addKeyListString(gConfig)
gStatus := addKeyListString(gStatus)
gControllers := addKeyListString(gControllers)

; ----- START THREADS & BOOT -----
threads["controllerThread"] := controllerThread(ObjShare(gConfig), ObjShare(gControllers))

; after xinput run boot script

; create check running program thread
threads["programThread"] := programThread(ObjShare(gConfig), ObjShare(gStatus))

Sleep(30000)

disableMainMessageListener()
xFreeLib(xLib)
CloseAllThreads(threads)

Sleep(500)
ExitApp()