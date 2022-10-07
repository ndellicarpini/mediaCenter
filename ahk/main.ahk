#SingleInstance Force
; #WinActivateForce

; ----- DO NOT EDIT: DYNAMIC INCLUDE START -----
#Include plugins\ahk\boot.ahk
#Include plugins\ahk\LOADSC~1.AHK
#Include plugins\CONTRO~1\xinput\xinput.ahk
#Include plugins\programs\AMAZON~1\AMAZON~1.AHK
#Include plugins\programs\bigbox\bigbox.ahk
#Include plugins\programs\cemu\cemu.ahk
#Include plugins\programs\chrome\chrome.ahk
#Include plugins\programs\citra\citra.ahk
#Include plugins\programs\desmume\desmume.ahk
#Include plugins\programs\dolphin\dolphin.ahk
#Include plugins\programs\kodi\kodi.ahk
#Include plugins\programs\origin\ORIGIN~1.AHK
#Include plugins\programs\pcsx2\pcsx2.ahk
#Include plugins\programs\ppsspp\ppsspp.ahk
#Include plugins\programs\RETROA~1\RETROA~1.AHK
#Include plugins\programs\steam\steam.ahk
#Include plugins\programs\steam\STEAMG~1.AHK
#Include plugins\programs\wingame\wingame.ahk
#Include plugins\programs\xemu\xemu.ahk
#Include plugins\programs\xenia\xenia.ahk
; -----  DO NOT EDIT: DYNAMIC INCLUDE END  -----

#Include lib\confio.ahk
#Include lib\std.ahk
#Include lib\messaging.ahk
#Include lib\program.ahk
#Include lib\emulator.ahk
#Include lib\data.ahk
#Include lib\hotkeys.ahk
#Include lib\desktop.ahk
#Include lib\controller.ahk
#Include lib\threads.ahk

#Include lib\gui\std.ahk
#Include lib\gui\constants.ahk
#Include lib\gui\interface.ahk
#Include lib\gui\choicedialog.ahk
#Include lib\gui\loadscreen.ahk
#Include lib\gui\pausemenu.ahk
#Include lib\gui\volumemenu.ahk
#Include lib\gui\controllermenu.ahk
#Include lib\gui\programmenu.ahk
#Include lib\gui\powermenu.ahk
#Include lib\gui\keyboard.ahk

SetKeyDelay 50, 100
CoordMode "Mouse", "Screen"
Critical "Off"

; set dpi scaling per window
prevDPIContext := DllCall("SetThreadDpiAwarenessContext", "Ptr", -3, "Ptr")

SetCurrentWinTitle(MAINNAME)
global MAINSCRIPTDIR := A_ScriptDir

global globalConfig         := Map()
global globalStatus         := Map()
global globalConsoles       := Map()
global globalPrograms       := Map()
global globalRunning        := Map()
global globalGuis           := Map()
global globalControllers    := Map()
global globalControlConfigs := Map()
global globalThreads        := Map()

; ----- INITIALIZE GLOBALCONFIG (READ-ONLY) -----
globalConfig["StartArgs"] := A_Args

; read from global.cfg
for key, value in readGlobalConfig().subConfigs {
    configObj := Map()
    statusObj := Map()
    
    ; for each subconfig (not monitor), convert to appropriate config & status objects
    for key2, value2, in value.items {
        configObj[key2] := value2
    }

    globalConfig[key] := configObj
}

; set priority from config
if (globalConfig["General"].Has("MainPriority") && globalConfig["General"]["MainPriority"] != "") {
    ProcessSetPriority(globalConfig["General"]["MainPriority"])
}

; set gui variables
parseGUIConfig(globalConfig["GUI"])

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
if (globalConfig["Plugins"].Has("ControllerPluginDir") && globalConfig["Plugins"]["ControllerPluginDir"] != "") {
    globalConfig["Plugins"]["ControllerPluginDir"] := expandDir(globalConfig["Plugins"]["ControllerPluginDir"])
    requiredFolders.Push(globalConfig["Plugins"]["ControllerPluginDir"])
}
if (globalConfig["Plugins"].Has("ProgramPluginDir") && globalConfig["Plugins"]["ProgramPluginDir"] != "") {
    globalConfig["Plugins"]["ProgramPluginDir"] := expandDir(globalConfig["Plugins"]["ProgramPluginDir"])
    requiredFolders.Push(globalConfig["Plugins"]["ProgramPluginDir"])
}

for value in requiredFolders {
    if (!DirExist(value)) {
        DirCreate value
    }
}

