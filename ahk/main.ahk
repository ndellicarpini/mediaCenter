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
#Include lib-mc\gui\interface.ahk
#Include lib-mc\gui\loadscreen.ahk
#Include lib-mc\gui\pausemenu.ahk

#Include lib-mc\mt\status.ahk
#Include lib-mc\mt\threads.ahk

SetKeyDelay 80, 60

setCurrentWinTitle(MAINNAME)
global MAINSCRIPTDIR := A_ScriptDir

; ----- INITIALIZE GLOBALCONFIG (READ-ONLY) -----
mainConfig := Map()
mainConfig["StartArgs"] := A_Args

; read from global.cfg
for key, value in readGlobalConfig().subConfigs {
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


; ----- INITIALIZE GLOBALSTATUS -----
mainStatus := statusInitBuffer()

; whether or not pause screen is shown 
setStatusParam("pause", false, mainStatus.Ptr)
; whether or not script is suspended (no actions running, changable in pause menu)
setStatusParam("suspendScript", false, mainStatus.Ptr)
; whether or not script is in keyboard & mouse mode
setStatusParam("kbbmode", false, mainStatus.Ptr)
; current name of programs focused & running, used to get config -> setup hotkeys & background actions
setStatusParam("currProgram", "", mainStatus.Ptr)
; load screen info
setStatusParam("loadShow", false, mainStatus.Ptr)
setStatusParam("loadText", "Now Loading...", mainStatus.Ptr)
; error info
setStatusParam("errorShow", false, mainStatus.Ptr)
setStatusParam("errorHwnd", 0, mainStatus.Ptr)
; time to hold a hotkey for it to trigger
setStatusParam("buttonTime", 70, mainStatus.Ptr)
; current hotkeys
setStatusParam("currHotkeys", Map(), mainStatus.Ptr)
; current active gui
setStatusParam("currGui", "", mainStatus.Ptr)
; some function that should be digested by a thread
setStatusParam("internalMessage", "", mainStatus.Ptr)


; ----- INITIALIZE GLOBALCONTROLLERS -----
mainControllers  := xInitBuffer(mainConfig["General"]["MaxXInputControllers"])


; ----- INITIALIZE PROGRAM CONFIGS -----
global globalRunning  := Map()
global globalPrograms := Map()
global globalGuis     := Map()

; read program configs from ConfigDir
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
            
            globalPrograms[tempConfig.items["name"]] := tempConfig.toMap()
        }
        else {
            ErrorMsg(A_LoopFileFullPath . " does not have required 'name' parameter")
        }
    }
}


; ----- INITIALIZE THREADS -----
; configure objects to be used in a thread-safe manner
;  read-only objects can be used w/ ObjShare 
;  read/write objects must be a buffer ptr w/ custom getters/setters
global globalConfig      := ObjShare(ObjShare(mainConfig))
global globalStatus      := mainStatus.Ptr
global globalControllers := mainControllers.Ptr

; message sent from send2Main
global externalMessage := []

; ----- PARSE START ARGS -----
for key, value in globalConfig["StartArgs"] {
    if (value = "-backup") {
        statusRestore()
    }
    else if (value = "-quiet") {
        globalConfig["Boot"]["EnableBoot"] := false
    }
}

if (!globalConfig["StartArgs"].Has("-quiet") && globalConfig["GUI"].Has("EnableLoadScreen") && globalConfig["GUI"]["EnableLoadScreen"]) {
    createLoadScreen()
}

; ----- START CONTROLLER THEAD -----
; this thread just updates the status of each controller in a loop
controllerThreadRef := controllerThread(ObjShare(mainConfig), mainControllers.Ptr)

; ----- START HOTKEY THREAD -----
; this thread reads controller & status to determine what actions needing to be taken
; (ie. if currExecutable-Game = retroarch & Home+Start -> Save State)
hotkeyThreadRef := hotkeyThread(ObjShare(mainConfig), mainStatus.Ptr, mainControllers.Ptr)

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

forceMaintain := globalConfig["General"]["ForceMaintainMain"]
forceActivate := globalConfig["General"]["ForceActivateWindow"]

checkErrors   := globalConfig["Programs"].Has("ErrorList") && globalConfig["Programs"]["ErrorList"] != ""

loopSleep     := Round(globalConfig["General"]["AvgLoopSleep"])

