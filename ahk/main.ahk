#SingleInstance Force
#WarnContinuableException Off

; ----- DO NOT EDIT: DYNAMIC INCLUDE START -----
#Include lib-custom\boot.ahk
#Include lib-custom\browser.ahk
#Include lib-custom\games.ahk
#Include lib-custom\loadscreen.ahk
#Include lib-custom\pausescreen.ahk
; ----- DO NOT EDIT: DYNAMIC INCLUDE END   -----

#Include lib-mc\confio.ahk
#Include lib-mc\thread.ahk
#Include lib-mc\display.ahk
#Include lib-mc\std.ahk
#Include lib-mc\xinput.ahk
#Include lib-mc\messaging.ahk
#Include lib-mc\executable.ahk

setCurrentWinTitle(MAINNAME)

global dynamicInclude := getDynamicIncludes(A_ScriptFullPath)
global mainMessage := []

; ----- READ GLOBAL CONFIG -----
mainConfig      := Map()
mainStatus      := Map()

; TODO - CURRENT & OPEN EXECUTABLE SET
mainExecutables := Map()

globalConfig := readGlobalConfig()

; initialize startup arguments
mainConfig["StartArgs"] := A_Args

; initialize basic status features

; whether or not pause screen is shown 
mainStatus["pause"] := false
; whether or not script is suspended (no actions running, changable in pause menu)
mainStatus["suspendScript"] := false

; current name of executable focused & running, used to get config -> setup hotkeys & background actions
mainStatus["currEXE"]  := ""
; map of current executables running & what times they were launched -> used to determine fallback on close
; ROW | ID: name, EXE: exe, TIME: Unix launched, 
mainStatus["openEXE"] := Map()
; name of executable overriding the openEXE map -> kept separate for quick actions that should override
; all status, but retain current exe stack on close (like checking manual in chrome)
mainStatus["override"] := ""

; load screen info
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
    loop files validateDir(mainConfig["General"]["ExeConfigDir"]) . "*", "FR" {
        tempConfig := readConfig(A_LoopFileFullPath,, "json")
        tempConfig.cleanAllItems(true)

        mainExecutables[tempConfig.items["name"]] := tempConfig
    }

    MsgBox(toString(mainStatus))
    MsgBox(toString(mainExecutables))
    ExitApp()
}

; pre running program thread intialize xinput
xLib := xLoadLib(mainConfig["General"]["XInputDLL"])
mainControllers := xInitialize(xLib, mainConfig["General"]["MaxXInputControllers"])

; adds the list of keys to the map as a string so that the map can be enumerated
; despite being a ComObject in the threads
mainConfig       := addKeyListString(mainConfig)
mainStatus       := addKeyListString(mainStatus)
mainControllers  := addKeyListString(mainControllers)
mainExecutables  := addKeyListString(mainExecutables)

; configure objects to be used in a thread-safe manner
localConfig      := ObjShare(ObjShare(mainConfig))
localStatus      := ObjShare(ObjShare(mainStatus))
localControllers := ObjShare(ObjShare(mainControllers))
localExecutables := ObjShare(ObjShare(mainExecutables))

threads := Map()

; ----- START CONTROLLER THEAD -----
; this thread just updates the status of each controller in a loop
threads["controllerThread"] := controllerThread(ObjShare(mainConfig), ObjShare(mainControllers))

; ----- BOOT -----
if (localConfig["Boot"]["EnableBoot"]) {
    runFunction(localConfig["Boot"]["StartBoot"])
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
        ; style of message should probably be "Run Chrome" or "Run Game Playstation C:\Rom\Crash"
        ; if first word = Run
        ;  -> second word of message would be the name of the program to launch, then all other words
        ;     would be sent to the launch command. 
        ; else 
        ;  -> send whole string to runFunction

        if (StrLower(mainMessage[1]) = "run") {
            mainMessage.RemoveAt(1)
            ; TODO - better way to add to localStatus
            localStatus["currEXE"] := createExecutable(mainMessage, localExecutables)

        }
        else {
            runFunction(mainMessage)
        }

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