; load process monitoring library for checking process lists
processLib := dllLoadLib("psapi.dll")

; load gdi library for screenshot thumbnails
gdiLib := dllLoadLib("GdiPlus.dll")

gdiToken  := 0
gdiBuffer := Buffer(24, 0)
NumPut("Char", 1, gdiBuffer.Ptr, 0)
DllCall("GdiPlus\GdiplusStartup", "UPtr*", gdiToken, "Ptr", gdiBuffer.Ptr, "Ptr", 0)

; load nvidia library for gpu monitoring
if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) { 
    try {
        nvLib := dllLoadLib("nvapi64.dll")
        DllCall(DllCall("nvapi64.dll\nvapi_QueryInterface", "UInt", 0x0150E828, "CDecl UPtr"), "CDecl")
    }
    catch {
        globalConfig["GUI"]["EnablePauseGPUMonitor"] := false
    }
}

; ----- INITIALIZE GLOBALSTATUS -----
; whether or not pause screen is shown 
globalStatus["pause"] := false
; whether or not script is suspended (no actions running, changable in pause menu)
globalStatus["suspendScript"] := false
; whether or not script is in keyboard & mouse mode
globalStatus["kbmmode"] := false
; whether or not script is in desktop mode
globalStatus["desktopmode"] := false

; current name of programs focused & running, used to get config -> setup hotkeys & background actions
globalStatus["currProgram"] := ""
; current active gui
globalStatus["currGui"] := ""

; load screen info
globalStatus["loadscreen"] := Map()
globalStatus["loadscreen"]["show"] := false
globalStatus["loadscreen"]["text"] := (globalConfig["GUI"].Has("DefaultLoadText")) 
    ? globalConfig["GUI"]["DefaultLoadText"] : "Now Loading..."

; error info
globalStatus["error"] := Map()
globalStatus["error"]["show"] := false
globalStatus["error"]["hwnd"] := 0

; hotkey info
globalStatus["controller"] := Map()
globalStatus["controller"]["hotkeys"]    := Map()
globalStatus["controller"]["mouse"]      := Map()
globalStatus["controller"]["buffer"]     := []
globalStatus["controller"]["buttonTime"] := 70

; ----- INITIALIZE PROGRAM/CONSOLE CONFIGS -----
; read program configs from ConfigDir
if (globalConfig["Plugins"].Has("ProgramPluginDir") && globalConfig["Plugins"]["ProgramPluginDir"] != "") {
    loop files validateDir(globalConfig["Plugins"]["ProgramPluginDir"]) . "*.json", "FR" {
        tempConfig := readConfig(A_LoopFileFullPath,, "json")
        tempConfig.cleanAllItems(true)

        if (tempConfig.items.Has("id") || tempConfig.items["id"] != "") {

            ; convert array of exe to map for efficient lookup
            if (tempConfig.items.Has("exe") && Type(tempConfig.items["exe"]) = "Array") {
                tempMap := Map()

                for item in tempConfig.items["exe"] {
                    tempMap[item] := ""
                }

                tempConfig.items["exe"] := tempMap
            }

            ; convert array of wndw to map for efficient lookup
            if (tempConfig.items.Has("wndw") && Type(tempConfig.items["wndw"]) = "Array") {
                tempMap := Map()

                for item in tempConfig.items["wndw"] {
                    tempMap[item] := ""
                }

                tempConfig.items["wndw"] := tempMap
            }
            
            globalPrograms[tempConfig.items["id"]] := tempConfig.toMap()
        }
        else {
            ErrorMsg(A_LoopFileFullPath . " does not have required 'id' parameter")
        }
    }
}

; read console configs from ConfigDir
if (globalConfig["Plugins"].Has("ConsolePluginDir") && globalConfig["Plugins"]["ConsolePluginDir"] != "") {
    loop files validateDir(globalConfig["Plugins"]["ConsolePluginDir"]) . "*.json", "FR" {
        tempConfig := readConfig(A_LoopFileFullPath,, "json")
        tempConfig.cleanAllItems(true)

        if (tempConfig.items.Has("id") || tempConfig.items["id"] != "") {
            globalConsoles[tempConfig.items["id"]] := tempConfig.toMap()
        }
        else {
            ErrorMsg(A_LoopFileFullPath . " does not have required 'id' parameter")
        }
    }
}

