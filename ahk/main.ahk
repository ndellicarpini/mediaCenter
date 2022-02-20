; TODO - there is currently a ~4MB/hr memory leak due to bad garbage collection for ComObjects
;      - this could be worse/better depending on usage during runtime, requires more testing

#SingleInstance Force

; ----- DO NOT EDIT: DYNAMIC INCLUDE START -----
#Include lib-custom\boot.ahk
#Include lib-custom\browser.ahk
#Include lib-custom\games.ahk
#Include lib-custom\load.ahk
; ----- DO NOT EDIT: DYNAMIC INCLUDE END   -----

#Include lib-mc\confio.ahk
#Include lib-mc\std.ahk
#Include lib-mc\xinput.ahk
#Include lib-mc\messaging.ahk
#Include lib-mc\program.ahk
#Include lib-mc\data.ahk
#Include lib-mc\hotkeys.ahk

#Include lib-mc\gui\std.ahk
#Include lib-mc\gui\loadscreen.ahk
#Include lib-mc\gui\pausemenu.ahk

#Include lib-mc\mt\status.ahk
#Include lib-mc\mt\threads.ahk

SetKeyDelay 80, 60

setCurrentWinTitle(MAINNAME)
mainScriptDir := A_ScriptDir

global dynamicInclude := getDynamicIncludes(A_ScriptFullPath)
global mainMessage := []

; ----- READ GLOBAL CONFIG -----
mainConfig      := Map()
mainStatus      := Map()
mainRunning     := Map()
mainPrograms    := Map()

globalConfig := readGlobalConfig()

; initialize startup arguments
mainConfig["StartArgs"] := A_Args

; initialize basic status features
mainStatus := statusInitBuffer()
; whether or not pause screen is shown 
setStatusParam("pause", false, mainStatus.Ptr)

; whether or not script is suspended (no actions running, changable in pause menu)
setStatusParam("suspendScript", false, mainStatus.Ptr)

; whether or not script is in keyboard & mouse mode
setStatusParam("kbbmode", false, mainStatus.Ptr)

; current name of programs focused & running, used to get config -> setup hotkeys & background actions
setStatusParam("currProgram", "", mainStatus.Ptr)

; name of program overriding the openProgram map -> kept separate for quick actions that should override
; all status, but retain current program stack on close (like checking manual in chrome)
setStatusParam("overrideProgram", "", mainStatus.Ptr)

; load screen info
setStatusParam("loadShow", false, mainStatus.Ptr)
setStatusParam("loadText", "Now Loading...", mainStatus.Ptr)

; error info
setStatusParam("errorShow", false, mainStatus.Ptr)
setStatusParam("errorHwnd", 0, mainStatus.Ptr)

; current hotkeys
setStatusParam("currHotkeys", Map(), mainStatus.Ptr)

; current active gui
setStatusParam("currGui", "", mainStatus.Ptr)

; setup status and config as maps rather than config objects for multithreading
for key, value in globalConfig.subConfigs {
    configObj := Map()
    statusObj := Map()
    
    ; for each subconfig (not monitor), convert to appropriate config & status objects
    for key2, value2, in value.items {
        configObj[key2] := value2
    }

    mainConfig[key] := configObj
}

parseGUIConfig(mainConfig["GUI"])

; create required folders
requiredFolders := [expandDir("data")]

if (mainConfig["General"].Has("CustomLibDir") && mainConfig["General"]["CustomLibDir"] != "") {
    mainConfig["General"]["CustomLibDir"] := expandDir(mainConfig["General"]["CustomLibDir"])
    requiredFolders.Push(mainConfig["General"]["CustomLibDir"])
}

if (mainConfig["General"].Has("AssetDir") && mainConfig["General"]["AssetDir"] != "") {
    mainConfig["General"]["AssetDir"] := expandDir(mainConfig["General"]["AssetDir"])
    requiredFolders.Push(mainConfig["General"]["AssetDir"])
}

if (mainConfig["Programs"].Has("ConfigDir") && mainConfig["Programs"]["ConfigDir"] != "") {
    mainConfig["Programs"]["ConfigDir"] := expandDir(mainConfig["Programs"]["ConfigDir"])
    requiredFolders.Push(mainConfig["Programs"]["ConfigDir"])
}

