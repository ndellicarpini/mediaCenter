; #SingleInstance Force
; #WinActivateForce

; ----- DO NOT EDIT: DYNAMIC INCLUDE START -----
#Include LIB-CU~1\boot.ahk
#Include LIB-CU~1\EMULAT~1.AHK
#Include LIB-CU~1\load.ahk
#Include LIB-CU~1\programs.ahk
#Include LIB-CU~1\steam.ahk
#Include LIB-CU~1\wingames.ahk
; -----  DO NOT EDIT: DYNAMIC INCLUDE END  -----

#Include lib-mc\confio.ahk
#Include lib-mc\std.ahk
#Include lib-mc\xinput.ahk
#Include lib-mc\messaging.ahk
#Include lib-mc\program.ahk
#Include lib-mc\emulator.ahk
#Include lib-mc\data.ahk
#Include lib-mc\hotkeys.ahk
#Include lib-mc\desktop.ahk

#Include lib-mc\gui\std.ahk
#Include lib-mc\gui\constants.ahk
#Include lib-mc\gui\interface.ahk
#Include lib-mc\gui\choicedialog.ahk
#Include lib-mc\gui\loadscreen.ahk
#Include lib-mc\gui\pausemenu.ahk
#Include lib-mc\gui\volumemenu.ahk
#Include lib-mc\gui\controllermenu.ahk
#Include lib-mc\gui\programmenu.ahk
#Include lib-mc\gui\powermenu.ahk
#Include lib-mc\gui\keyboard.ahk

#Include lib-mc\mt\status.ahk
#Include lib-mc\mt\threads.ahk

SetKeyDelay 50, 100
CoordMode "Mouse", "Screen"
Critical "Off"

; set dpi scaling per window
prevDPIContext := DllCall("SetThreadDpiAwarenessContext", "Ptr", -3, "Ptr")

SetCurrentWinTitle(MAINNAME)
global MAINSCRIPTDIR := A_ScriptDir

global globalConfig
global globalStatus
global globalControllers
global globalPrograms
global globalRunning
global globalGuis

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

; set priority from config
if (mainConfig["General"].Has("MainPriority") && mainConfig["General"]["MainPriority"] != "") {
    ProcessSetPriority(mainConfig["General"]["MainPriority"])
}

; set gui variables
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

; load xinput libraray
xLibrary := dllLoadLib("xinput1_3.dll")

; load process monitoring library for checking process lists
processLib := dllLoadLib("psapi.dll")

; load gdi library for screenshot thumbnails
gdiLib := dllLoadLib("GdiPlus.dll")

gdiToken  := 0
gdiBuffer := Buffer(24, 0)
NumPut("Char", 1, gdiBuffer.Ptr, 0)
DllCall("GdiPlus\GdiplusStartup", "UPtr*", gdiToken, "Ptr", gdiBuffer.Ptr, "Ptr", 0)

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
setStatusParam("kbmmode", false, mainStatus.Ptr)
; whether or not script is in desktop mode
setStatusParam("desktopmode", false, mainStatus.Ptr)
; current name of programs focused & running, used to get config -> setup hotkeys & background actions
setStatusParam("currProgram", "", mainStatus.Ptr)
; load screen info
setStatusParam("loadShow", false, mainStatus.Ptr)
setStatusParam("loadText", (mainConfig["GUI"].Has("DefaultLoadText")) ? mainConfig["GUI"]["DefaultLoadText"] : "Now Loading...", mainStatus.Ptr)
; error info
setStatusParam("errorShow", false, mainStatus.Ptr)
setStatusParam("errorHwnd", 0, mainStatus.Ptr)
; time to hold a hotkey for it to trigger
setStatusParam("buttonTime", (mainConfig["Hotkeys"].Has("ButtonTime")) ? mainConfig["Hotkeys"]["ButtonTime"] : 70, mainStatus.Ptr)
; current hotkeys
setStatusParam("currHotkeys", Map(), mainStatus.Ptr)
; current mouse
setStatusParam("currMouse", Map(), mainStatus.Ptr)
; current active gui
setStatusParam("currGui", "", mainStatus.Ptr)
; some function that should be digested by a thread
setStatusParam("internalMessage", "", mainStatus.Ptr)


