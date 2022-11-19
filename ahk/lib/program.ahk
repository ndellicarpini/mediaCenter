; creates an executable generic object that gets added to globalRunning
; this executable object will contain a lot of the generic features taken from executable json files
; each function & more in json files has default version as well
class Program {
    ; attributes
    id       := ""

    name     := ""
    dir      := ""
    exe      := ""
    wndw     := ""
    priority := ""

    volume := 0
    time   := 0

    ; number of seconds before determining a program not responding
    hungCount    := 0
    maxHungCount := 20

    ; if waiting on check of program relaunching
    waitingExistTimer      := false
    waitingHungTimer       := false
    waitingPostLaunchTimer := false
    waitingFullscreenTimer := false
    waitingMouseHideTimer  := false

    muted              := false
    background         := false
    minimized          := false
    fullscreened       := false
    paused             := false
    
    allowQuickAccess  := false
    allowHungCheck    := true
    allowPause        := true
    allowExit         := true
    shouldExit        := false
    requireInternet   := false
    requireFullscreen := false

    pauseOrder    := []
    pauseMousePos := []
    pauseOptions  := Map()

    launcher := Map()
    hotkeys  := Map()
    mouse    := Map()

    hotkeyButtonTime := 70

    ; functions
    customLaunch       := ""
    customPostLaunch   := ""
    customPause        := ""
    customResume       := ""
    customGetWNDW      := ""

    customExit         := ""
    customPostExit     := ""
    customRestore      := ""
    customSkipLauncher := ""
    customMinimize     := ""
    customFullscreen   := ""

    ; TODO - create a config obj that gives details how to update the program config before launch
    ; think emulator configs -> allow create defaults per args?
    configObj := ""

    ; used when exe/wndw are lists - keep current active
    currEXE  := ""
    currWNDW := ""

    __New(exeConfigRef) {
        exeConfig := ObjDeepClone(exeConfigRef)

        this.id   := exeConfig["id"]

        ; set basic attributes
        this.name     := (exeConfig.Has("name"))     ? exeConfig["name"]     : this.name
        this.dir      := (exeConfig.Has("dir"))      ? exeConfig["dir"]      : this.dir
        this.exe      := (exeConfig.Has("exe"))      ? exeConfig["exe"]      : this.exe
        this.wndw     := (exeConfig.Has("wndw"))     ? exeConfig["wndw"]     : this.wndw
        this.priority := (exeConfig.Has("priority")) ? exeConfig["priority"] : this.priority

        this.time := A_TickCount
        
        this.background         := (exeConfig.Has("background"))         ? exeConfig["background"]         : this.background
        this.allowPause         := (exeConfig.Has("allowPause"))         ? exeConfig["allowPause"]         : this.allowPause
        this.allowExit          := (exeConfig.Has("allowExit"))          ? exeConfig["allowExit"]          : this.allowExit
        this.allowQuickAccess   := (exeConfig.Has("allowQuickAccess"))   ? exeConfig["allowQuickAccess"]   : this.allowQuickAccess
        this.allowHungCheck     := (exeConfig.Has("allowHungCheck"))     ? exeConfig["allowHungCheck"]     : this.allowHungCheck
        this.requireInternet    := (exeConfig.Has("requireInternet"))    ? exeConfig["requireInternet"]    : this.requireInternet
        this.requireFullscreen  := (exeConfig.Has("requireFullscreen"))  ? exeConfig["requireFullscreen"]  : this.requireFullscreen

        ; set custom functions
        this.customLaunch     := (exeConfig.Has("launch"))     ? exeConfig["launch"]     : this.customLaunch 
        this.customPostLaunch := (exeConfig.Has("postLaunch")) ? exeConfig["postLaunch"] : this.customPostLaunch 
        this.customPause      := (exeConfig.Has("pause"))      ? exeConfig["pause"]      : this.customPause
        this.customResume     := (exeConfig.Has("resume"))     ? exeConfig["resume"]     : this.customResume 
        this.customGetWNDW    := (exeConfig.Has("getWNDW"))    ? exeConfig["getWNDW"]    : this.customGetWNDW 
        this.customExit       := (exeConfig.Has("exit"))       ? exeConfig["exit"]       : this.customExit
        this.customPostExit   := (exeConfig.Has("postExit"))   ? exeConfig["postExit"]   : this.customPostExit
        this.customRestore    := (exeConfig.Has("restore"))    ? exeConfig["restore"]    : this.customRestore
        this.customMinimize   := (exeConfig.Has("minimize"))   ? exeConfig["minimize"]   : this.customMinimize
        this.customFullscreen := (exeConfig.Has("fullscreen")) ? exeConfig["fullscreen"] : this.customFullscreen

        this.hotkeyButtonTime := (exeConfig.Has("hotkeyButtonTime")) ? exeConfig["hotkeyButtonTime"] : this.hotkeyButtonTime

        this.hotkeys := (exeConfig.Has("hotkeys")) ? exeConfig["hotkeys"] : this.hotkeys
        this.mouse   := (exeConfig.Has("mouse"))   ? exeConfig["mouse"]   : this.mouse

        if (exeConfig.Has("launcher")) {
            if (Type(exeConfig["launcher"]) = "Map") {
                this.launcher := exeConfig["launcher"]
            }
            else {
                this.customSkipLauncher := exeConfig["launcher"]
            }
        }

        ; set pause contents if appropriate
        if (this.allowPause) {
            if (exeConfig.Has("pauseOptions")) {
                if (Type(exeConfig["pauseOptions"]) = "Map" && this.pauseOptions.Count > 0) {
                    for key, value in exeConfig["pauseOptions"] {
                        this.pauseOptions[key] := value
                    }
                }
                else {
                    this.pauseOptions := exeConfig["pauseOptions"]
                }
            }

            if (exeConfig.Has("pauseOrder")) {
                if (Type(exeConfig["pauseOrder"]) = "Map" && this.pauseOrder.Length > 0) {
                    for item in exeConfig["pauseOrder"] {
                        if (!inArray(item, this.pauseOrder)) {
                            this.pauseOrder.Push(item)
                        }
                    }
                }
                else {
                    this.pauseOrder := exeConfig["pauseOrder"]
                }
            }
        }
    }

