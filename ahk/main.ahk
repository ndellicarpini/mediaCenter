#SingleInstance Force
; #WinActivateForce

; ----- DO NOT EDIT: DYNAMIC INCLUDE START -----
#Include plugins\ahk\boot.ahk
#Include plugins\ahk\delfinovin.ahk
#Include plugins\ahk\loadscreen.ahk
#Include plugins\inputs\xinput\xinput.ahk
#Include plugins\programs\bigbox\bigbox.ahk
#Include plugins\programs\cemu\cemu.ahk
#Include plugins\programs\chrome\chrome.ahk
#Include plugins\programs\citra\citra.ahk
#Include plugins\programs\desmume\desmume.ahk
#Include plugins\programs\dolphin\dolphin.ahk
#Include plugins\programs\eagame\eagame.ahk
#Include plugins\programs\kodi\kodi.ahk
#Include plugins\programs\pcsx2\pcsx2.ahk
#Include plugins\programs\ppsspp\ppsspp.ahk
#Include plugins\programs\retroarch\retroarch.ahk
#Include plugins\programs\rpcs3\rpcs3.ahk
#Include plugins\programs\ryujinx\ryujinx.ahk
#Include plugins\programs\steam\steam.ahk
#Include plugins\programs\steam\steamgame.ahk
#Include plugins\programs\steam\extensions\Rockstar Launcher\rockstar.ahk
#Include plugins\programs\steam\extensions\Shenmue\shenmue.ahk
#Include plugins\programs\steam\extensions\Ubisoft Launcher\ubisoft.ahk
#Include plugins\programs\steam\extensions\XCOM 2\xcom 2.ahk
#Include plugins\programs\wingame\wingame.ahk
#Include plugins\programs\wingame\extensions\Super Mario 64\sm64.ahk
#Include plugins\programs\wingame\extensions\Zelda - Majora's Mask\mm.ahk
#Include plugins\programs\wingame\extensions\Zelda - Ocarina of Time\oot.ahk
#Include plugins\programs\xemu\xemu.ahk
#Include plugins\programs\xenia\xenia.ahk
; -----  DO NOT EDIT: DYNAMIC INCLUDE END  -----

#Include lib\config.ahk
#Include lib\std.ahk
#Include lib\messaging.ahk
#Include lib\program\program.ahk
#Include lib\program\emulator.ahk
#Include lib\data.ahk
#Include lib\input\hotkeys.ahk
#Include lib\input\desktop.ahk
#Include lib\input\devices.ahk
#Include lib\input\input.ahk
#Include lib\threads.ahk

#Include lib\gui\std.ahk
#Include lib\gui\constants.ahk
#Include lib\gui\interface.ahk
#Include lib\gui\interfaces\message.ahk
#Include lib\gui\interfaces\notification.ahk
#Include lib\gui\interfaces\choice.ahk
#Include lib\gui\interfaces\loadscreen.ahk
#Include lib\gui\interfaces\input.ahk
#Include lib\gui\interfaces\pause.ahk
#Include lib\gui\interfaces\power.ahk
#Include lib\gui\interfaces\program.ahk
#Include lib\gui\interfaces\volume.ahk
#Include lib\gui\interfaces\keyboard.ahk

; SetKeyDelay 50, 100
CoordMode "Mouse", "Screen"
Critical("Off")

; set dpi scaling per window
prevDPIContext := DllCall("SetThreadDpiAwarenessContext", "Ptr", -3, "Ptr")

; set current WinTitle
SetCurrentWinTitle(MAINNAME)

; get current hwnd
restoreDHW := A_DetectHiddenWindows

DetectHiddenWindows(true)
global mainPID := DllCall("GetCurrentProcessId")
global mainHWND := WinExist("ahk_pid " mainPID)
DetectHiddenWindows(restoreDHW)

global globalConfig       := Map()
global globalStatus       := Map()
global globalConsoles     := Map()
global globalPrograms     := Map()
global globalRunning      := Map()
global globalGuis         := Map()
global globalInputStatus  := Map()
global globalInputConfigs := Map()
global globalThreads      := Map()