for value in requiredFolders {
    if (!DirExist(value)) {
        DirCreate value
    }
}

; ----- PARSE PROGRAM CONFIGS -----
if (mainConfig["Programs"].Has("ConfigDir") && mainConfig["Programs"]["ConfigDir"] != "") {
    loop files validateDir(mainConfig["Programs"]["ConfigDir"]) . "*", "FR" {
        tempConfig := readConfig(A_LoopFileFullPath,, "json")
        tempConfig.cleanAllItems(true)

        if (tempConfig.items.Has("name") || tempConfig.items["name"] != "") {

            if (mainConfig["Programs"].Has("SettingListDir") && mainConfig["Programs"]["SettingListDir"] != "") {
                for key, value in tempConfig.items {
                    tempConfig.items[key] := cleanSetting(value, mainConfig["Programs"]["SettingListDir"])
                }
            }
            
            mainPrograms[tempConfig.items["name"]] := tempConfig.toMap()
        }
        else {
            ErrorMsg(A_LoopFileFullPath . " does not have required 'name' parameter")
        }
    }
}

; load nvidia library for gpu monitoring
if (mainConfig["GUI"].Has("EnablePauseGPUMonitor") && mainConfig["GUI"]["EnablePauseGPUMonitor"]) { 
    try {
        nvLib := dllLoadLib("nvapi64.dll")
        DllCall(DllCall("nvapi64.dll\nvapi_QueryInterface", "UInt", 0x0150E828, "CDecl UPtr"), "CDecl")
    }
    catch {
        mainConfig["GUI"]["EnablePauseGPUMonitor"] := false
    }
}

; adds the list of keys to the map as a string so that the map can be enumerated
; despite being a ComObject in the threads
mainConfig       := addKeyListString(mainConfig)

mainControllers  := xInitBuffer(mainConfig["General"]["MaxXInputControllers"])

; configure objects to be used in a thread-safe manner
; TODO - is global necessary / good???
global globalConfig      := ObjShare(ObjShare(mainConfig))
global globalStatus      := mainStatus.Ptr
global globalControllers := mainControllers.Ptr

global threads := Map()

; ----- PARSE START ARGS -----
for key in StrSplit(globalConfig["StartArgs"]["keys"], ",") {
    if (globalConfig["StartArgs"][key] = "-backup") {
        globalStatus := statusRestore(mainRunning, mainPrograms)
    }
    else if (globalConfig["StartArgs"][key] = "-quiet") {
        globalConfig["Boot"]["EnableBoot"] := false
    }
}

if (!globalConfig["StartArgs"].Has("-quiet") && globalConfig["GUI"].Has("EnableLoadScreen") && globalConfig["GUI"]["EnableLoadScreen"]) {
    createLoadScreen()
}

; ----- START CONTROLLER THEAD -----
; this thread just updates the status of each controller in a loop
threads["controllerThread"] := controllerThread(ObjShare(mainConfig), mainControllers.Ptr)
SetWorkingDir(mainScriptDir)

; ----- START ACTION -----
; this thread reads controller & status to determine what actions needing to be taken
; (ie. if currExecutable-Game = retroarch & Home+Start -> Save State)
threads["hotkeyThread"] := hotkeyThread(ObjShare(mainConfig), mainStatus.Ptr, mainControllers.Ptr)
SetWorkingDir(mainScriptDir)

; ----- BOOT -----
if (globalConfig["Boot"]["EnableBoot"]) {
    runFunction(globalConfig["Boot"]["BootFunction"])
}

; ----- ENABLE LISTENER -----
enableMainMessageListener()

; ----- ENABLE BACKUP -----
SetTimer(BackupTimer, 10000)

; ----- MAIN THREAD LOOP -----
; the main thread monitors the other threads, checks that looper is running
; the main thread launches programs with appropriate settings and does any non-hotkey looping actions in the background
; probably going to need to figure out updating loadscreen?

forceActivate := globalConfig["General"]["ForceActivateWindow"]
checkErrors   := globalConfig["Programs"].Has("ErrorList") && globalConfig["Programs"]["ErrorList"] != ""
loopSleep     := Round(globalConfig["General"]["AvgLoopSleep"])