    ; runs the program
    ;  args - args to run the program with
    ;
    ; returns null
    launch(args := "") {
        restoreCritical := A_IsCritical
        Critical("Off")

        restoreAllowExit := this.allowExit
        this.allowExit := true

        restoreHotkeys := this.hotkeys
        this.hotkeys := Map()

        ; if require internet & internet check fails -> return
        if (this.requireInternet) {
            if (!waitForInternetProgram(this.id, 30)) {
                Critical(restoreCritical)
                return
            }
        }

        if (this.shouldExit) {
            Critical(restoreCritical)
            resetLoadScreen()
            return
        }

        this.allowExit := false

        setLoadScreen("Waiting for " . this.name . "...")

        ; run custom launch function
        if (this.customLaunch != "") {
            preCustomHotkeys := this.hotkeys
            if (runFunction(this.customLaunch, args) = -1) {
                if (!this.background) {
                    SetTimer(DelayCheckLaunch, -3000)
                }

                ; restore hotkeys if they weren't overwritten in customLaunch
                if (this.hotkeys = preCustomHotkeys) {
                    this.hotkeys := restoreHotkeys
                }

                this.allowExit := restoreAllowExit
                Critical(restoreCritical)

                resetLoadScreen()
                return
            }

            ; if hotkeys were overwritten in customLaunch update restoreHotkeys
            if (this.hotkeys != preCustomHotkeys) {
                restoreHotkeys := this.hotkeys
                this.hotkeys := Map()
            }
        }
        ; run dir\exe
        else if (!IsObject(this.exe) && this.exe != "") {
            if (Type(args) = "Array" && args.Length > 0) {
                argString := ""
                for item in args {
                    if (InStr(item, A_Space)) {
                        argString .= '"' . item . '"' . A_Space
                    }
                    else {
                        argString .= item . A_Space
                    }
                }

                Run validateDir(this.dir) . this.exe . A_Space . RTrim(argString, A_Space), validateDir(this.dir), ((this.background) ? "Hide" : "Max")
            }
            else if (Type(args) = "String" && args != "") {
                Run validateDir(this.dir) . this.exe . A_Space . args, validateDir(this.dir), ((this.background) ? "Hide" : "Max")
            }
            else {
                Run validateDir(this.dir) . this.exe, validateDir(this.dir), ((this.background) ? "Hide" : "Max")
            }
        }
        ; fail
        else {
            ErrorMsg(this.name . "does not have an exe defined, it cannot be launched with default settings")
            
            Critical(restoreCritical)
            resetLoadScreen()
            return
        }

        ; skip launcher if program has one
        if (this.customSkipLauncher != "" || this.launcher.Count > 0) {
            this.allowExit := true
            this.skipLauncher()

            this.allowExit := false
            if (this.shouldExit) {
                Critical(restoreCritical)
                resetLoadScreen()
                return
            }
        }

        count := 0
        maxCount := 150

        ; wait for either window or just exe (if background)
        while (!this.exists(!this.background) && count < maxCount) {
            count += 1

            Sleep(150)
        }

        ; read properties of window after delay
        if (!this.background) {
            SetTimer(DelayCheckLaunch, -3000)
        }

        this.shouldExit := false


        this.allowExit := restoreAllowExit
        this.hotkeys   := restoreHotkeys
        Critical(restoreCritical)

        resetLoadScreen()
        return

        ; saves screenshot & updates program data
        DelayCheckLaunch() {
            global globalGuis

            if (this.exists(true) && globalGuis.Count = 0 && this.hungCount = 0) {
                if (this.priority != "") {
                    ProcessSetPriority(this.priority, this.getPID())
                }

                this.checkFullscreen()
                saveScreenshot(this.id)
                return
            }

            SetTimer(CheckLaunchTimer, 500)
            return
        }

        ; if delay launch fials 
        CheckLaunchTimer() {
            global globalGuis

            if (!this || !this.exists()) {
                SetTimer(CheckLaunchTimer, 0)
                return
            }

            if (this.exists(true) && globalGuis.Count = 0 && this.hungCount = 0) {
                if (this.priority != "") {
                    ProcessSetPriority(this.priority, this.getPID())
                }

                this.checkFullscreen()
                saveScreenshot(this.id)

                SetTimer(CheckLaunchTimer, 0)
            }

            return
        }
    }

    ; activates the program's window
    restore() {
        global globalStatus

        if (this.hungCount > 0) {
            return
        }

        this.minimized := false
        
        window := this.getWNDW()

        ; if window not available in alt-tab -> not real
        if (!WinShown(window) || WinGetExStyle(window) & 0x00000080) {
            return
        }

        ; run custom restore
        if (this.customRestore != "") {
            if (runFunction(this.customRestore) = -1) {
                this.postRestore()
                return
            }
        }

        ; if window should not be fullscreen
        if (!this.fullscreened && !this.requireFullscreen) {
            try {
                count := 0
                maxCount := 150
                ; try to maximize window
                while (WinGetMinMax(window) != 1 && count < maxCount) {
                    WinMaximize(window)

                    Sleep(100)
                    count += 1
                }
    
                if (!WinActive(window)) {
                    WinMoveTop(window)
                    Sleep(100)
                }
            }
        }
        
        try {
            count := 0
            maxCount := 150
            ; try to activate window
            while (!WinActive(window) && count < maxCount) {
                WinActivate(window)
                
                Sleep(100)
                count += 1
            }
        }

        this.postRestore()
    }