globalConsoles.CaseSense := "Off"
globalPrograms.CaseSense := "Off"
globalRunning.CaseSense  := "Off"
globalGuis.CaseSense     := "Off"


; ----- INITIALIZE GLOBALCONFIG -----
globalConfig["StartArgs"] := A_Args

writeLog("Starting...", "MAIN")

; read from global.cfg
for key, value in GlobalCfg().data {
    configObj := Map()
    statusObj := Map()
    
    ; for each subconfig (not monitor), convert to appropriate config & status objects
    for key2, value2, in value {
        configObj[key2] := value2
    }

    globalConfig[key] := configObj
}

; set priority from config
if (globalConfig["General"].Has("MainPriority") && globalConfig["General"]["MainPriority"] != "") {
    ProcessSetPriority(globalConfig["General"]["MainPriority"])
}

; set overrides to case insensitive
if (globalConfig.Has("Overrides")) {
    overrides := ObjDeepClone(globalConfig["Overrides"])

    globalConfig["Overrides"] := Map()
    globalConfig["Overrides"].CaseSense := "Off"

    for key, value in overrides {
        globalConfig["Overrides"][key] := value
    }
}

; set gui variables
setGUIConstants()

writeLog("Reading plugins...", "MAIN")

; create required folders
requiredFolders := [expandDir("data")]

if (globalConfig["GUI"].Has("AssetDir") && globalConfig["GUI"]["AssetDir"] != "") {
    globalConfig["GUI"]["AssetDir"] := expandDir(globalConfig["GUI"]["AssetDir"])
    requiredFolders.Push(globalConfig["GUI"]["AssetDir"])
}
if (globalConfig["Plugins"].Has("AHKPluginDir") && globalConfig["Plugins"]["AHKPluginDir"] != "") {
    globalConfig["Plugins"]["AHKPluginDir"] := expandDir(globalConfig["Plugins"]["AHKPluginDir"])
    requiredFolders.Push(globalConfig["Plugins"]["AHKPluginDir"])
}
if (globalConfig["Plugins"].Has("ConsolePluginDir") && globalConfig["Plugins"]["ConsolePluginDir"] != "") {
    globalConfig["Plugins"]["ConsolePluginDir"] := expandDir(globalConfig["Plugins"]["ConsolePluginDir"])
    requiredFolders.Push(globalConfig["Plugins"]["ConsolePluginDir"])
}
if (globalConfig["Plugins"].Has("InputPluginDir") && globalConfig["Plugins"]["InputPluginDir"] != "") {
    globalConfig["Plugins"]["InputPluginDir"] := expandDir(globalConfig["Plugins"]["InputPluginDir"])
    requiredFolders.Push(globalConfig["Plugins"]["InputPluginDir"])
}
if (globalConfig["Plugins"].Has("ProgramPluginDir") && globalConfig["Plugins"]["ProgramPluginDir"] != "") {
    globalConfig["Plugins"]["ProgramPluginDir"] := expandDir(globalConfig["Plugins"]["ProgramPluginDir"])
    requiredFolders.Push(globalConfig["Plugins"]["ProgramPluginDir"])
}

for value in requiredFolders {
    if (!DirExist(value)) {
        DirCreate(value)
    }
}

global wmiCOM := ComObjGet("winmgmts:")

; load process monitoring library for checking process lists
processLib := DllLoadLib("psapi.dll")

; load gdi library for screenshot thumbnails
gdiLib := DllLoadLib("GdiPlus.dll")

gdiToken  := 0
gdiBuffer := Buffer(24, 0)
NumPut("Char", 1, gdiBuffer.Ptr, 0)
DllCall("GdiPlus\GdiplusStartup", "UPtr*", gdiToken, "Ptr", gdiBuffer.Ptr, "Ptr", 0)

; load nvidia library for gpu monitoring
if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) { 
    try {
        nvLib := DllLoadLib("nvml.dll")
        DllCall("nvml\nvmlInit_v2", "CDecl")
    }
    catch {
        globalConfig["GUI"]["EnablePauseGPUMonitor"] := false
    }
}