; ----- INITIALIZE GLOBALCONTROLLERS -----
mainControllers  := xInitBuffer(mainConfig["General"]["MaxXInputControllers"])


; ----- INITIALIZE PROGRAM/CONSOLE CONFIGS -----
globalRunning  := Map()
globalPrograms := Map()
globalConsoles := Map()
globalGuis     := Map()

; read program configs from ConfigDir
if (mainConfig["Programs"].Has("ProgramConfigDir") && mainConfig["Programs"]["ProgramConfigDir"] != "") {
    loop files validateDir(mainConfig["Programs"]["ProgramConfigDir"]) . "*", "FR" {
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
if (mainConfig["Programs"].Has("ConsoleConfigDir") && mainConfig["Programs"]["ConsoleConfigDir"] != "") {
    loop files validateDir(mainConfig["Programs"]["ConsoleConfigDir"]) . "*", "FR" {
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

; ----- INITIALIZE THREADS -----
; configure objects to be used in a thread-safe manner
;  read-only objects can be used w/ ObjShare 
;  read/write objects must be a buffer ptr w/ custom getters/setters
globalConfig      := ObjShare(ObjShare(mainConfig))
globalStatus      := mainStatus.Ptr
globalControllers := mainControllers.Ptr

; ----- PARSE START ARGS -----
for item in globalConfig["StartArgs"] {
    if (item = "-backup") {
        statusRestore()
        globalConfig["Boot"]["EnableBoot"] := false

        if (getStatusParam("kbmmode")) {
            enableKBMMode()
        }
        if (getStatusParam("desktopmode")) {
            enableDesktopMode()
        }
    }
}

if (!inArray("-quiet", globalConfig["StartArgs"]) && globalConfig["GUI"].Has("EnableLoadScreen") && globalConfig["GUI"]["EnableLoadScreen"]) {
    createLoadScreen()
}

; ----- START CONTROLLER THEAD -----
; this thread just updates the status of each controller in a loop
controllerThreadRef := controllerThread(ObjShare(mainConfig), globalControllers, xLibrary)
Sleep(100)

; ----- START HOTKEY THREAD -----
; this thread reads controller & status to determine what actions needing to be taken
; (ie. if currExecutable-Game = retroarch & Home+Start -> Save State)
hotkeyThreadRef := hotkeyThread(ObjShare(mainConfig), globalStatus, globalControllers)
Sleep(100)

; ----- START FUNCTION THREAD -----
; this thread runs functions requested as 'threadedFunction' in a separate thread
; this is a sacrificial thread, used for functions that have a high chance of hanging the script
functionThreadRef := functionThread(ObjShare(mainConfig), globalStatus)
Sleep(100)

; ----- BOOT -----
if (globalConfig["Boot"]["EnableBoot"]) {
    runFunction(globalConfig["Boot"]["BootFunction"])
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

checkErrors    := globalConfig["Programs"].Has("ErrorList") && globalConfig["Programs"]["ErrorList"] != ""

loopSleep      := Round(globalConfig["General"]["AvgLoopSleep"])

delayCount := 0
maxDelayCount := 15

mouseHidden := false

hotkeySource := ""
loop {
    currSuspended := getStatusParam("suspendScript")

    ; --- CHECK INTERNAL MESSAGE ---
    internalMessage := getStatusParam("internalMessage")
    if (internalMessage != "") {
        currProgram := getStatusParam("currProgram")
        currGui     := getStatusParam("currGui")
        currLoad    := getStatusParam("loadShow")
        currError   := getStatusParam("errorShow")
        currKBMM    := getStatusParam("kbmmode")
        currDesktop := getStatusParam("desktopmode")

        ; mismatched currHotkeys & status, ignore message
        if ((hotkeySource != currProgram && hotkeySource != currGui)
            && (hotkeySource = "load" && !currLoad) 
            && (hotkeySource = "error" && !currError) 
            && (hotkeySource = "kbmmode" && !currKBMM) 
            && (hotkeySource = "desktopmode" && !currDesktop)) {

            setStatusParam("internalMessage", "")
            continue
        }

        ; update pause status & create/destroy pause menu
        if (StrLower(internalMessage) = "pausemenu") {
            if (!globalGuis.Has(GUIPAUSETITLE)) {
                guiPauseMenu()
            }
            else {
                globalGuis[GUIPAUSETITLE].Destroy()
            }
        }

        ; exits the current error or program
        else if (StrLower(internalMessage) = "exitprogram") {
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
            else if (currProgram != "" && globalRunning[currProgram].allowExit) {
                try globalRunning[currProgram].exit()

                if (!globalRunning[currProgram].exists()) {
                    setStatusParam("currProgram", "")
                }
            }
        }

        ; run current gui funcion
        else if (StrLower(SubStr(internalMessage, 1, 4)) = "gui.") {
            tempArr  := StrSplit(internalMessage, A_Space)
            tempFunc := StrReplace(tempArr.RemoveAt(1), "gui.", "") 

            try globalGuis[currGui].%tempFunc%(tempArr*)
        }

        ; run current program function
        else if (StrLower(SubStr(internalMessage, 1, 8)) = "program.") {
            tempArr  := StrSplit(internalMessage, A_Space)
            tempFunc := StrReplace(tempArr.RemoveAt(1), "program.", "")
            
            if (tempFunc = "pause" || tempFunc = "resume" || tempFunc = "minimize" 
                || tempFunc = "exit" || tempFunc = "restore" || tempFunc = "launch") {

                try globalRunning[currProgram].%tempFunc%(tempArr*)
            }
            else {
                SetTimer(WaitProgramResume.Bind(currProgram, tempFunc, tempArr), -50)
            }
        }

        ; run function
        else {
            try runFunction(internalMessage)
        }

        ; reset message after processing
        if (getStatusParam("internalMessage") = internalMessage) {
            setStatusParam("internalMessage", "")
        }

        continue
    }

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
            Sleep(50)
        }
    }
    
    Sleep(loopSleep)

    activeSet := false
    hotkeySource := ""

    currHotkeys := defaultHotkeys(globalConfig)
    currMouse   := Map()

    ; --- CHECK DESKTOP MODE ---
    if (getStatusParam("desktopmode")) {
        currHotkeys := desktopmodeHotkeys()
        currMouse   := kbmmodeMouse()

        if (globalGuis.Has(GUIKEYBOARDTITLE)) {
            currHotkeys := addHotkeys(currHotkeys, globalGuis[GUIKEYBOARDTITLE].hotkeys)
        }

        activeSet := true
        hotkeySource := "desktopmode"
    }

    ; --- CHECK OVERRIDE ---
    currError := getStatusParam("errorShow")

    ; if errors should be detected, set error here
    if (!currError && checkErrors && !currSuspended) {
        resetTMM := A_TitleMatchMode

        SetTitleMatchMode 2
        for key, value in globalConfig["Programs"]["ErrorList"] {

            wndwHWND := WinShown(value)
            if (!wndwHWND) {
                wndwHWND := WinShown(StrLower(value))
            }

            if (wndwHWND > 0) {
                setStatusParam("errorShow", true)
                setStatusParam("errorHwnd", wndwHWND)
                
                break
            }
        }
        SetTitleMatchMode resetTMM
    }

    if (currError && !currSuspended) {
        errorHwnd := getStatusParam("errorHwnd")

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
            setStatusParam("errorShow", false)
            setStatusParam("errorHwnd", 0)
        }
    }

    ; --- CHECK LOAD SCREEN ---
    if (getStatusParam("loadShow") && !activeSet && !currSuspended) {
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
    currProgram := getStatusParam("currProgram")
    currGui     := getStatusParam("currGui")

    if ((delayCount > maxDelayCount || (currProgram = "" && currGui = "")) && !currSuspended) {
        checkAllGuis()

        mostRecentGui := getMostRecentGui()
        if (mostRecentGui != currGui) {
            setStatusParam("currGui", mostRecentGui)
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
                    setStatusParam("buttonTime", 0)
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
                setStatusParam("currGui", mostRecentGui)

                continue
            }
            else {
                setStatusParam("currGui", "")
            }
        }
    }

    ; --- CHECK KB & MOUSE MODE ---
    if (getStatusParam("kbmmode") && hotkeySource = "" && !currSuspended) {
        currHotkeys := addHotkeys(currHotkeys, kbmmodeHotkeys())
        currMouse   := kbmmodeMouse()

        ; don't restore currProgram if mouse is not on currProgram
        if (!activeSet && currProgram != "" && globalRunning.Has(currProgram)) {
            MouseGetPos(,, &mouseWin)
            
            if (globalRunning[currProgram].getHWND() != mouseWin && WinHidden(GUILOADTITLE) != mouseWin) {
                newSet := true
                for key, value in globalRunning {
                    if (!value.background) {
                        newSet := newSet && (value.getHWND() != mouseWin)
                    }
                }

                activeSet := newSet
            }
        }

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
                        setStatusParam("buttonTime", globalRunning[currProgram].hotkeyButtonTime)
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
                    setStatusParam("currProgram", "")
                }
            }
        } 
        else {
            createProgram(currProgram, false, false)
        }   
    }

    ; --- UPDATE HOTKEYS & MOUSE ---
    setStatusParam("currHotkeys", currHotkeys)
    setStatusParam("currMouse", currMouse)

    ; --- BACKUP ---
    if (statusUpdated()) {
        statusBackup()
    }

    if (delayCount > maxDelayCount) {
        try {
            controllerThreadRef.FuncPtr("")
        }
        catch {
            controllerThreadRef := controllerThread(ObjShare(mainConfig), globalControllers, xLibrary)
            Sleep(100)
        }
        
        try {
            hotkeyThreadRef.FuncPtr("")
        }
        catch {
            hotkeyThreadRef := hotkeyThread(ObjShare(mainConfig), globalStatus, globalControllers)
            Sleep(100)
        }

        ; check that function thread is running
        functionThreadHWND := WinHidden("functionThread")
        if (!functionThreadHWND) {
            setStatusParam("threadedFunction", "")
            functionThreadRef := functionThread(ObjShare(mainConfig), globalStatus)
            Sleep(100)
        }
        else if (DllCall("IsHungAppWindow", "Ptr", functionThreadHWND)) {
            ProcessKill(functionThreadHWND)
        }

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

    currProgram := getStatusParam("currProgram")

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
        if (getStatusParam("errorShow")) {
            try ProcessKill(WinGetPID("ahk_id " getStatusParam("errorHwnd")))
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

    if (!globalRunning.Has(id) || getStatusParam("currProgram") != id) {
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
    ; disable message listener
    OnMessage(MESSAGE_VAL, HandleMessage, 0)

    setLoadScreen("Please Wait...")

    ; tell the threads to close
    functionThreadRef.exitThread   := true
    Sleep(100)
    hotkeyThreadRef.exitThread     := true
    Sleep(100)
    controllerThreadRef.exitThread := true
    Sleep(100)

    dllFreeLib(xLibrary)
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

    setStatusParam("internalMessage", "")
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

    setStatusParam("internalMessage", "")
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
    Sleep(500)

    ShutdownScript()
    Sleep(500)
    
    DllCall("powrprof\SetSuspendState", "Int", 0, "Int", 0, "Int", 0)
    Sleep(3000)

    Run A_AhkPath . A_Space . "mainLooper.ahk -clean", A_ScriptDir, "Hide"
    ExitApp()
}