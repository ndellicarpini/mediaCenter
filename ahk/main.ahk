#SingleInstance Force
; #WinActivateForce

; ----- DO NOT EDIT: DYNAMIC INCLUDE START -----
#Include plugins\ahk\boot.ahk
#Include plugins\ahk\LOADSC~1.AHK
#Include plugins\inputs\xinput\xinput.ahk
#Include plugins\programs\AMAZON~1\AMAZON~1.AHK
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
#Include plugins\programs\RETROA~1\RETROA~1.AHK
#Include plugins\programs\rpcs3\rpcs3.ahk
#Include plugins\programs\ryujinx\ryujinx.ahk
#Include plugins\programs\steam\steam.ahk
#Include plugins\programs\steam\STEAMG~1.AHK
#Include plugins\programs\wingame\wingame.ahk
#Include plugins\programs\xemu\xemu.ahk
#Include plugins\programs\xenia\xenia.ahk
; -----  DO NOT EDIT: DYNAMIC INCLUDE END  -----

#Include lib\confio.ahk
#Include lib\std.ahk
#Include lib\messaging.ahk
#Include lib\program\program.ahk
#Include lib\program\emulator.ahk
#Include lib\data.ahk
#Include lib\input\hotkeys.ahk
#Include lib\input\desktop.ahk
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

SetKeyDelay 50, 100
CoordMode "Mouse", "Screen"
Critical("Off")

; set dpi scaling per window
prevDPIContext := DllCall("SetThreadDpiAwarenessContext", "Ptr", -3, "Ptr")

SetCurrentWinTitle(MAINNAME)

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

; set overrides to case insensitive
if (globalConfig.Has("Overrides")) {
    overrides := ObjDeepClone(globalCOnfig["Overrides"])

    globalConfig["Overrides"] := Map()
    globalConfig["Overrides"].CaseSense := "Off"

    for key, value in overrides {
        globalConfig["Overrides"][key] := value
    }
}

; set gui variables
setGUIConstants()

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
globalStatus["loadscreen"]["enable"] := false
globalStatus["loadscreen"]["overrideWNDW"] := false
globalStatus["loadscreen"]["text"] := (globalConfig["GUI"].Has("DefaultLoadText")) 
    ? globalConfig["GUI"]["DefaultLoadText"] : "Now Loading..."

; hotkey info
globalStatus["input"] := Map()
globalStatus["input"]["hotkeys"]    := Map()
globalStatus["input"]["mouse"]      := Map()
globalStatus["input"]["source"]     := ""
globalStatus["input"]["buttonTime"] := 70
globalStatus["input"]["buffer"]     := []

; ----- INITIALIZE PROGRAM/CONSOLE/INPUT CONFIGS -----
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
                    tempMap[StrLower(item)] := ""
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