; ----- INITIALIZE GLOBALSTATUS -----
; whether or not script is suspended (no actions running, changable in pause menu)
globalStatus["suspendScript"] := false
; whether or not script is in keyboard & mouse mode
globalStatus["kbmmode"] := false
; whether or not script is in desktop mode
globalStatus["desktopmode"] := false

; current active gui
globalStatus["currGui"] := ""
; current WinTitle to overlay regular programs (needs to be an always-on-top window to work properly)
globalStatus["currOverlay"] := ""
; current name of programs focused & running, used to get config -> setup hotkeys & background actions
globalStatus["currProgram"] := Map()
globalStatus["currProgram"]["id"] := ""
globalStatus["currProgram"]["exe"] := ""
globalStatus["currProgram"]["hwnd"] := 0

; load screen info
globalStatus["loadscreen"] := Map()
globalStatus["loadscreen"]["show"] := false
globalStatus["loadscreen"]["enable"] := false
globalStatus["loadscreen"]["overrideWNDW"] := ""
globalStatus["loadscreen"]["text"] := (globalConfig["GUI"].Has("DefaultLoadText")) 
    ? globalConfig["GUI"]["DefaultLoadText"] : "Now Loading..."

; hotkey info
globalStatus["input"] := Map()
globalStatus["input"]["hotkeys"]    := Map()
globalStatus["input"]["mouse"]      := Map()
globalStatus["input"]["buttonTime"] := 70
globalStatus["input"]["buffer"]     := []

; ----- INITIALIZE PROGRAM/CONSOLE/INPUT CONFIGS -----
; read program configs from ConfigDir
if (globalConfig["Plugins"].Has("ProgramPluginDir") && globalConfig["Plugins"]["ProgramPluginDir"] != "") {
    programExtensions := Map()
    loop files validateDir(globalConfig["Plugins"]["ProgramPluginDir"]) . "*.json", "FR" {
        tempConfig := Config(A_LoopFileFullPath, "json")

        if (tempConfig.data.Has("extends") && Type(tempConfig.data["extends"]) = "Map" 
            && tempConfig.data["extends"].Has("id") && tempConfig.data["extends"]["id"] != "") {       
            
            if (programExtensions.Has(tempConfig.data["extends"]["id"])) {
                programExtensions[tempConfig.data["extends"]["id"]].Push(tempConfig.data)
            }
            else {
                programExtensions[tempConfig.data["extends"]["id"]] := [tempConfig.data]
            }
        }
    }

    loop files validateDir(globalConfig["Plugins"]["ProgramPluginDir"]) . "*.json", "FR" {
        tempConfig := Config(A_LoopFileFullPath, "json")

        if (tempConfig.data.Has("id") && tempConfig.data["id"] != "") { 
            ; convert array of exe to map for efficient lookup
            if (tempConfig.data.Has("exe") && Type(tempConfig.data["exe"]) = "Array") {
                tempMap := Map()

                for item in tempConfig.data["exe"] {
                    tempMap[StrLower(item)] := ""
                }

                tempConfig.data["exe"] := tempMap
            }

            ; convert array of wndw to map for efficient lookup
            if (tempConfig.data.Has("wndw") && Type(tempConfig.data["wndw"]) = "Array") {
                tempMap := Map()

                for item in tempConfig.data["wndw"] {
                    tempMap[item] := ""
                }

                tempConfig.data["wndw"] := tempMap
            }
            
            globalPrograms[tempConfig.data["id"]] := tempConfig.data
            if (programExtensions.Has(tempConfig.data["id"])) {
                globalPrograms[tempConfig.data["id"]]["_extensions"] := programExtensions[tempConfig.data["id"]]
            }
        }
    }
}

; read console configs from ConfigDir
if (globalConfig["Plugins"].Has("ConsolePluginDir") && globalConfig["Plugins"]["ConsolePluginDir"] != "") {
    loop files validateDir(globalConfig["Plugins"]["ConsolePluginDir"]) . "*.json", "FR" {
        tempConfig := Config(A_LoopFileFullPath, "json")

        if (tempConfig.data.Has("id") || tempConfig.data["id"] != "") {
            globalConsoles[tempConfig.data["id"]] := tempConfig.data
        }
        else {
            ErrorMsg(A_LoopFileFullPath . " does not have required 'id' parameter")
        }
    }
}

