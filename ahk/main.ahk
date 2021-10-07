#SingleInstance Force
#WarnContinuableException Off

; ----- DO NOT EDIT: DYNAMIC INCLUDE START -----
#Include lib-custom\boot.ahk
#Include lib-custom\browser.ahk
#Include lib-custom\games.ahk
#Include lib-custom\loadscreen.ahk
#Include lib-custom\pausescreen.ahk
#Include lib-custom\emulators\retroarch.ahk
; ----- DO NOT EDIT: DYNAMIC INCLUDE END   -----

#Include lib-mc\confio.ahk
#Include lib-mc\thread.ahk
#Include lib-mc\display.ahk
#Include lib-mc\std.ahk
#Include lib-mc\xinput.ahk
#Include lib-mc\messaging.ahk

setCurrentWinTitle(MAINNAME)

global dynamicInclude := getDynamicIncludes(A_ScriptFullPath)
global mainMessage := []

; ----- READ GLOBAL CONFIG -----
mainConfig := Map()
mainStatus := Map()

globalConfig := readGlobalConfig()

; initialize startup arguments
mainConfig["StartArgs"] := A_Args

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

; configure objects to be used in a thread-safe manner
shareConfig      := ObjShare(ObjShare(mainConfig))
shareStatus      := ObjShare(ObjShare(mainStatus))
shareControllers := ObjShare(ObjShare(mainControllers))

threads := Map()

; ----- START CONTROLLER THEAD -----
; this thread just updates the status of each controller in a loop
threads["controllerThread"] := controllerThread(ObjShare(mainConfig), ObjShare(mainControllers))

; ----- BOOT -----
if (shareConfig["Boot"]["EnableBoot"]) {
    %shareConfig["Boot"]["StartBoot"]%(shareConfig)
}

; ----- START PROGRAM ----- 
; this thread updates the status mode based on checking running programs
threads["programThread"] := programThread(ObjShare(mainConfig), ObjShare(mainStatus))

; ----- START ACTION -----
; this thread reads controller & status to determine what actions needing to be taken
; (ie. if currExecutable-Game = retroarch & Home+Start -> Save State)
; threads["actionThread"] := actionThread()

; ----- ENABLE LISTENER -----
enableMainMessageListener()

; ----- MAIN THREAD LOOP -----
loopSleep := shareConfig["General"]["AvgLoopSleep"] * 3
loop {
    ;perform actions based on mode & main message

    if (mainMessage != []) {
        ; do something based on main message
        mainMessage := []
    }

    if (shareControllers[0].A) {
        shareStatus["suspendScript"] := shareStatus["suspendScript"] ? false : true

        while(shareControllers[0].A) {
            Sleep(10)
        }
    }

    ; need to check that threads are running - currently no way to do this without there being a debug print

    ; check looper
    if (shareConfig["General"]["ForceMaintainMain"] && !shareStatus["suspendScript"] && !WinHidden(MAINLOOP)) {
        Run A_AhkPath . " " . "mainLooper.ahk", A_ScriptDir, "Hide"
    }

    ; need sleep in order to 
    Sleep(loopSleep)
}

disableMainMessageListener()
closeAllThreads(threads)
xFreeLib(xLib)

Sleep(100)
ExitApp()