checkAllCount := 0
loop {
    ; infinite loop during suspention
    if (getStatusParam("suspendScript")) {
        Sleep(loopSleep)
        continue
    }

    ; --- CHECK MESSAGES ---

    ; do something based on external message (like launching app)
    ; style of message should probably be "Run Chrome" or "Run RetroArch Playstation C:\Rom\Crash"
    if (externalMessage.Length > 0) {
        if (StrLower(externalMessage[1]) = "run") {
            externalMessage.RemoveAt(1)
            createProgram(externalMessage, globalRunning, globalPrograms)
        }
        else {
            runFunction(externalMessage)
        }

        ; reset message after processing
        externalMessage := []

        continue
    }

    internalMessage := getStatusParam("internalMessage")
    if (internalMessage != "") {
        currProgram := getStatusParam("currProgram")
        currGui     := getStatusParam("currGui")

        if (StrLower(internalMessage) = "pause") {
            if (!WinShown(GUIPAUSETITLE)) {
                setStatusParam("pause", true)
                createPauseMenu()
            }
            else {
                setStatusParam("pause", false)
                destroyPauseMenu()
            }
        }
        else if (StrLower(internalMessage) = "exit") {
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
                globalRunning[currProgram].exit()
            }
        }
        else if (StrLower(internalMessage) = "nuclear") {
            killed := false
            if (!killed && getStatusParam("errorShow")) {
                try {
                    errorPID := WinGetPID("ahk_id " getStatusParam("errorHwnd"))
                    ProcessKill(errorPID)

                    killed := true
                }
            }

            if (!killed && currProgram != "") {
                ProcessKill(globalRunning[currProgram].getPID())
                killed := true
            }

            ; TODO - gui notification that drastic measures have been taken

            if (!killed) {
                ProcessKill(WinGetPID(WinHidden(MAINNAME)))
            }
        }
        else if (StrLower(SubStr(internalMessage, 1, 4)) = "gui.") {
            globalGuis[currGui].%StrReplace(internalMessage, "gui.", "")%()
        }
        else if (StrLower(SubStr(internalMessage, 1, 4)) = "program.") {
            globalRunning[currProgram].%StrReplace(internalMessage, "program.", "")%()
        }
        else {
            runFunction(internalMessage)
        }

        if (getStatusParam("internalMessage") != internalMessage) {
            continue
        }

        ; reset message after processing
        setStatusParam("internalMessage", "")

        continue
    }
    
    Sleep(loopSleep)

    activeSet := false
    currHotkeys := defaultHotkeys(globalConfig)

    ; --- CHECK OVERRIDE ---
    ; focus error window

    ; if errors should be detected, set error here
    if (checkErrors) {
        resetTMM := A_TitleMatchMode

        SetTitleMatchMode 2
        for key, value in globalConfig["Programs"]["ErrorList"] {

            wndwHWND := WinShown(value)
            if (wndwHWND > 0) {
                setStatusParam("errorShow", true)
                setStatusParam("errorHwnd", wndwHWND)
                
                break
            }
        }
        SetTitleMatchMode resetTMM
    }

    if (getStatusParam("errorShow")) {
        errorHwnd := getStatusParam("errorHwnd")

        if (WinShown("ahk_id " errorHwnd)) {
            if (!activeSet) {
                if (forceActivate && !WinActive("ahk_id " errorHwnd)) {
                    WinActivate("ahk_id " errorHwnd)
                }

                currHotkeys := addHotkeys(currHotkeys, errorHotkeys())

                setStatusParam("buttonTime", 25)
                activeSet := true
            }
        }
        else {
            setStatusParam("errorShow", false)
            setStatusParam("errorHwnd", 0)
        }
    }

    ; activate load screen if its supposed to be shown
    if (!activeSet && getStatusParam("loadShow")) {
        activateLoadScreen()
        activeSet := true
    }

    ; --- CHECK ALL OPEN ---
    currProgram := getStatusParam("currProgram")
    currGui     := getStatusParam("currGui")

    if (checkAllCount > 10 || (currProgram = "" && currGui = "")) {
        checkAllGuis()

        mostRecentGui := getMostRecentGui()
        if (mostRecentGui != currGui) {
            setStatusParam("currGui", mostRecentGui)
        }

        checkAllPrograms()

        mostRecentProgram := getMostRecentProgram()
        if (mostRecentProgram != currProgram) {
            setStatusParam("currProgram", mostRecentProgram)
        }

        checkAllCount := 0
    }

    ; --- CHECK OPEN GUIS ---
    if (currGui != "") {
        if (globalGuis.Has(currGui) && WinShown(currGui)) {
            if (!activeSet) {
                if (forceActivate) {
                    try WinActivate(currGui)
                }

                if (globalGuis[currGui].hotkeys.Count > 0) {
                    currHotkeys := addHotkeys(currHotkeys, globalGuis[currGui].hotkeys)
                }

                setStatusParam("buttonTime", 25)
                activeSet := true
            }
        } 
        else {
            if (globalGuis.Has(currGui)) {
                globalGuis[currGui].Destroy()
                globalGuis.Delete(currGui)
            }

            setStatusParam("currGui", "")
        }
    }

    ; --- CHECK OPEN PROGRAMS ---
    if (currProgram != "") {
        if (globalRunning.Has(currProgram)) {
            if (globalRunning[currProgram].exists()) {
                if (!activeSet) {
                    if (forceActivate) {
                        try globalRunning[currProgram].restore()
                    }

                    if (globalRunning[currProgram].hotkeys.Count > 0) {
                        currHotkeys := addHotkeys(currHotkeys, globalRunning[currProgram].hotkeys)
                    }

                    setStatusParam("buttonTime", 70)
                    activeSet := true
                }
            }
            else {
                setStatusParam("currProgram", "")
            }
        } 
        else {
            createProgram(currProgram, false, false)
        }
    }

    ; --- CHECK HOTKEYS ---
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

    ; --- CHECK THREADS ---
    try {
        controllerThreadRef.FuncPtr("")
    }
    catch {
        controllerThreadRef := controllerThread(ObjShare(mainConfig), globalControllers)
    }
    try {
        hotkeyThreadRef.FuncPtr("")
    }
    catch {
        hotkeyThreadRef := hotkeyThread(ObjShare(mainConfig), globalStatus, globalControllers)
    }

    ; --- CHECK LOOPER ---
    if (forceMaintain && !WinHidden(MAINLOOP)) {
        Run A_AhkPath . A_Space . "mainLooper.ahk", A_ScriptDir, "Hide"
    }
 
    checkAllCount += 1
    Sleep(loopSleep)
}

disableMainMessageListener()

try controllerThreadRef.ExitApp()
try hotkeyThreadRef.ExitApp()

if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
    dllFreeLib(nvLib)
}

Sleep(100)
ExitApp()

; write globalStatus/globalRunning to file as backup cache?
; maybe only do it like every 10ish secs?
BackupTimer() {    
    try statusBackup()
    return
}