; read input configs from plugins & start a unique inputThread for each individual config
if (globalConfig["Plugins"].Has("InputPluginDir") && globalConfig["Plugins"]["InputPluginDir"] != "") {
    loop files validateDir(globalConfig["Plugins"]["InputPluginDir"]) . "*.json", "FR" {
        tempConfig := Config(A_LoopFileFullPath, "json")

        if ((tempConfig.data.Has("id") || tempConfig.data["id"] != "")
            && (tempConfig.data.Has("className") || tempConfig.data["className"] != "")
            && (tempConfig.data.Has("maxConnected") || tempConfig.data["maxConnected"] != "")) {
            
            controlID := tempConfig.data["id"]

            globalInputConfigs[controlID] := tempConfig.data
            globalInputStatus[controlID] := Array()

            loop globalInputConfigs[controlID]["maxConnected"] {
                globalInputStatus[controlID].Push(Map())
            }

            globalThreads["input-" . controlID] := inputThread(
                controlID,
                ObjPtrAddRef(globalConfig), 
                ObjPtrAddRef(globalStatus), 
                ObjPtrAddRef(globalInputStatus),
                ObjPtrAddRef(globalInputConfigs)
            )
        }
        else {
            ErrorMsg(A_LoopFileFullPath . " does not have required 'id' parameter")
        }
    }
}

; ----- PARSE START ARGS -----
for item in globalConfig["StartArgs"] {
    if (item = "-backup") {
        writeLog("Restoring state from backup...", "MAIN")

        try statusRestore()

        ; kill any programs that should have exited before main was backed up
        for key, value in globalRunning {
            if (value.shouldExit) {
                try ProcessKill(value.getPID())
            }
        }
        
        if (globalStatus["kbmmode"]) {
            enableKBMMode()
        }
        if (globalStatus["desktopmode"]) {
            enableDesktopMode()
        }

        writeLog("---------- State restored ----------`r`n" . toString(globalStatus), "MAIN")
        writeLog("---------- State restored ----------", "MAIN")

        resetLoadScreen(0)
    }
}

; set the GUI constants
setMonitorInfo()

; create loadscreen if appropriate
if (!inArray("-quiet", globalConfig["StartArgs"]) && globalConfig["GUI"].Has("EnableLoadScreen") && globalConfig["GUI"]["EnableLoadScreen"]) {
    globalStatus["loadscreen"]["enable"] := true
}

writeLog("Starting Threads...", "MAIN")

; start non-input threads
globalThreads["hotkey"] := hotkeyThread(
    ObjPtrAddRef(globalConfig), 
    ObjPtrAddRef(globalStatus),
    ObjPtrAddRef(globalInputConfigs),
    ObjPtrAddRef(globalRunning)
)
globalThreads["misc"] := miscThread(
    ObjPtrAddRef(globalConfig), 
    ObjPtrAddRef(globalStatus)
)

Sleep(250)

; ----- BOOT -----
if (globalConfig.Has("Overrides") && globalConfig["Overrides"].Has("boot") && globalConfig["Overrides"]["boot"] != "") {
    try %globalConfig["Overrides"]["boot"]%(globalConfig["StartArgs"]*)
}

; initial backup of status
try statusBackup()

; enables the OnMessage listener for send2Main
global send2MainBuffer := []
OnMessage(MESSAGE_VAL, HandleMessage)

; enables the shell listener
DllCall("RegisterShellHookWindow", "UInt", mainHWND)

global activateFixHWND := 0
global SHELL_MESSAGE_VAL := DllCall("RegisterWindowMessage", "Str", "SHELLHOOK")
OnMessage(SHELL_MESSAGE_VAL, HandleShellMessage)

; ----- MAIN THREAD LOOP -----
; the main thread monitors the other threads, checks that maintainer is running
; the main thread launches programs with appropriate settings and does any non-hotkey looping actions in the background

forceMaintain := globalConfig["General"].Has("ForceMaintainMain") && globalConfig["General"]["ForceMaintainMain"]
forceActivate := globalConfig["General"].Has("ForceActivateWindow") && globalConfig["General"]["ForceActivateWindow"]
loopSleep     := Round(globalConfig["General"]["AvgLoopSleep"] * 2)