if (globalConfig["Plugins"].Has("ControllerPluginDir") && globalConfig["Plugins"]["ControllerPluginDir"] != "") {
    loop files validateDir(globalConfig["Plugins"]["ControllerPluginDir"]) . "*.json", "FR" {
        tempConfig := readConfig(A_LoopFileFullPath,, "json")
        tempConfig.cleanAllItems(true)

        if ((tempConfig.items.Has("id") || tempConfig.items["id"] != "")
            && (tempConfig.items.Has("className") || tempConfig.items["className"] != "")
            && (tempConfig.items.Has("maxConnected") || tempConfig.items["maxConnected"] != "")) {
            controlID := tempConfig.items["id"]

            globalControlConfigs[controlID] := tempConfig.toMap()
            globalControllers[controlID] := []

            controllerInit := runFunction(globalControlConfigs[controlID]["initialize"])
            loop tempConfig.items["maxConnected"] {
                globalControllers[controlID].Push(
                    %globalControlConfigs[controlID]["className"]%(controllerInit, A_Index - 1, globalControlConfigs[controlID])
                )
            }

            globalThreads["controller-" . controlID] := controllerThread(
                controlID,
                ObjPtrAddRef(globalConfig), 
                ObjPtrAddRef(globalStatus), 
                ObjPtrAddRef(globalPrograms), 
                ObjPtrAddRef(globalConsoles), 
                ObjPtrAddRef(globalRunning), 
                ObjPtrAddRef(globalGuis),
                ObjPtrAddRef(globalControllers),
                ObjPtrAddRef(globalControlConfigs)
            )
        }
        else {
            ErrorMsg(A_LoopFileFullPath . " does not have required 'id' parameter")
        }
    }
}

; ----- INITIALIZE THREADS -----
; configure objects to be used in a thread-safe manner
;  read-only objects can be used w/ ObjPtrAddRef 
;  read/write objects must be a buffer ptr w/ custom getters/setters

; ----- PARSE START ARGS -----
for item in globalConfig["StartArgs"] {
    if (item = "-backup") {
        if (globalStatus["kbmmode"]) {
            enableKBMMode()
        }
        if (globalStatus["desktopmode"]) {
            enableDesktopMode()
        }
    }
}

if (!inArray("-quiet", globalConfig["StartArgs"]) && globalConfig["GUI"].Has("EnableLoadScreen") && globalConfig["GUI"]["EnableLoadScreen"]) {
    createLoadScreen()
}

globalThreads["action"] := actionThread(
    ObjPtrAddRef(globalConfig), 
    ObjPtrAddRef(globalStatus), 
    ObjPtrAddRef(globalPrograms), 
    ObjPtrAddRef(globalConsoles), 
    ObjPtrAddRef(globalRunning), 
    ObjPtrAddRef(globalGuis),
    ObjPtrAddRef(globalControllers),
    ObjPtrAddRef(globalControlConfigs)
)

Sleep(100)

; ----- BOOT -----
if (!inArray("-backup", globalConfig["StartArgs"])) {
    MsgBox("ih")
    try customBoot()
}

; enables the OnMessage listener for send2Main
OnMessage(MESSAGE_VAL, HandleMessage)

; initial backup of status
statusBackup()

; ----- MAIN THREAD LOOP -----
; the main thread monitors the other threads, checks that looper is running
; the main thread launches programs with appropriate settings and does any non-hotkey looping actions in the background
; probably going to need to figure out updating loadscreen?

forceMaintain  := globalConfig["General"].Has("ForceMaintainMain") && globalConfig["General"]["ForceMaintainMain"]
forceActivate  := globalConfig["General"].Has("ForceActivateWindow") && globalConfig["General"]["ForceActivateWindow"]
bypassFirewall := globalConfig["General"].Has("BypassFirewallPrompt") && globalConfig["General"]["BypassFirewallPrompt"]
hideTaskbar    := globalConfig["General"].Has("HideTaskbar") && globalConfig["General"]["HideTaskbar"]

checkErrors    := globalConfig["Plugins"].Has("ErrorList") && globalConfig["Plugins"]["ErrorList"] != ""

loopSleep      := Round(globalConfig["General"]["AvgLoopSleep"])

delayCount := 0
maxDelayCount := 15

mouseHidden := false