    ; resumes & activates first restore timers
    postRestore() {
        this.resume()

        ; after first restore -> perform post launch action
        if (!this.waitingPostLaunchTimer) {
            SetTimer(DelayPostLauch.Bind(this.id), -1000)
            this.waitingPostLaunchTimer := true
        }

        ; after first restore -> fullscreen window if required
        if (this.requireFullscreen && !this.fullscreened && !this.waitingFullscreenTimer) {
            SetTimer(DelayFullscreen.Bind(this.id), -2500)
            this.waitingFullscreenTimer := true
        }

        ; after first restore -> move mouse to proper position
        if (!this.waitingMouseHideTimer) {
            ; hide mouse
            if (this.mouse.Count = 0) {
                SetTimer(DelayMouseMove.Bind(this.id, percentWidth(1, false), percentHeight(1, false)), -3000)
            }
            ; move mouse to starting position
            else if (this.mouse.Has("initialPos")) {
                x := percentWidth(this.mouse["initialPos"][1], false)
                y := percentHeight(this.mouse["initialPos"][2], false)
    
                SetTimer(DelayMouseMove.Bind(this.id, x, y), -500)
            }

            this.waitingMouseHideTimer := true
        }

        return

        ; do custom post launch function
        DelayPostLauch(id) {
            global globalRunning

            if (!globalRunning.Has(id)) {
                return
            }

            if (this.customPostLaunch != "") {
                if (runFunction(this.customPostLaunch) = -1) {
                    return
                }
            }

            return
        }

        ; fullscreen window
        DelayFullscreen(id) {
            global globalRunning

            if (!globalRunning.Has(id)) {
                return
            }

            this.waitingFullscreenTimer := false
            
            if (!this.checkFullscreen()) {
                this.fullscreen()
            }

            Sleep(50)

            return
        }

        ; move mouse to x, y position
        DelayMouseMove(id, x, y) {
            global globalRunning

            if (!globalRunning.Has(id)) {
                return
            }
            
            MouseMove(x, y)
            return
        }
    }

    ; waits for & skips some program that launches before exe by clicking based on launcher Map
    skipLauncher() {
        if (this.customSkipLauncher != "") {
            if (runFunction(this.customSkipLauncher) = -1) {
                return
            }
        }

        if (!this.launcher.Has("exe") || this.launcher["exe"] = "") {
            return
        }

        delay := (this.launcher.Has("delay")) ? this.launcher["delay"] : 1000

        ; wait for executable
        while (!WinShown("ahk_exe " this.launcher["exe"])) {
            if (this.exists() || this.shouldExit) {
                resetLoadScreen()
                return
            }

            Sleep(100)
        }

        ; flatten double array
        mouseArr := []
        loop this.launcher["mouseClick"].Length {
            if (Type(this.launcher["mouseClick"][A_Index]) = "Array") {
                currIndex := A_Index
                loop this.launcher["mouseClick"][currIndex].Length {
                    mouseArr.Push(this.launcher["mouseClick"][currIndex][A_Index])
                }
            }
            else {
                mouseArr.Push(this.launcher["mouseClick"][A_Index])
            }
        }

        if (Mod(mouseArr.Length, 2) != 0) {
            ErrorMsg("Launcher mouseClick length must be even")
            return
        }

        globalStatus["loadscreen"]["overrideWNDW"] := "ahk_exe " this.launcher["exe"]

        ; try to skip launcher as long as exectuable is shown
        while (WinShown("ahk_exe " this.launcher["exe"])) {
            if (this.exists() || this.shouldExit) {
                resetLoadScreen()
                return
            }

            loop (mouseArr.Length / 2) {
                index := ((A_Index - 1) * 2) + 1
        
                Sleep(delay)
                Sleep(75)
                if (this.exists() || this.shouldExit || !WinShown("ahk_exe " this.launcher["exe"])) {
                    resetLoadScreen()
                    return
                }

                MouseClick("Left", percentWidthRelativeWndw(mouseArr[index], "ahk_exe " this.launcher["exe"])
                    , percentHeightRelativeWndw(mouseArr[index + 1], "ahk_exe " this.launcher["exe"]),,, "D")
                Sleep(75)
                MouseClick("Left",,,,, "U")
                Sleep(75)
                MouseMove(percentWidth(1), percentHeight(1))    
            }
        }

        globalStatus["loadscreen"]["overrideWNDW"] := ""
    }

    ; minimize program window
    minimize() {
        global globalStatus

        if (this.hungCount > 0) {
            return
        }

        restoreCritical := A_IsCritical
        Critical("On")

        this.pause()

        this.minimized := true

        ; reset fullscreen status on minimize
        this.fullscreened := false
        this.waitingFullscreenTimer := false

        ; get new thumbnail
        if (this.id = globalStatus["currProgram"]) {
            saveScreenshot(this.id)
        }

        ; run custom minimize
        if (this.customMinimize != "") {
            if (runFunction(this.customMinimize) = -1) {
                Critical(restoreCritical)
                return
            }
        }

        WinMinimize(this.getWNDW())
        Critical(restoreCritical)
    }