writeLog("Starting input timer...", "MAIN")

; set timer to check the input buffer
SetTimer(InputBufferTimer, 35)

delayCount := 0
maxDelayCount := 15

writeLog("Starting main loop...", "MAIN")

loop {
    currSuspended   := globalStatus["suspendScript"]
    currDesktopMode := globalStatus["desktopmode"]

    ; --- CHECK SEND2MAIN BUFFER ---
    if (send2MainBuffer.Length > 0 && !currSuspended) {
        message := send2MainBuffer.Pop()
        if (message = "" || message.Length = 0) {
            continue
        } 

        restoreCritical := A_IsCritical
        Critical("On")

        if (StrLower(message[1]) = "run") {
            message.RemoveAt(1)
            createProgram(message)
        }
        else if (StrLower(message[1]) = "console") { 
            message.RemoveAt(1)
            createConsole(message)
        }
        else {
            try RunBufferedFunction(joinArray(message))
        }

        Critical(restoreCritical)

        Sleep(loopSleep)
        continue
    }

    activeSet := false

    ; --- CHECK OPEN GUIS ---
    currGui := globalStatus["currGui"]

    if (currGui != "") {
        currWNDW := INTERFACES[currGui]["wndw"]   
        if (!globalGuis.Has(currGui) || !WinShown(currWNDW)) {
            updateGuis()
            currGui := globalStatus["currGui"]
        }  

        if (currGui != "" && globalGuis.Has(currGui) && globalGuis[currGui].allowFocus) {
            if (!activeSet) {
                if (forceActivate && !WinActive(currWNDW)) {
                    try WinActivateForeground(currWNDW)
                }

                activeSet := true
            }
        }
    }
    
    ; --- CHECK LOAD SCREEN ---
    if (globalStatus["loadscreen"]["show"] && !activeSet && !currSuspended && !currDesktopMode) {             
        activeSet := true

        if (!globalStatus["kbmmode"] && keyboardExists()) {
            closeKeyboard()
        }
    }

    ; --- CHECK DESKTOP MODE / KB & MOUSE MODE ---
    if (globalStatus["desktopmode"] && !activeSet) {
        activeSet := true
    }

    ; --- CHECK OPEN PROGRAMS ---
    currProgram := globalStatus["currProgram"]["id"]

    if (!currSuspended && !currDesktopMode && send2MainBuffer.Length = 0) {
        if (currProgram = "" || !globalRunning.Has(currProgram) || !globalRunning[currProgram].exists(false, true)) {
            updatePrograms()
            currProgram := globalStatus["currProgram"]["id"]
        }

        if (currProgram != "" && globalRunning.Has(currProgram)) {
            ; double check that no currGui exists because dumb dumb
            if (globalStatus["currGui"] != "" && globalGuis.Has(globalStatus["currGui"]) 
                && globalGuis[globalStatus["currGui"]].allowFocus) {
                continue
            }

            if (!activeSet) {
                if (forceActivate) {
                    try globalRunning[currProgram].restore()
                }
                else {
                    try globalRunning[currProgram].resume()
                }

                activeSet := true
            }
        }
    }

    ; --- CHECK FIX ACTIVATION ---
    if (activateFixHWND != 0) {
        tempHWND := activateFixHWND
        activateFixHWND := 0

        if (WinShown(tempHWND) && (globalStatus["currGui"] = "" 
            || !globalGuis.Has(globalStatus["currGui"]) || !globalGuis[globalStatus["currGui"]].allowFocus)) {
            
            WinMinimizeMessage(tempHWND)
            Sleep(250)
            WinRestoreMessage(tempHWND)

            Sleep(loopSleep)
            continue
        }    
    }

    ; --- CHECK ALL OPEN PROGRAMS / GUIS ---
    if ((delayCount > maxDelayCount || !activeSet) && !currSuspended && send2MainBuffer.Length = 0) {
        updateGuis()
        updatePrograms()
    }

    ; every maxDelayCount loops -> check threads & maintainer
    if (delayCount > maxDelayCount) {
        for key, value in globalThreads {
            ; if thread crashed, reset main
            try {
                bruh := value.ThreadID
            }
            catch {
                ProcessClose(mainPID)
            }
        }

        ; check that maintainer is running
        if (forceMaintain && !WinHidden(MAINLOOP)) {
            Run(A_AhkPath . A_Space . "maintainer.ahk", A_ScriptDir, "Hide")
        }

        ; check that no other instances of main are running
        restoreDHW := A_DetectHiddenWindows
        DetectHiddenWindows(true)

        mainList := WinGetList(MAINNAME)
        if (mainList.Length > 1) {
            for hwnd in mainList {
                if (hwnd != mainHWND) {
                    ProcessClose(WinGetPID(hwnd))
                }
            }
        }

        DetectHiddenWindows(restoreDHW)

        delayCount := 0
    }

    ; check if status has updated & backup
    if (statusUpdated()) {
        try statusBackup()
    }
    
    delayCount += 1
    Sleep(loopSleep)
}