hotkeySource := ""
loop {
    currSuspended := globalStatus["suspendScript"]

    if (!currSuspended) {
        ; check that sound driver hasn't crashed
        if (SoundGetMute()) {
            SoundSetMute(false)
        }
    
        ; automatically accept firewall
        if (bypassFirewall && WinShown("Windows Security Alert")) {
            WinActivate("Windows Security Alert")
            Sleep(50)
            Send "{Enter}"
        }
    
        ; check that taskbar is hidden
        if (hideTaskbar && WinShown("ahk_class Shell_TrayWnd")) {
            try WinHide "ahk_class Shell_TrayWnd"
        }
    }
    
    Sleep(loopSleep)

    activeSet := false
    hotkeySource := ""

    currHotkeys := defaultHotkeys(globalConfig)
    currMouse   := Map()

    ; --- CHECK DESKTOP MODE ---
    if (globalStatus["desktopmode"]) {
        currHotkeys := desktopmodeHotkeys()
        currMouse   := kbmmodeMouse()

        activeSet := true
        hotkeySource := "desktopmode"
    }

    ; --- CHECK OVERRIDE ---
    currError := globalStatus["error"]["show"]

    ; if errors should be detected, set error here
    if (!currError && checkErrors && !currSuspended) {
        resetTMM := A_TitleMatchMode

        SetTitleMatchMode 2
        for key, value in globalConfig["Plugins"]["ErrorList"] {

            wndwHWND := WinShown(value)
            if (!wndwHWND) {
                wndwHWND := WinShown(StrLower(value))
            }

            if (wndwHWND > 0) {
                globalStatus["error"]["show"] := true
                globalStatus["error"]["hwnd"] := wndwHWND
                
                break
            }
        }
        SetTitleMatchMode resetTMM
    }

    if (currError && !currSuspended) {
        errorHwnd := globalStatus["error"]["hwnd"]

        if (WinShown("ahk_id " errorHwnd)) {
            if (!activeSet) {
                if (forceActivate && !WinActive("ahk_id " errorHwnd)) {
                    WinActivate("ahk_id " errorHwnd)
                }

                activeSet := true
            }

            ; REPLACE THIS W/ KB & M MODE
            if (hotkeySource = "") {
                currHotkeys := addHotkeys(currHotkeys, kbmmodeHotkeys())
                currMouse   := kbmmodeMouse()

                hotkeySource := "error"
            }
        }
        else {
            globalStatus["error"]["show"] := false
            globalStatus["error"]["hwnd"] := 0
        }
    }

    ; --- CHECK LOAD SCREEN ---
    if (globalStatus["loadscreen"]["show"] && !activeSet && !currSuspended) {
        activateLoadScreen()

        for key, value in currHotkeys {
            if (StrLower(value) = "pausemenu") {
                currHotkeys.Delete(key)
                break
            }
        }
        
        activeSet := true
        hotkeySource := "load"
    }

    ; --- CHECK ALL OPEN ---
    currProgram := globalStatus["currProgram"]
    currGui     := globalStatus["currGui"]

    if ((delayCount > maxDelayCount || (currProgram = "" && currGui = "")) && !currSuspended) {
        checkAllGuis()

        mostRecentGui := getMostRecentGui()
        if (mostRecentGui != currGui) {
            globalStatus["currGui"] := mostRecentGui
        }

        checkAllPrograms()

        mostRecentProgram := getMostRecentProgram()
        if (mostRecentProgram != currProgram) {
            setCurrentProgram(mostRecentProgram)
        }
    }

    ; --- CHECK OPEN GUIS ---
    if (currGui != "") {
        if (globalGuis.Has(currGui) && WinShown(currGui)) {
            if (!activeSet && globalGuis[currGui].allowFocus) {
                if (forceActivate && !WinActive(currGui)) {
                    try WinActivate(currGui)
                }

                activeSet := true
            }

            if (hotkeySource = "") {
                if (globalGuis[currGui].hotkeys.Count > 0) {
                    currHotkeys := addHotkeys(currHotkeys, globalGuis[currGui].hotkeys)
                    globalStatus["controller"]["buttonTime"] := 0
                }

                for key, value in currHotkeys {
                    if (!globalGuis[currGui].allowPause && StrLower(value) = "pausemenu") {
                        currHotkeys.Delete(key)
                        break
                    }
                }

                if (globalGuis[currGui].mouse.Count > 0) {
                    currMouse := globalGuis[currGui].mouse
                }

                hotkeySource := currGui
            }
        } 
        else {
            if (globalGuis.Has(currGui)) {
                globalGuis[currGui].Destroy()
                globalGuis.Delete(currGui)
            }

            checkAllGuis()

            mostRecentGui := getMostRecentGui()
            if (mostRecentGui != currGui) {
                globalStatus["currGui"] := mostRecentGui

                continue
            }
            else {
                globalStatus["currGui"] := ""
            }
        }
    }

    ; --- CHECK KB & MOUSE MODE ---
    if (globalStatus["kbmmode"] && hotkeySource = "") {
        currHotkeys := addHotkeys(currHotkeys, kbmmodeHotkeys())
        currMouse   := kbmmodeMouse()

        activeSet := true
        hotkeySource := "kbmmode"
    }

    ; --- CHECK OPEN PROGRAMS ---
    if (currProgram != "" && !currSuspended) {
        if (globalRunning.Has(currProgram)) {
            if (globalRunning[currProgram].exists()) {
                if (!activeSet) {
                    if (forceActivate) {
                        if (globalRunning[currProgram].hungCount = 0) {
                            try globalRunning[currProgram].restore()
                        }
                    }
                    else {
                        try globalRunning[currProgram].resume()
                    }

                    activeSet := true
                }

                if (hotkeySource = "") {
                    if (globalRunning[currProgram].hotkeys.Count > 0) {
                        currHotkeys := addHotkeys(currHotkeys, globalRunning[currProgram].hotkeys)
                        globalStatus["controller"]["buttonTime"] := globalRunning[currProgram].hotkeyButtonTime
                    }

                    for key, value in currHotkeys {
                        if (!globalRunning[currProgram].allowPause && StrLower(value) = "pausemenu") {
                            currHotkeys.Delete(key)
                            break
                        }
                    }

                    if (globalRunning[currProgram].mouse.Count > 0) {
                        currMouse := globalRunning[currProgram].mouse
                    }
                                            
                    hotkeySource := currProgram
                }
            }
            else {
                checkAllPrograms()

                mostRecentProgram := getMostRecentProgram()
                if (mostRecentProgram != currProgram) {
                    setCurrentProgram(mostRecentProgram)                    
                    
                    continue
                }
                else {
                    globalStatus["currProgram"] := ""
                }
            }
        } 
        else {
            createProgram(currProgram, false, false)
        }   
    }

    ; --- UPDATE HOTKEYS & MOUSE ---
    globalStatus["controller"]["hotkeys"] := currHotkeys
    globalStatus["controller"]["mouse"]   := currMouse

    ; --- BACKUP ---
    if (statusUpdated()) {
        statusBackup()
    }

    if (delayCount > maxDelayCount) {
        ; try {
        ;     controllerThreadRef.FuncPtr("")
        ; }
        ; catch {
        ;     controllerThreadRef := controllerThread(ObjPtrAddRef(globalConfig), globalControllers, xLibrary)
        ;     Sleep(100)
        ; }
        
        ; try {
        ;     hotkeyThreadRef.FuncPtr("")
        ; }
        ; catch {
        ;     hotkeyThreadRef := hotkeyThread(ObjPtrAddRef(globalConfig), ObjPtrAddRef(globalStatus), globalControllers, ObjPtrAddRef(globalRunning))
        ;     Sleep(100)
        ; }

        ; ; check that function thread is running
        ; functionThreadHWND := WinHidden("functionThread")
        ; if (!functionThreadHWND) {
        ;     functionThreadRef := functionThread(ObjPtrAddRef(globalConfig), ObjPtrAddRef(globalStatus))
        ;     Sleep(100)
        ; }
        ; else if (DllCall("IsHungAppWindow", "Ptr", functionThreadHWND)) {
        ;     ProcessKill(functionThreadHWND)
        ; }

        ; check that looper is running
        if (forceMaintain && !WinHidden(MAINLOOP)) {
            Run A_AhkPath . A_Space . "mainLooper.ahk", A_ScriptDir, "Hide"
        }

        delayCount := 0
    }
    
    delayCount += 1
    Sleep(loopSleep)
}