    ; fullscreen window if not fullscreened
    fullscreen() {
        global globalStatus

        if (this.hungCount > 0) {
            return
        }
        
        restoreCritical := A_IsCritical
        Critical("On")

        if (this.customFullscreen != "") {
            if (runFunction(this.customFullscreen) = -1) {
                Critical(restoreCritical)
                return
            }
        }

        window := this.getWNDW()

        try {
            if (!WinShown(window)) {
                Critical(restoreCritical)
                return
            }
    
            WinGetClientPos(,, &W, &H, window)
            if (W < 1 || H < 1) {
                Critical(restoreCritical)
                return
            }
    
            ; remove border around window
            WinSetStyle(-0xC40000, window)
            Sleep(50)
    
            WinSetExStyle(-0x00000200, window)
            Sleep(50)
        }
        catch {
            Critical(restoreCritical)
            return
        }

        ; TODO - GET BETTER WAY TO CALCULATE FULLSCREEN ASPECT RATIO

        ; currently rounding the INACCURATE client area as returned by WinGetClientPos
        ; bc of that i'm rounding the reported aspect ratios to common ones

        validWidths  := [MONITORW, 21, 16, 4]
        validHeights := [MONITORH,  9,  9, 3]

        minDiff := 69
        aspectIndex := 1
        loop validWidths.Length {
            currDiff := Abs((W / H) - (validWidths[A_Index] / validHeights[A_Index]))

            if (currDiff < minDiff) {
                minDiff := currDiff
                aspectIndex := A_Index
            }
        }

        multiplier := Min(MONITORW / validWidths[aspectIndex], MONITORH / validHeights[aspectIndex])
        newW := validWidths[aspectIndex]  * multiplier
        newH := validHeights[aspectIndex] * multiplier

        WinMove(MONITORX + ((MONITORW - newW) / 2), MONITORY + ((MONITORH - newH) / 2), newW, newH, window)

        Critical(restoreCritical)

        Sleep(50)
        this.checkFullscreen()
    }

    ; return if program is "fullscreen" & update the fullscreen value of the program
    checkFullscreen() {
        if (this.hungCount > 0) {
            return
        }

        window := this.getWNDW()

        try {
            if (WinGetMinMax(window) = -1 || WinGetExStyle(window) & 0x00000080) {
                return false
            }
        
            style := WinGetStyle(window)
            this.fullscreened := (style & 0x20800000) ? false : true

            return this.fullscreened
        }

        return false
    }

    ; check if program executable exists
    ;  requireShown - require program to be shown
    ;  checkHung - check the responding state of the program
    ;
    ; returns true if program exists
    exists(requireShown := false, checkHung := false) {
        wndwStatus := false
        exeStatus := false

        ; skip cycle if waiting for exist timers
        if (this.waitingExistTimer) {
            return true
        }

        ; skip cycle if exe & waiting for user choice dialog
        if (this.waitingHungTimer && ProcessExist("ahk_pid " this.getPID())) {
            return true
        }

        ; check if any wndw exists
        if (IsObject(this.wndw)) {
            current := this.currWNDW

            if (current = "") {
                current := checkWNDW(this.wndw, true)
            }

            if (current != "") {
                wndwStatus := true

                ; if wndw previously existed & no longer does
                ;    -> delay wait for any wndw to reappear 
                if (!checkWNDW(current) && !this.waitingExistTimer) {
                    SetTimer(DelayCheckWNDW, -1500)
                    this.waitingExistTimer := true
                }

                this.currWNDW := current
            }
        }
        ; check if wndw exists
        else {
            wndwStatus := checkWNDW(this.wndw)
        }

        ; if wndwStatus was successful, skip exe check
        if (!wndwStatus) {
            ; if only checking wndw & program doesn't have window
            ;  -> try to check if exe has wndw
            if (requireShown) {
                if (this.wndw = "") {
                    if (IsObject(this.exe)) {
                        for key, empty in this.exe {
                            if (WinShown("ahk_exe " key)) {
                                this.currEXE := key
                                exeStatus := true
                                break
                            }   
                        }         
                    }
                    else {
                        exeStatus := WinShown("ahk_exe " this.exe) ? true : false
                    }
                }
            }
            ; check if any exe exists
            else if (IsObject(this.exe)) {
                current := this.currEXE

                if (current = "") {
                    current := checkEXE(this.exe, true)
                }

                if (current != "") {
                    exeStatus := true

                    ; if exe previously existed & no longer does
                    ;    -> delay wait for any exe to reappear 
                    if (!checkEXE(current) && !this.waitingExistTimer) {
                        SetTimer(DelayCheckEXE, -1500)
                        this.waitingExistTimer := true
                    }

                    this.currEXE := current
                }
            }
            ; check if exe exists
            else {
                exeStatus := checkEXE(this.exe)
            }
        }

        if (this.allowHungCheck && checkHung) {
            ; check if wndw hung 
            if ((exeStatus || wndwStatus) && !WinResponsive(this.getHWND())) {
                if (this.hungCount = 0) {
                    SetTimer(CheckHungTimer, -1000)
                    this.hungCount += 1
                }
            }
            ; reset hung counter if wndw not hung
            else if (this.hungCount > 0) {
                this.hungCount := 0
                this.waitingHungTimer := false
            }
        }
        
        return exeStatus || wndwStatus

        ; check if any exe exists from exe list
        DelayCheckEXE() {
            this.waitingExistTimer := false

            if (this.exe = "") {
                return
            }

            current := checkEXE(this.exe, true)
            if (current = "") {
                this.exe := ""
                return
            }

            this.currEXE := current
            return
        }

        ; check if any wndw exists from wndw list
        DelayCheckWNDW() {
            this.waitingExistTimer := false

            if (this.wndw = "") {
                return
            }

            current := checkWNDW(this.wndw, true)
            if (current = "") {
                this.wndw := ""
                return
            }

            this.currWNDW := current
            return
        }

        ; repeated check while program is hung
        CheckHungTimer() {
            ; if exists & hung
            if (ProcessExist(this.getPID()) && !WinResponsive(this.getHWND())) {               
                if (this.hungCount > this.maxHungCount) {
                    ; create "wait for program" gui dialog
                    if (!this.waitingHungTimer) {
                        createChoiceDialog(this.name " has stopped responding", "Wait",,, "Exit", "ProcessKill " . this.getPID(), "FF0000")
                        this.waitingHungTimer := true
                    }
                    ; reset hung count if gui dialog doesn't exist
                    else if (!WinShown(GUICHOICETITLE)) {
                        this.hungCount := 0
                        this.waitingHungTimer := false
                    }
                }

                this.hungCount += 1
                SetTimer(CheckHungTimer, -1000)
            }
            ; reset hung count if no longer exists/hung
            else {
                this.hungCount := 0

                ; close gui dialog if it exists
                hungGUI := getGUI(GUICHOICETITLE)
                if (this.waitingHungTimer && hungGUI) {
                    this.waitingHungTimer := false
                    hungGUI.Destroy()
                }
            }
            
            return
        }
    }