return

; runs a function string (generally from send2Main or the input buffer)
;  bufferedFunc - function string
RunBufferedFunction(bufferedFunc) {
    global globalConfig
    global globalStatus        
    global globalRunning       
    global globalGuis
    
    currProgram := globalStatus["currProgram"]["id"]
    currGui     := globalStatus["currGui"]
    currLoad    := globalStatus["loadscreen"]["show"]
    currKBMM    := globalStatus["kbmmode"]
    currDesktop := globalStatus["desktopmode"]

    ; update pause status & create/destroy pause menu
    if (StrLower(bufferedFunc) = "pausemenu") {
        ; check the following conditions to allow the pause screen to show
        ;  - the load screen is not active
        ;  - config EnablePauseMenu is not explicitly set to "false"
        ;  - if a program exists -> the program allows pausing
        ;  - if a gui exists -> the gui allows pausing
        if (!(globalConfig["GUI"].Has("EnablePauseMenu") && globalConfig["GUI"]["EnablePauseMenu"] = false)
            ; && (!currLoad || (currLoad && globalStatus["loadscreen"]["overrideWNDW"] != "")) 
            && !(currProgram != "" && globalRunning.Has(currProgram) && !globalRunning[currProgram].allowPause)
            && !(currGui != "" && globalGuis.Has(currGui) && !globalGuis[currGui].allowPause)) {

            try {
                if (!globalGuis.Has("pause")) {
                    createInterface("pause")
                }
                else {
                    globalGuis["pause"].Destroy()
                }
            }
            catch {
                writeLog("Failed to create pausemenu??")
            }
        }
    }

    ; the nuclear option
    else if (StrLower(bufferedFunc) = "nuclear") {
        if (currProgram != "" && globalRunning[currProgram].exists()) {
            try ProcessKill(globalRunning[currProgram].getPID())
        }

        ; need to think about if this is necessary?
        ; i mean if this is working main isn"t crashed right?
        ProcessKill(MAINNAME)
    }

    ; run current gui funcion
    else if (StrLower(SubStr(bufferedFunc, 1, 4)) = "gui.") {
        ; need to do separate check so that bufferedFunc doesn't propagate to runFunction
        if (currGui != "" && globalGuis.Has(currGui)) {
            tempArr  := StrSplit(bufferedFunc, A_Space)
            tempFunc := StrReplace(tempArr.RemoveAt(1), "gui.", "") 

            try globalGuis[currGui].%tempFunc%(tempArr*)
        }
    }

    ; run current program function
    else if (StrLower(SubStr(bufferedFunc, 1, 8)) = "program.") {
        ; need to do separate check so that bufferedFunc doesn't propagate to runFunction
        if (currProgram != "" && globalPrograms.Has(currProgram) && !globalStatus["suspendScript"]) {
            tempArr  := StrSplit(bufferedFunc, A_Space)
            tempFunc := StrReplace(tempArr.RemoveAt(1), "program.", "")
            
            if (tempFunc = "exit") {
                if (currProgram != "" && globalRunning[currProgram].allowExit) {
                    try globalRunning[currProgram].exit()
                }
            }
            else {
                try globalRunning[currProgram].%tempFunc%(tempArr*)
            }
        }
    }

    ; run function
    else if (bufferedFunc != "") {
        runFunction(bufferedFunc)
    }

    return
}

