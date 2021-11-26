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
        configObj[key2] := value2
    }

    mainConfig[key] := configObj
}

; read executable folder & add to configs
if (mainConfig["General"].Has("ExeConfigDir") && mainConfig["General"]["ExeConfigDir"] != "") {
    loop files validateDir(mainConfig["General"]["ExeConfigDir"]) . "*", "FD" {
        
    }

    ; TESTING
    oof := readConfig("config\executables\chrome.json",, "json")
    oof.cleanAllItems()
    MsgBox(toString(oof))
    ExitApp()
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
localConfig      := ObjShare(ObjShare(mainConfig))
localStatus      := ObjShare(ObjShare(mainStatus))
localControllers := ObjShare(ObjShare(mainControllers))

threads := Map()

; ----- START CONTROLLER THEAD -----
; this thread just updates the status of each controller in a loop
threads["controllerThread"] := controllerThread(ObjShare(mainConfig), ObjShare(mainControllers))

; ----- BOOT -----
if (localConfig["Boot"]["EnableBoot"]) {
    %localConfig["Boot"]["StartBoot"]%(localConfig)
}

; ----- START PROGRAM ----- 
; this thread updates the status mode based on checking running programs
threads["programThread"] := programThread(ObjShare(mainConfig), ObjShare(mainStatus))

; ----- START ACTION -----
; this thread reads controller & status to determine what actions needing to be taken
; (ie. if currExecutable-Game = retroarch & Home+Start -> Save State)
threads["hotkeyThread"] := hotkeyThread(ObjShare(mainConfig), ObjShare(mainStatus), ObjShare(mainControllers))

; ----- ENABLE LISTENER -----
enableMainMessageListener()

; ----- MAIN THREAD LOOP -----
; the main thread monitors the other threads, checks that looper is running
; the main thread launches programs with appropriate settings and does any non-hotkey looping actions in the background
; probably going to need to figure out updating loadscreen?
loopSleep := localConfig["General"]["AvgLoopSleep"] * 3
loop {
    ;perform actions based on mode & main message

    if (mainMessage != []) {
        ; do something based on main message (like launching app)
        mainMessage := []
    }

    ; need to check that threads are running - currently no way to do this without there being a debug print

    ; check looper
    if (localConfig["General"]["ForceMaintainMain"] && !localStatus["suspendScript"] && !WinHidden(MAINLOOP)) {
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