    ; exit program 
    exit() {
        global globalStatus

        ; disable hotkeys
        this.hotkeys := Map()
        this.shouldExit := true

        window := this.getWNDW()
        
        activeEXE := ""
        if (this.currEXE != "") {
            activeEXE := this.currEXE
        }
        else if (!IsObject(this.exe)) {
            activeEXE := this.exe
        }

        exeExists := false
        if (activeEXE != "") {
            exeExists := ProcessExist(activeEXE)
        }
        else if (window != "") {
            exeExists := WinHidden(window)
        }

        if (window = "" && activeEXE = "") {
            return
        }
        
        setLoadScreen("Exiting " . this.name . "...")

        restoreCritical := A_IsCritical
        Critical("On")

        ; run custom exit
        if (this.customExit != "") {
            if (runFunction(this.customExit) = -1) {
                Critical(restoreCritical)
                return
            }
        }
        else if (window != "") {
            if (this.hungCount = 0) {
                WinClose(window)
            }
            else {
                ProcessClose(activeEXE)
            }
        }

        try {
            if (this.launcher.Has("exe") && this.launcher["exe"] != "" && ProcessExist(this.launcher["exe"])) {
                ProcessClose(this.launcher["exe"])
            }

            count := 0
            maxCount := 300
            ; wait for program executable to close
            while (exeExists && count < maxCount) {
                window := this.getWNDW()

                if (this.customExit = "" && window != "") {
                    ; attempt to winclose again @ 10s
                    if (count = 100 && WinShown(window)) {
                        ; if program is hanging, kill it
                        if (this.hungCount = 0) {
                            WinClose(window)
                        }
                        else {
                            ProcessKill(this.getPID())
                        }
                    }
    
                    ; attempt to processclose @ 20s
                    if (count = 200) {
                        ProcessWinClose(window)
                    }
                }

                if (activeEXE != "") {
                    exeExists := ProcessExist(activeEXE)
                }
                else if (window != "") {
                    exeExists := WinHidden(window)
                }
                
                count += 1
                Sleep(100)
            }

            ; if exists -> go nuclear @ 30s
            if (window != "" && WinHidden(window)) {
                ProcessKill(window)
            }
        }

        Sleep(500)
        resetLoadScreen()

        Critical(restoreCritical)
        return
    }

    ; run custom post exit function
    postExit() {
        if (this.customPostExit != "") {
            runFunction(this.customPostExit)
        }
    }
    
    ; runs custom pause function on pause
    pause() {
        if (this.paused) {
            return
        }
        
        restoreCritical := A_IsCritical
        Critical("On")
        
        this.paused := true

        ; save mouse position to be restored on resume
        if ((this.mouse.Has("initialPos") && this.mouse.Count > 1)
            || (!this.mouse.Has("initialPos") && this.mouse.Count > 0)) {

            MouseGetPos(&x, &y)
            this.pauseMousePos := [x, y]
        }

        saveScreenshot(this.id)

        if (this.customPause != "") {
            runFunction(this.customPause)
        }

        Critical(restoreCritical)
        return
    }

    ; runs custom resume function after pause close
    resume() {
        if (!this.paused) {
            return
        }
        
        restoreCritical := A_IsCritical
        Critical("On")
        
        Sleep(100)
        this.paused := false
        
        if (this.pauseMousePos.Length = 2) {
            MouseMove(this.pauseMousePos[1], this.pauseMousePos[2])
        }

        if (this.customResume != "") {
            runFunction(this.customResume)
        }

        Critical(restoreCritical)
        return
    }

    ; get program pid
    getPID() {
        activeWNDW := this.getWNDW()

        activeEXE := ""
        if (this.currEXE != "") {
            activeEXE := this.currEXE
        }
        else if (!IsObject(this.exe)) {
            activeEXE := this.exe
        }

        resetDHW := A_DetectHiddenWindows
        DetectHiddenWindows(!this.background)

        PID := 0

        try {
            if (activeWNDW != "") {
                PID := WinGetPID(activeWNDW)
            }
            else if (activeEXE != "") {
                PID := ProcessExist(activeEXE)
            }
        }
        catch {
            PID := 0
        }

        DetectHiddenWindows(resetDHW)
        return PID
    }