; run function from top of input buffer
InputBufferTimer() {
    global globalConfig
    global globalStatus        
    global globalRunning       
    global globalGuis

    try {
        if (globalStatus["input"]["buffer"].Length = 0) {
            return
        }

        RunBufferedFunction(globalStatus["input"]["buffer"][1])
        globalStatus["input"]["buffer"].RemoveAt(1)
    }
    catch {
        globalStatus["input"]["buffer"] := []
    }

    return
}

; handle when message comes in from send2Main
; style of message should probably be "Run Chrome" or "Run RetroArch Playstation C:\Rom\Crash"
HandleMessage(wParam, lParam, *) {
    global send2MainBuffer
    global globalConfig
    global globalStatus
    global globalRunning

    message := getMessage(lParam)

    if (message.Length = 0 || globalStatus["suspendScript"]) {
        return
    }

    ; ProcessClose(WinHidden(SENDNAME))

    currProgram := globalStatus["currProgram"]["id"]

    restoreCritical := A_IsCritical
    Critical("On")

    ; the nuclear option
    if (StrLower(message[1]) = "nuclear") {
        if (currProgram != "" && globalRunning[currProgram].exists()) {
            try ProcessKill(globalRunning[currProgram].getPID())
        }

        ; need to think about if this is necessary?
        ; i mean if this is working main isn't crashed right?
        ProcessKill(MAINNAME)
        return
    }

    ; minimize the current program before doing the requested action
    if (SubStr(StrLower(message[1]), 1, 7) = "minthen") {
        if (currProgram != "") {
            globalRunning[currProgram].minimize()
            Sleep(200)
        }

        message[1] := SubStr(message[1], 8)
    }

    ; prep load screen for new program
    if (StrLower(message[1]) = "run" || StrLower(message[1]) = "console") {
        setLoadScreen()
        activateLoadScreen()
    }

    ; buffer all actions bc shit gets wacky being initialized in msg handler
    send2MainBuffer.Push(message)
    
    Critical(restoreCritical)
    return
}

; handle when message sent from shell
HandleShellMessage(wParam, lParam, *) {
    global globalStatus
    global globalGuis
    global globalRunning

    global activateFixHWND

    HSHELL_FLASH := 0x8006

    if (globalStatus["suspendScript"]) {
        return
    }

    ; maybe convert to a switch statement if I keep adding shell message checks
    if (wParam = HSHELL_FLASH && WinShown(lParam)) {
        for key, value in globalRunning {
            if (!value.background && lParam = value.getHWND()) {
                activateFixHWND := lParam
                return
            }
        }
    }

    return
}

; clean shutdown of script
ShutdownScript(restoreTaskbar := true) {
    global globalThreads

    ; disable input buffer
    SetTimer(InputBufferTimer, 0)

    ; disable message listeners
    OnMessage(MESSAGE_VAL, HandleMessage, 0)
    OnMessage(SHELL_MESSAGE_VAL, HandleShellMessage, 0)

    setLoadScreen("Please Wait...")
    activateLoadScreen()

    writeLog("Exiting...", "MAIN")

    DllFreeLib(processLib)
    
    DllCall("GdiPlus\GdiplusShutdown", "Ptr", gdiToken)
    DllFreeLib(gdiLib)
    
    if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
        DllFreeLib(nvLib)
    }
    
    ; reset dpi scaling
    DllCall("SetThreadDpiAwarenessContext", "Ptr", prevDPIContext, "Ptr")
    
    ; reset taskbar
    if (restoreTaskbar && !taskbarExists()) {
        showTaskbar()
    }

    writeLog("Exiting Threads...", "MAIN")

    ; tell the threads to close
    for key, value in globalThreads {
        value.ExitApp()
    }
    
    Sleep(500)

    ObjRelease(ObjPtr(globalConfig))
    ObjRelease(ObjPtr(globalStatus))
    ObjRelease(ObjPtr(globalConsoles))
    ObjRelease(ObjPtr(globalPrograms))
    ObjRelease(ObjPtr(globalRunning))
    ObjRelease(ObjPtr(globalGuis))
    ObjRelease(ObjPtr(globalInputStatus))
    ObjRelease(ObjPtr(globalInputConfigs))
}