loop {
    ;perform actions based on mode & main message

    ; infinite loop during suspention
    if (getStatusParam("suspendScript")) {
        Sleep(loopSleep)
        continue
    }

    ; --- CHECK MESSAGES ---

    ; do something based on main message (like launching app)
    ; style of message should probably be "Run Chrome" or "Run RetroArch Playstation C:\Rom\Crash"
    ; if first word = Run
    ;  -> second word of message would be the name of the program to launch, then all other words
    ;     would be sent to the launch command. 
    ; else 
    ;  -> send whole string to runFunction
    if (mainMessage.Length > 0) {
        if (StrLower(mainMessage[1]) = "run") {
            mainMessage.RemoveAt(1)
            createProgram(mainMessage, mainRunning, mainPrograms)
        }
        else {
            runFunction(mainMessage)
        }

        ; reset message after processing
        mainMessage := []
    }

    internalMemo := getStatusParam("internalMemo")
    if (internalMemo != "") {
        if (StrLower(internalMemo) = "pause") {
            ; run the pause menu update timer in this thread to not overload hotkey thread
            if (!WinShown(GUIPAUSETITLE)) {
                setStatusParam("pause", true)
                createPauseMenu((currProgram != "") ? mainRunning[currProgram] : "")
            }
            else {
                setStatusParam("false", true)
                destroyPauseMenu()
            }
        }
        else if (StrLower(internalMemo) = "exit") {
            if (getStatusParam("errorShow")) {
                errorHwnd := getStatusParam("errorHwnd")
                errorGUI := getGUI(errorHwnd)

                if (errorGUI) {
                    errorGUI.Destroy()
                }
                else {
                    CloseErrorMsg(errorHwnd)
                }
            }

            else if (currProgram != "") {
                mainRunning[currProgram].exit()
            }
        }
        else if (StrLower(internalMemo) = "nuclear") {
            killed := false
            if (!killed && getStatusParam("errorShow")) {
                try {
                    errorPID := WinGetPID("ahk_id " getStatusParam("errorHwnd"))
                    ProcessKill(errorPID)

                    killed := true
                }
            }

            if (!killed && currProgram != '') {
                ProcessKill(mainRunning[currProgram].getPID())
                killed := true
            }

            ; TODO - gui notification that drastic measures have been taken

            if (!killed) {
                ProcessKill(WinGetPID(WinHidden(MAINNAME)))
            }
        }
        else {
            runFunction(internalMemo)
        }

        ; reset message after processing
        setStatusParam("internalMemo", "")
    }
    
    Sleep(loopSleep)

    hotkeySet := false
    currHotkeys := defaultHotkeys(globalConfig)

    ; --- CHECK OPEN GUIS ---
    guiMessageShown := WinShown(GUIMESSAGETITLE)

    ; if gui message exists
    if (guiMessageShown) {
        if (!hotkeySet) {
            currHotkeys := addHotkeys(currHotkeys, errorHotkeys())
            hotkeySet := true
        }

        setStatusParam("errorShow", true)
        setStatusParam("errorHwnd", guiMessageShown)
    }
    

    ; --- CHECK RUNNING PROGRAMS ---
    currProgram     := getStatusParam("currProgram")
    overrideProgram := getStatusParam("overrideProgram")

    ; if errors should be detected, set error here
    if (checkErrors) {
        resetTMM := A_TitleMatchMode

        SetTitleMatchMode 2
        for key in StrSplit(globalConfig["Programs"]["ErrorList"]["keys"], ",") {

            wndwHWND := WinShown(globalConfig["Programs"]["ErrorList"][key])
            if (wndwHWND > 0) {
                setStatusParam("errorShow", true)
                setStatusParam("errorHwnd", wndwHWND)
                
                break
            }
        }
        SetTitleMatchMode resetTMM
    }

    ; focus error window
    if (getStatusParam("errorShow")) {
        errorHwnd := getStatusParam("errorHwnd")

        if (WinShown("ahk_id " errorHwnd)) {
            if (forceActivate && !WinActive("ahk_id " errorHwnd)) {
                WinActivate("ahk_id " errorHwnd)
            }

            if (!hotkeySet) {
                currHotkeys := addHotkeys(currHotkeys, errorHotkeys())
                hotkeySet := true
            }
        }
        else {
            setStatusParam("errorShow", false)
            setStatusParam("errorHwnd", 0)
        }
    }

    ; focus override program
    else if (overrideProgram != "") {

        ; need to create override program if doesn't exist
        if (!mainRunning.Has(overrideProgram)) {
            createProgram(overrideProgram, mainRunning, mainPrograms, true, false)
        }

        else {
            if (mainRunning[overrideProgram].exists()) {
                if (forceActivate) {
                    try mainRunning[overrideProgram].restore()
                }

                if (!hotkeySet) {
                    currHotkeys := addHotkeys(currHotkeys, mainRunning[overrideProgram].hotkeys)
                    hotkeySet := true
                }
            }
            else {
                setStatusParam("overrideProgram", "")
                mainRunning.Delete(overrideProgram)
            }
        }
    }

    ; activate load screen if its supposed to be shown
    else if (getStatusParam("loadShow")) {
        activateLoadScreen()
    }

    ; current program is set
    else if (currProgram != "") {

        ; need to create current program if doesn't exist
        if (!mainRunning.Has(currProgram)) {
            createProgram(currProgram, mainRunning, mainPrograms, false, false)
        } 

        else {
            ; focus currProgram if it exists
            if (mainRunning[currProgram].exists()) {
                if (forceActivate) {
                    try mainRunning[currProgram].restore()
                }

                if (!hotkeySet) {
                    currHotkeys := addHotkeys(currHotkeys, mainRunning[currProgram].hotkeys)
                    hotkeySet := true
                }
            }
            else {
                prevTime := 0
                prevProgram := ""
                for key, value in mainRunning {
                    if (key != currProgram && value.time > prevTime) {
                        prevProgram := key
                        prevTime := value.time
                    }
                }

                ; restore previous program if open
                if (prevProgram != "") {
                    setStatusParam("currProgram", prevProgram)
                }

                ; updates currProgram if a program exists, else create the default program if no prev program exists
                else {
                    openProgram := checkAllPrograms(mainPrograms)
                    if (openProgram != "") {
                        createProgram(openProgram, mainRunning, mainPrograms, false)
                    }

                    else if (globalConfig["Programs"].Has("Default") && globalConfig["Programs"]["Default"] != "") {
                        createProgram(globalConfig["Programs"]["Default"], mainRunning, mainPrograms)
                    }

                    else {
                        setStatusParam("currProgram", "")
                        mainRunning.Delete(currProgram)
                    }
                }
            }
        }
    }

    ; no current program
    else {
        openProgram := checkAllPrograms(mainPrograms)
        if (openProgram != "") {
            createProgram(openProgram, mainRunning, mainPrograms, false)
        }

        else if (globalConfig["Programs"].Has("Default") && globalConfig["Programs"]["Default"] != "") {
            createProgram(globalConfig["Programs"]["Default"], mainRunning, mainPrograms)
        }
    }

    ; check if hotkeys need to be updated
    statusHotkeys := getStatusParam("currHotkeys")

    statusKeys := []
    statusVals := []
    for key, value in statusHotkeys {
        statusKeys.Push(key)
        statusVals.Push(value)
    }

    currKeys := []
    currVals := []
    for key, value in currHotkeys {
        currKeys.Push(key)
        currVals.Push(value)
    }

    if (!arrayEquals(statusKeys, currKeys) || !arrayEquals(statusVals, currVals)) {
        setStatusParam("currHotkeys", currHotkeys)
    }

    ; need to check that threads are running
    ; i can't figure out how to re-send objshares, so for now error out
    for key, value in threads {
        try {
            value.FuncPtr("")
        }
        catch {
            ErrorMsg((
                "Thread " . key . " has crashed?"
                "I hope this isn't something i need to fix"
            ), true)
        }
    }

    ; check looper
    if (globalConfig["General"]["ForceMaintainMain"] && !NumGet(globalStatus["suspendScript"], 0, "UChar") && !WinHidden(MAINLOOP)) {
        Run A_AhkPath . " " . "mainLooper.ahk", A_ScriptDir, "Hide"
    }
 
    Sleep(loopSleep)
}

disableMainMessageListener()
closeAllThreads(threads)

if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
    dllFreeLib(nvLib)
}

Sleep(100)
ExitApp()

; write globalStatus/globalRunning to file as backup cache?
; maybe only do it like every 10ish secs?
BackupTimer() {
    global 
    
    try statusBackup(mainRunning)
    return
}