    ; get program window name
    getWNDW() {  
        if (this.customGetWNDW != "") {
            return runFunction(this.customGetWNDW)
        }

        activeEXE := ""
        if (this.currEXE != "") {
            activeEXE := this.currEXE
        }
        else if (!IsObject(this.exe)) {
            activeEXE := this.exe
        }

        activeWNDW := ""
        if (this.currWNDW != "") {
            activeWNDW := this.currWNDW
        }
        else if (!IsObject(this.wndw)) {
            activeWNDW := this.wndw
        }

        if (activeWNDW != "") {
            return activeWNDW
        }
        if (activeEXE != "") {
            return "ahk_exe " . activeEXE
        }
        
        return ""
    }

    ; get program hwnd
    getHWND() {
        WNDW := this.getWNDW()

        resetDHW := A_DetectHiddenWindows
        DetectHiddenWindows(!this.background)

        HWND := 0

        try {
            if (WNDW != "") {
                HWND := WinGetID(WNDW)
            }
        }
        catch {
            HWND := 0
        }
        
        DetectHiddenWindows(resetDHW)
        return HWND
    }

    ; update the volume value of the program
    checkVolume() {
        volumeInterface := this.getVolumeInterfacePtrs()
        if (volumeInterface.Length = 0) {
            this.volume := -1
            return
        }

        for ptr in volumeInterface {
            currVal := 0
            DllCall(NumGet(NumGet(ptr, 0, "UPtr") + 4 * A_PtrSize, 0, "UPtr"), "Ptr", ptr, "Float*", &currVal)

            this.volume := Round(currVal * 100)
            return
        }
    }

    ; set the volume of a program
    ;  newVal - new value for volume (0-100)
    setVolume(newVal) {
        volumeInterface := this.getVolumeInterfacePtrs()
        if (volumeInterface.Length = 0) {
            return
        }

        for ptr in volumeInterface {
            programGUID := Buffer(16, 0)
            DllCall("ole32\CLSIDFromString", "WStr", "", "Ptr", programGUID.Ptr)
            DllCall(NumGet(NumGet(ptr, 0, "UPtr") + 3 * A_PtrSize, 0, "UPtr"), "Ptr", ptr, "Float", newVal / 100, "Ptr", programGUID.Ptr)
        }

        this.volume := newVal
    }

    ; sets volume of program to 0
    muteVolume() {
        volumeInterface := this.getVolumeInterfacePtrs()
        if (volumeInterface.Length = 0) {
            this.volume := -1
            this.muted  := false
            return
        }

        for ptr in volumeInterface {
            programGUID := Buffer(16, 0)
            DllCall("ole32\CLSIDFromString", "WStr", "", "Ptr", programGUID.Ptr)
            DllCall(NumGet(NumGet(ptr, 0, "UPtr") + 3 * A_PtrSize, 0, "UPtr"), "Ptr", ptr, "Float", ((this.muted) ? (this.volume / 100) : 0), "Ptr", programGUID.Ptr)
        }

        this.muted := !this.muted
    }