; read input configs from plugins & start a unique inputThread for each individual config
if (globalConfig["Plugins"].Has("InputPluginDir") && globalConfig["Plugins"]["InputPluginDir"] != "") {
    loop files validateDir(globalConfig["Plugins"]["InputPluginDir"]) . "*.json", "FR" {
        tempConfig := readConfig(A_LoopFileFullPath,, "json")
        tempConfig.cleanAllItems(true)

        if ((tempConfig.items.Has("id") || tempConfig.items["id"] != "")
            && (tempConfig.items.Has("className") || tempConfig.items["className"] != "")
            && (tempConfig.items.Has("maxConnected") || tempConfig.items["maxConnected"] != "")) {
            
            controlID := tempConfig.items["id"]

            globalInputConfigs[controlID] := tempConfig.toMap()
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
        statusRestore()

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
    }
}

; create loadscreen if appropriate
if (!inArray("-quiet", globalConfig["StartArgs"]) && globalConfig["GUI"].Has("EnableLoadScreen") && globalConfig["GUI"]["EnableLoadScreen"]) {
    globalStatus["loadscreen"]["enable"] := true
}

; start non-input threads
globalThreads["hotkey"] := hotkeyThread(
    ObjPtrAddRef(globalConfig), 
    ObjPtrAddRef(globalStatus),
    ObjPtrAddRef(globalInputConfigs),
    ObjPtrAddRef(globalRunning),
)

globalThreads["misc"] := miscThread(
    ObjPtrAddRef(globalConfig), 
    ObjPtrAddRef(globalStatus)
)

Sleep(100)

; ----- BOOT -----
if (!inArray("-backup", globalConfig["StartArgs"]) && globalConfig.Has("Overrides") 
    && globalConfig["Overrides"].Has("boot") && globalConfig["Overrides"]["boot"] != "") {
    
    try %globalConfig["Overrides"]["boot"]%()
}

; enables the OnMessage listener for send2Main
global send2MainBuffer := []
OnMessage(MESSAGE_VAL, HandleMessage)

; initial backup of status
statusBackup()

; ----- MAIN THREAD LOOP -----
; the main thread monitors the other threads, checks that maintainer is running
; the main thread launches programs with appropriate settings and does any non-hotkey looping actions in the background

forceMaintain  := globalConfig["General"].Has("ForceMaintainMain") && globalConfig["General"]["ForceMaintainMain"]
forceActivate  := globalConfig["General"].Has("ForceActivateWindow") && globalConfig["General"]["ForceActivateWindow"]
checkErrors    := globalConfig["Plugins"].Has("ErrorList") && globalConfig["Plugins"]["ErrorList"] != ""

loopSleep      := Round(globalConfig["General"]["AvgLoopSleep"] * 2)

; set timer to check the input buffer
SetTimer(InputBufferTimer, 35)

delayCount := 0
maxDelayCount := 15

mouseHidden := false

loop {
    activeSet := false
    hotkeySource := ""

    currSuspended   := globalStatus["suspendScript"]
    currDesktopMode := globalStatus["desktopmode"]

    ; --- CHECK SEND2MAIN BUFFER ---
    if (send2MainBuffer.Length > 0 && !currSuspended) {
        message := send2MainBuffer.Pop()
        if (message = "" || message.Length = 0) {
            continue
        } 

        if (StrLower(message[1]) = "run") {
            message.RemoveAt(1)
            createProgram(message)
        }
        else if (StrLower(message[1]) = "console") {           
            message.RemoveAt(1)
            createConsole(message)
        }
        else {
            try {
                runFunction(message)
            }
            catch {
                globalStatus["input"]["buffer"].Push(joinArray(message))
            }
        }

        Sleep(loopSleep)
        continue
    }

    ; --- CHECK LOAD SCREEN ---
    if (globalStatus["loadscreen"]["show"] && !activeSet && !currSuspended && !currDesktopMode) {             
        activeSet := true
        hotkeySource := "loadscreen"

        if (globalGuis.Has("pause")) {
            globalGuis["pause"].Destroy()
        }
    }

    ; --- CHECK OPEN GUIS ---
    currGui := globalStatus["currGui"]

    if (currGui != "") {
        currWNDW := INTERFACES[currGui]["wndw"]
        if (globalGuis.Has(currGui) && WinShown(currWNDW)) {
            if (globalGuis[currGui].allowFocus) {
                if (!activeSet) {
                    if (forceActivate && !WinActive(currWNDW)) {
                        try WinActivate(currWNDW)
                    }
    
                    activeSet := true
                }
    
                if (hotkeySource = "") {
                    hotkeySource := currGui
                }
            }
        } 
        else {
            if (globalGuis.Has(currGui)) {
                globalGuis[currGui].Destroy()
                globalGuis.Delete(currGui)
                
                Sleep(50)

                if (WinShown(currWNDW)) {
                    WinClose(currWNDW)
                }
            }

            checkAllGuis()

            mostRecentGui := getMostRecentGui()
            if (mostRecentGui != currGui) {
                setCurrentGui(mostRecentGui)

                continue
            }
            else {
                globalStatus["currGui"] := ""
            }
        }
    }

    ; --- CHECK SUSPENDED HOTKEYS ---
    if (hotkeySource = "" && currSuspended) {
        hotkeySource := "suspended"
    }

    ; --- CHECK DESKTOP MODE / KB & MOUSE MODE ---
    if (hotkeySource = "") {
        if (globalStatus["desktopmode"]) {
            activeSet := true
            hotkeySource := "desktopmode"
        }
        else if (globalStatus["kbmmode"]) {
            hotkeySource := "kbmmode"
        }
    }

    ; --- CHECK OPEN PROGRAMS ---
    currProgram := globalStatus["currProgram"]

    if (currProgram != "" && !currSuspended && !currDesktopMode) {
        if (globalRunning.Has(currProgram)) {
            if (globalRunning[currProgram].exists(false, true)) {
                if (!activeSet) {
                    if (forceActivate) {
                        try globalRunning[currProgram].restore()
                    }
                    else {
                        try globalRunning[currProgram].resume()
                    }

                    activeSet := true
                }

                if (hotkeySource = "") {                                                                    
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

    ; --- CHECK ALL OPEN PROGRAMS / GUIS ---
    if ((delayCount > maxDelayCount || !activeSet) && !currSuspended) {
        checkAllGuis()

        mostRecentGui := getMostRecentGui()
        if (mostRecentGui != currGui) {
            setCurrentGui(mostRecentGui)

            continue
        }

        checkAllPrograms()

        mostRecentProgram := getMostRecentProgram()
        if (mostRecentProgram != currProgram) {
            setCurrentProgram(mostRecentProgram)

            continue
        }
    }

    ; update hotkey source
    globalStatus["input"]["source"] := hotkeySource

    ; check if status has updated & backup
    if (statusUpdated()) {
        statusBackup()
    }

    ; every maxDelayCount loops -> check threads & maintainer
    if (delayCount > maxDelayCount) {
        for key, value in globalThreads {
            ; if thread crashed, reset main
            try {
                value.FuncPtr("")
            }
            catch {
                ExitApp()
            }
        }

        ; check that maintainer is running
        if (forceMaintain && !WinHidden(MAINLOOP)) {
            Run A_AhkPath . A_Space . "maintainer.ahk", A_ScriptDir, "Hide"
        }

        delayCount := 0
    }
    
    delayCount += 1
    Sleep(loopSleep)
}

; run function from top of input buffer
InputBufferTimer() {
    global globalConfig
    global globalStatus        
    global globalRunning       
    global globalGuis

    if (globalStatus["input"]["buffer"].Length = 0) {
        return
    }
    
    bufferedFunc := globalStatus["input"]["buffer"].Pop()
    hotkeySource := globalStatus["input"]["source"]
    
    currProgram := globalStatus["currProgram"]
    currGui     := globalStatus["currGui"]
    currLoad    := globalStatus["loadscreen"]["show"]
    currKBMM    := globalStatus["kbmmode"]
    currDesktop := globalStatus["desktopmode"]

    ; mismatched currHotkeys & status, ignore message
    if ((hotkeySource != currProgram && hotkeySource != currGui)
        && (hotkeySource = "load" && !currLoad) 
        && (hotkeySource = "kbmmode" && !currKBMM) 
        && (hotkeySource = "desktopmode" && !currDesktop)) {

        globalStatus["input"]["buffer"] := []
        return
    }

    ; update pause status & create/destroy pause menu
    if (StrLower(bufferedFunc) = "pausemenu") {     
        if (currLoad || (globalConfig["GUI"].Has("EnablePauseMenu") && globalConfig["GUI"]["EnablePauseMenu"] = false)
            || (currProgram != "" && hotkeySource = currProgram && !globalRunning[currProgram].allowPause)
            || (currGui != "" && hotkeySource = currGui && !globalGuis[currGui].allowPause)) {

            return
        }

        if (!globalGuis.Has("pause")) {
            createInterface("pause")
        }
        else {
            globalGuis["pause"].Destroy()
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
        tempArr  := StrSplit(bufferedFunc, A_Space)
        tempFunc := StrReplace(tempArr.RemoveAt(1), "gui.", "") 

        try globalGuis[currGui].%tempFunc%(tempArr*)
    }

    ; run current program function
    else if (StrLower(SubStr(bufferedFunc, 1, 8)) = "program.") {
        if (globalStatus["suspendScript"]) {
            return
        }

        tempArr  := StrSplit(bufferedFunc, A_Space)
        tempFunc := StrReplace(tempArr.RemoveAt(1), "program.", "")
        
        if (tempFunc = "exit") {
           if (currProgram != "" && globalRunning[currProgram].allowExit) {
                try globalRunning[currProgram].exit()
    
                if (globalRunning.Has(currProgram) && !globalRunning[currProgram].exists()) {
                    globalStatus["currProgram"] := ""
                }
            }
        }
        else {
            try globalRunning[currProgram].%tempFunc%(tempArr*)
        }
    }

    ; run function
    else if (bufferedFunc != "") {
        try runFunction(bufferedFunc)
    }

    return
}

; handle when message comes in from send2Main
; style of message should probably be "Run Chrome" or "Run RetroArch Playstation C:\Rom\Crash"
HandleMessage(wParam, lParam, msg, hwnd) {
    global send2MainBuffer
    global globalConfig
    global globalStatus
    global globalRunning

    message := getMessage(wParam, lParam, msg, hwnd)

    if (message.Length = 0 || globalStatus["suspendScript"]) {
        return
    }

    currProgram := globalStatus["currProgram"]

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
    else if (SubStr(StrLower(message[1]), 1, 7) = "minthen") {
        if (currProgram != "") {
            globalRunning[currProgram].minimize()
            Sleep(200)
        }

        message[1] := SubStr(message[1], 8)
    }

    ; launching a new program -> prioritize showing the load screen
    if (StrLower(message[1]) = "run" || StrLower(message[1]) = "console") {
        activateLoadScreen()
    } 

    ; buffer all actions bc shit gets wacky being initialized in msg handler
    send2MainBuffer.Push(message)
}

; clean shutdown of script
ShutdownScript(restoreTaskbar := true) {
    global globalThreads

    ; disable input buffer
    SetTimer(InputBufferTimer, 0)

    ; disable message listener
    OnMessage(MESSAGE_VAL, HandleMessage, 0)

    setLoadScreen("Please Wait...")

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

    ; tell the threads to close
    for key, value in globalThreads {
        value.exitThread := true
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

    Critical("On")

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

    Critical("On")

    statusBackup()

    if (!globalConfig["General"].Has("ForceMaintainMain") 
        || (globalConfig["General"].Has("ForceMaintainMain") && !globalConfig["General"]["ForceMaintainMain"])) {

        Run A_AhkPath . A_Space . "maintainer.ahk 1", A_ScriptDir, "Hide"
    }
    else if (!WinHidden(MAINLOOP)) {
        Run A_AhkPath . A_Space . "maintainer.ahk", A_ScriptDir, "Hide"
    }

    ShutdownScript()
    Sleep(500)

    ExitApp()
}

; clean up running programs & shutdown
PowerOff() {
    global globalConfig

    Critical("On")

    if (globalConfig["Plugins"].Has("DefaultProgram")) {
        globalConfig["Plugins"]["DefaultProgram"] := ""
    }
    
    exitAllPrograms()
    Sleep(500)
    
    ShutdownScript()
    Sleep(500)

    Shutdown 1
    ExitApp()
}

; clean up running programs & restart
Restart() {
    global globalConfig

    Critical("On")

    if (globalConfig["Plugins"].Has("DefaultProgram")) {
        globalConfig["Plugins"]["DefaultProgram"] := ""
    }

    exitAllPrograms()
    Sleep(500)

    ShutdownScript()
    Sleep(500)

    Shutdown 2
    ExitApp()
}

; clean up running programs & sleep -> restarting script after
Standby() {
    global globalConfig

    Critical("On")

    if (globalConfig["Plugins"].Has("DefaultProgram")) {
        globalConfig["Plugins"]["DefaultProgram"] := ""
    }

    if (WinHidden(MAINLOOP)) {
        ProcessWinClose(MAINLOOP)
    }
    
    exitAllPrograms()
    setLoadScreen("Please Wait...")
    Sleep(1000)
    
    DllCall("powrprof\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)
    Sleep(5000)

    ShutdownScript()
    Sleep(500)

    Run A_AhkPath . A_Space . "maintainer.ahk -clean", A_ScriptDir, "Hide"
    ExitApp()
}