; handle when message comes in from send2Main
HandleMessage(wParam, lParam, msg, hwnd) {
    global globalConfig
    global globalRunning

    message := getMessage(wParam, lParam, msg, hwnd)

    if (message.Length = 0) {
        return
    }

    currProgram := globalStatus["currProgram"]

    ; do something based on external message (like launching app)
    ; style of message should probably be "Run Chrome" or "Run RetroArch Playstation C:\Rom\Crash"
    if (SubStr(StrLower(message[1]), 1, 7) = "minthen") {
        if (currProgram != "") {
            globalRunning[currProgram].minimize()
            Sleep(200)
        }

        message[1] := SubStr(message[1], 8)
    }
    else {
        setLoadScreen((globalConfig["GUI"].Has("DefaultLoadText")) ? globalConfig["GUI"]["DefaultLoadText"] : "Now Loading...")
        Sleep(100)
    }

    if (StrLower(message[1]) = "run") {
        message.RemoveAt(1)
        createProgram(message)
    }
    else if (StrLower(message[1]) = "console") {           
        message.RemoveAt(1)
        createConsole(message)
    }
    else if (StrLower(message[1]) = "nuclear") {
        if (globalStatus["error"]["show"]) {
            try ProcessKill(WinGetPID("ahk_id " globalStatus["error"]["hwnd"]))
        }

        if (currProgram != "" && globalRunning[currProgram].exists()) {
            try ProcessKill(globalRunning[currProgram].getPID())
        }

        ; need to think about if this is necessary?
        ; i mean if this is working main isn't crashed right?
        ; ProcessKill(MAINNAME)
    }
    else {
        try runFunction(joinArray(message))
    }
}