    ; internal function to initialize volume checkers
    getVolumeInterfacePtrs() {
        iasm2 := "{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}"
        iasc2 := "{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}"
        isav  := "{87CE5498-68D6-44E5-9215-6DA47EF883D8}"

        deviceEnum := ComObject("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
        if (!deviceEnum) {
            ErrorMsg("Could not get audio device enumerator")
            return
        }

        device := 0
        if (DllCall(NumGet(NumGet(deviceEnum.Ptr, 0, "UPtr") + 5 * A_PtrSize, 0, "UPtr"), "Ptr", deviceEnum.Ptr, "WStr", "playback", "Ptr*", &device) != 0) {
            DllCall(NumGet(NumGet(deviceEnum.Ptr, 0, "UPtr") + 4 * A_PtrSize, 0, "UPtr"), "Ptr", deviceEnum.Ptr, "Int", 0, "Int", 0, "Ptr*", &device)
        }

        volGUID := Buffer(16, 0)
        deviceInterface := 0
        DllCall("ole32\CLSIDFromString", "WStr", iasm2, "Ptr", volGUID.Ptr)
        DllCall(NumGet(NumGet(device, 0, "UPtr") + 3 * A_PtrSize, 0, "UPtr"), "Ptr", device, "Ptr", volGUID.Ptr, "UInt", 0, "UInt", 0, "Ptr*", &deviceInterface)
        
        sessionEnum := 0
        DllCall(NumGet(NumGet(deviceInterface, 0, "UPtr") + 5 * A_PtrSize, 0, "UPtr"), "Ptr", deviceInterface, "Ptr*", &sessionEnum)
        
        sessionCount := 0
        DllCall(NumGet(NumGet(sessionEnum, 0, "UPtr") + 3 * A_PtrSize, 0, "UPtr"), "Ptr", sessionEnum, "Ptr*", &sessionCount)
        
        interfacePtrs := []
        loop sessionCount {
            currSession := 0
            DllCall(NumGet(NumGet(sessionEnum, 0, "UPtr") + 4 * A_PtrSize, 0, "UPtr"), "Ptr", sessionEnum, "Int", (A_Index - 1), "Ptr*", &currSession)
            sessionInterface := ComObjQuery(currSession, iasc2)
            
            sessionPID := 0
            DllCall(NumGet(NumGet(sessionInterface.Ptr, 0, "UPtr") + 14 * A_PtrSize, 0, "UPtr"), "Ptr", sessionInterface.Ptr, "UInt*", &sessionPID)
            
            exeNameBuff := Buffer(512, 0)
            processPtr := DllCall("OpenProcess", "UInt", 0x1000, "UInt", 0, "UInt", sessionPID, "UPtr")
            DllCall("QueryFullProcessImageName", "UPtr", processPtr, "UInt", 0, "Str", exeNameBuff.Ptr, "UInt*", 512, "UInt")
            DllCall("CloseHandle", "UPtr", processPtr, "UInt")
            
            exeNameArr := StrSplit(StrGet(exeNameBuff), "\")
            if (sessionPID != 0 && (sessionPID = this.getPID() || (exeNameArr.Length > 0 && exeNameArr[exeNameArr.Length] = ((this.currEXE != "")  ? this.currEXE  : this.exe)))) {
                interfacePtrs.Push(ComObjQuery(sessionInterface.Ptr, isav).Ptr)
            }
        }

        return interfacePtrs
    }
}

; cleans up program setting if it is a file, converting it into a newline deliminated list
;   setting - setting
;   dir - directory of settings lists
;
; returns setting or list of values parsed from setting's file
cleanSetting(setting, dir) {
    if (Type(setting) != "String" || setting = "" || dir = "") {
        return setting
    }

    settingFile := validateDir(dir) . setting

    if (FileExist(settingFile)) {
        return readConfig(settingFile, "").items
    }

    return setting
}

; takes a variable amount of exe maps (key=exe) and returns the process exe if its running
;  exe - either an exe or a map with each key being an exe
;  retName - return name rather than boolean
;
; return either "" if the process is not running, or the name of the process
checkEXE(exe, retName := false) {
    if (exe = "") {
        return false
    }

    if (IsObject(exe)) {
        size  := 4096
        bytes := 0

        processBuff := Buffer(size, 0)
        DllCall("psapi.dll\EnumProcesses", "Ptr", processBuff.Ptr, "UInt", size, "UIntP", &bytes)

        loop (bytes // 4) {
            processPtr := DllCall("OpenProcess", "UInt", 0x0010 | 0x0400, "Int", 0, "UInt", NumGet(processBuff, A_Index * 4, "UInt"), "Ptr")
            if (!processPtr) {
                continue
            }

            processName := ""
            processNameBuff := Buffer(size, 0)
            processNamePtr  := DllCall("psapi.dll\GetModuleBaseName", "Ptr", processPtr, "Ptr", 0, "Ptr", processNameBuff.Ptr, "UInt", size // 2)
            if (processNamePtr) {
                processName := StrGet(processNameBuff)
            }
            else {
                DllCall("psapi.dll\GetProcessImageFileName", "Ptr", processPtr, "Ptr", processNameBuff.Ptr, "UInt", size // 2)
                processNameArr := StrSplit(StrGet(processNameBuff), "\")
                processName := processNameArr[processNameArr.Length]
            }

            DllCall("CloseHandle", "Ptr", processPtr)

            if (processName != "" && exe.Has(processName)) {
                return (retName) ? processName : true
            }
        }
    }
    else {
        if (retName) {
            return ProcessExist(exe) ? exe : ""
        }
        else {
            return ProcessExist(exe) ? true : false
        }
    }

    return (retName) ? "" : false
}

; takes a variable of window maps (key=window) and returns true if any of the functions return
;  wndw - either an wndw name or a map with each key being an wndw
;  retName - return name rather than boolean
;
; return either "" if the process is not running, or the name of the process
checkWNDW(wndw, retName := false) {
    if (wndw = "") {
        return false
    }

    if (IsObject(wndw)) {
        for key, empty in wndw {
            if (WinShown(key)) {
                return (retName) ? key : true
            }
        }
	}
    else {
        if (retName) {
            return WinShown(wndw) ? wndw : ""
        }
        else {
            return WinShown(wndw) ? true : false
        }
    }

    return (retName) ? "" : false
}

; creates a program that gets added to globalRunning
;  params - params to pass to Program(), first element of params must be program name
;  launchProgram - if program.launch() should be called
;  setCurrent - if currProgram should be updated
;  customAttributes - map of manual set attributes
;
; returns null
createProgram(params, launchProgram := true, setCurrent := true, customAttributes := "") {   
    global globalRunning
    global globalPrograms

    newProgram := []
    if (IsObject(params)) {
        newProgram := params
    }
    else {
        newProgram := toArray(StrSplit(params, A_Space))
    }

    newID := newProgram.RemoveAt(1)
    
    for key, value in globalPrograms {
        ; find program config from id
        if (StrLower(key) = StrLower(newID)) {
            ; if config missing required values
            if (!value.Has("id") || !value.Has("name")) {
                ErrorMsg("Tried to create program " . newID . "missing required fields id/name", true)
                return
            }

            ; check if program or program w/ same name exists
            for key2, value2 in globalRunning {
                if (key = key2 || value["name"] = value2.name) {
                    ; just set the running program as current
                    if (setCurrent || launchProgram) {
                        setCurrentProgram(key2)
                    }

                    resetLoadScreen()
                    return
                }
            }
            
            globalRunning[newID] := Program(value)

            ; set new program as current
            if (setCurrent) {
                setCurrentProgram(newID)
            }

            ; launch new program
            if (launchProgram) {
                globalRunning[newID].launch(newProgram)
            }

            ; set attributes of program (basically only done from backup.bin)
            if (customAttributes != "") {                
                for key, value in customAttributes {
                    globalRunning[newID].%key% := value
                }
            }
        
            return
        }
    }

    ErrorMsg("Program " . newID . " was not found")
}

; sets the requested id as the current program if it exists
;  id - id of program to set as current
;
; returns null
setCurrentProgram(id) {
    global globalStatus
    global globalRunning

    if (!globalRunning.Has(id) || globalRunning[id].background) {
        MsgBox("Requested current program doesn't exist / is background")
        return
    }
    
    if (globalStatus["currProgram"] != id) {
        activateLoadScreen()
        MouseMove(percentWidth(1), percentHeight(1))

        globalRunning[id].time := A_TickCount

        globalStatus["currProgram"] := id
        globalStatus["input"]["source"] := id
        Sleep(200)

        resetLoadScreen()
    }

    if (globalRunning[id].exists(true) && !globalStatus["suspendScript"]) {
        globalRunning[id].restore()
    }
}

; get the most recently opened program if it exists, otherwise return blank
;  checkBackground - boolean if to check background apps as well
;
; returns either name of recently opened program or empty string
getMostRecentProgram(checkBackground := false) {
    global globalRunning

    prevTime := -1
    prevProgram := ""
    for key, value in globalRunning {
        if (!checkBackground && value.background) {
            continue
        }

        if (value.time > prevTime) {
            prevTime := value.time
            prevProgram := key
        }
    }

    return prevProgram
}

; checks & updates the running list of programs
; launches missing background programs
;
; returns null
checkAllPrograms() {
    global globalConfig
    global globalRunning
    global globalPrograms
    global globalConsoles

    for key, value in globalPrograms {
        if (!globalRunning.Has(key) && ((value.Has("exe") && checkEXE(value["exe"])) || (value.Has("wndw") && checkWNDW(value["wndw"])))) {
            foundConsole := false
            ; run program as console if it's an emulator
            for key2, value2 in globalConsoles {
                if (inArray(key, value2["emulators"])) {
                    createConsole([key2, ""], false, false)
                    
                    foundConsole := true
                    break
                }
            }

            if (!foundConsole) {
                createProgram(key, false, false)
            }
        }
    }

    toDelete := []
    numForeground := 0
    for key, value in globalRunning {
        if (!value.exists()) {
            toDelete.Push(key)
        }
        else if (!value.background) {
            numForeground += 1
        }
    }

    for item in toDelete {
        globalRunning[item].postExit()
        globalRunning.Delete(item)
    }

    if (globalConfig["Plugins"].Has("DefaultProgram") && globalConfig["Plugins"]["DefaultProgram"] != "" && numForeground = 0) {
        if (!globalPrograms.Has(globalConfig["Plugins"]["DefaultProgram"])) {
            ErrorMsg("Default Program" . globalConfig["Plugins"]["DefaultProgram"] . " has no config", true)
        }

        createProgram(globalConfig["Plugins"]["DefaultProgram"])
    }
}

; updates program list & exits all existing programs
;
; returns null
exitAllPrograms() {
    global globalRunning

    checkAllPrograms()

    while (globalRunning.Count > 0) {
        name := getMostRecentProgram(true)

        globalRunning[name].exit()
        Sleep(250)

        if (globalRunning[name].exists()) {
            ProcessKill(globalRunning[name].getPID())
        }

        globalRunning[name].postExit()
        globalRunning.Delete(name)
    }
}

; spin waits until either timeout or successful internet connection
;  programID - id of program waiting, will cancel if shouldExit
;  timeout - seconds to wait
;
; returns true if connected to internet
waitForInternetProgram(programID, timeout := 30) {
	global globalRunning

	count := 0
	wsaData := Buffer(408, 0)
		
	setLoadScreen("Waiting for Internet...")

	if (DllCall("Ws2_32\WSAStartup", "UShort", 0x0202, "Ptr", wsaData.Ptr)) {
		resetLoadScreen()
		return false
	}
	
	addrPtr := 0
	while (count < timeout) {
		if (programID != "" && globalRunning[programID].shouldExit) {
			DllCall("Ws2_32\WSACleanup")
			resetLoadScreen()
			return false
		}

		try {
			if (DllCall("Ws2_32\GetAddrInfoW", "WStr", "dns.msftncsi.com", "WStr", "http", "Ptr", 0, "Ptr*", &addrPtr)) {		
				count += 1
				Sleep(1000)

				setLoadScreen("Waiting for Internet... (" . (timeout - count) . ")")
				continue
			}

			family  := NumGet(addrPtr + 4, 0, "Int")
			addrLen := NumGet(addrPtr + 16, 0, "Ptr")
			addr    := NumGet(addrPtr + 16, 16, "Ptr")

			DllCall("Ws2_32\WSAAddressToStringW", "Ptr", addr, "UInt", addrLen, "Ptr", 0, "Str", wsaData.Ptr, "UInt*", 204)
			DllCall("Ws2_32\FreeAddrInfoW", "Ptr", addrPtr)

			http := ComObject("WinHttp.WinHttpRequest.5.1")

			if (family = 2 && StrGet(wsaData) = "131.107.255.255:80") {
				http.Open("GET", "http://www.msftncsi.com/ncsi.txt")
			}
			else if (family = 23 && StrGet(wsaData) = "[fd3e:4f5a:5b81::1]:80") {
				http.Open("GET", "http://ipv6.msftncsi.com/ncsi.txt")
			}

			http.Send()

			if (http.ResponseText = "Microsoft NCSI") {
				DllCall("Ws2_32\WSACleanup")
				resetLoadScreen()
				return true
			}
		}
	
		count += 1
		Sleep(1000)

		setLoadScreen("Waiting for Internet... (" . (timeout - count) . ")")
	}

	DllCall("Ws2_32\WSACleanup")
	resetLoadScreen()
	return false
}