; exits the script entirely, including maintainer
ExitScript() {
    global globalConfig
    global mainPID

    Critical("On")

    try statusBackup()

    if (WinHidden(MAINLOOP) && globalConfig["General"].Has("ForceMaintainMain") 
        && globalConfig["General"]["ForceMaintainMain"]) {

        ProcessWinClose(MAINLOOP)
    }

    ShutdownScript()
    Sleep(500)

    ; ProcessClose(mainPID)
    ExitApp()
}

; resets the script, loading from statusBackup
ResetScript() {
    global globalConfig
    global mainPID

    Critical("On")

    try statusBackup()

    restoreSuspendScript := globalStatus["suspendScript"]
    globalStatus["suspendScript"] := false
    
    restoreDesktopMode := globalStatus["desktopmode"]
    globalStatus["desktopmode"] := false

    if (!globalConfig["General"].Has("ForceMaintainMain") 
        || (globalConfig["General"].Has("ForceMaintainMain") && !globalConfig["General"]["ForceMaintainMain"])) {

        Run A_AhkPath . A_Space . "maintainer.ahk 1", A_ScriptDir, "Hide"
    }
    else if (!WinHidden(MAINLOOP)) {
        Run A_AhkPath . A_Space . "maintainer.ahk", A_ScriptDir, "Hide"
    }

    ShutdownScript()
    Sleep(500)

    ; ProcessClose(mainPID)
    ExitApp()
}

; clean up running programs & shutdown
PowerOff() {
    global globalStatus
    global globalConfig
    global mainPID

    Critical("On")

    if (globalConfig["Plugins"].Has("DefaultProgram")) {
        globalConfig["Plugins"]["DefaultProgram"] := ""
    }

    if (globalStatus["suspendScript"]) {
        globalStatus["suspendScript"] := false
    }
    if (globalStatus["desktopmode"]) {
        disableDesktopMode()
    }
    if (globalStatus["kbmmode"]) {
        disableKBMMode()
    }
    
    exitAllPrograms()
    Sleep(500)
    
    ShutdownScript()
    Sleep(500)

    Shutdown 1
    ; ProcessClose(mainPID)
    ExitApp()
}

; clean up running programs & restart
Restart() {
    global globalConfig
    global mainPID

    Critical("On")

    if (globalConfig["Plugins"].Has("DefaultProgram")) {
        globalConfig["Plugins"]["DefaultProgram"] := ""
    }

    if (globalStatus["suspendScript"]) {
        globalStatus["suspendScript"] := false
    }
    if (globalStatus["desktopmode"]) {
        disableDesktopMode()
    }
    if (globalStatus["kbmmode"]) {
        disableKBMMode()
    }

    exitAllPrograms()
    Sleep(500)

    ShutdownScript()
    Sleep(500)

    Shutdown 2
    ; ProcessClose(mainPID)
    ExitApp()
}

; clean up running programs & sleep -> restarting script after
Standby() {
    global globalConfig
    global mainPID

    Critical("On")

    if (globalConfig["Plugins"].Has("DefaultProgram")) {
        globalConfig["Plugins"]["DefaultProgram"] := ""
    }

    if (globalStatus["suspendScript"]) {
        globalStatus["suspendScript"] := false
    }
    if (globalStatus["desktopmode"]) {
        disableDesktopMode()
    }
    if (globalStatus["kbmmode"]) {
        disableKBMMode()
    }

    if (WinHidden(MAINLOOP)) {
        ProcessWinClose(MAINLOOP)
    }
    
    exitAllPrograms()
    setLoadScreen("Please Wait...")
    activateLoadScreen()
    Sleep(1000)

    ProcessClose("explorer.exe")
    
    DllCall("powrprof\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)
    Sleep(5000)

    ShutdownScript()
    Sleep(500)

    Run A_AhkPath . A_Space . "maintainer.ahk -clean", A_ScriptDir, "Hide"
    ; ProcessClose(mainPID)
    ExitApp()
}