; wait for current program to resume before requested program function
WaitProgramResume(id, function, args) {
    global globalRunning

    if (!globalRunning.Has(id) || globalStatus["currProgram"] != id) {
        return
    }

    this := globalRunning[id]
    
    if (!this.exists()) {
        return
    }

    if (!this.paused) {
        try this.%function%(args*)
    }
    else { 
        SetTimer(WaitProgramResume.Bind(id, function, args), -50)
    }

    return
}

; clean shutdown of script
ShutdownScript(restoreTaskbar := true) {
    global globalThreads
    global globalControlConfigs

    ; disable message listener
    OnMessage(MESSAGE_VAL, HandleMessage, 0)

    setLoadScreen("Please Wait...")

    ; tell the threads to close
    for key, value in globalThreads {
        value.exitThread := true
        Sleep(100)
    }

    for key, value in globalControlConfigs {
        runFunction(value["destroy"])
    }

    dllFreeLib(processLib)
    
    DllCall("GdiPlus\GdiplusShutdown", "Ptr", gdiToken)
    dllFreeLib(gdiLib)
    
    if (globalConfig["GUI"].Has("EnablePauseGPUMonitor") && globalConfig["GUI"]["EnablePauseGPUMonitor"]) {
        dllFreeLib(nvLib)
    }
    
    ; reset dpi scaling
    DllCall("SetThreadDpiAwarenessContext", "Ptr", prevDPIContext, "Ptr")
    
    ; reset taskbar
    if (restoreTaskbar && !WinShown("ahk_class Shell_TrayWnd") && WinHidden("ahk_class Shell_TrayWnd")) {
        try WinShow "ahk_class Shell_TrayWnd"
    }
}

; exits the script entirely, including looper
ExitScript() {
    global globalConfig

    statusBackup()

    if (WinHidden(MAINLOOP) && globalConfig["General"].Has("ForceMaintainMain") 
        && globalConfig["General"]["ForceMaintainMain"]) {

        ProcessWinClose(MAINLOOP)
    }

    ShutdownScript()
    Sleep(500)

    ExitApp()
}

; resets the script, loading from statusBackup
ResetScript() {
    global globalConfig

    statusBackup()

    if (!globalConfig["General"].Has("ForceMaintainMain") 
        || (globalConfig["General"].Has("ForceMaintainMain") && !globalConfig["General"]["ForceMaintainMain"])) {

        Run A_AhkPath . A_Space . "mainLooper.ahk 1", A_ScriptDir, "Hide"
    }
    else if (!WinHidden(MAINLOOP)) {
        Run A_AhkPath . A_Space . "mainLooper.ahk", A_ScriptDir, "Hide"
    }

    ShutdownScript()
    Sleep(500)

    ExitApp()
}

; clean up running programs & shutdown
PowerOff() {
    exitAllPrograms()
    Sleep(500)
    
    ShutdownScript()
    Sleep(500)

    Shutdown 1
    ExitApp()
}

; clean up running programs & restart
Restart() {
    exitAllPrograms()
    Sleep(500)

    ShutdownScript()
    Sleep(500)

    Shutdown 2
    ExitApp()
}

; clean up running programs & sleep -> restarting script after
Standby() {
    if (WinHidden(MAINLOOP)) {
        ProcessKill(MAINLOOP)
    }
    
    exitAllPrograms()
    setLoadScreen("Please Wait...")
    Sleep(1500)
    
    DllCall("powrprof\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)
    Sleep(5000)
    
    ShutdownScript()
    Sleep(1500)

    Run A_AhkPath . A_Space . "mainLooper.ahk -clean", A_ScriptDir, "Hide"
    ExitApp()
}