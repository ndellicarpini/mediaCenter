; creates an executable generic object that gets added to globalRunning
; this executable object will contain a lot of the generic features taken from executable json files
; each function & more in json files has default version as well
class Program {
    className := "Program"
    
    ; attributes
    id       := ""

    name     := ""
    dir      := ""
    exe      := ""
    wndw     := ""
    overlay  := ""
    priority := ""

    volume := 0
    time   := 0

    muted              := false
    background         := false
    minimized          := false
    fullscreened       := false
    paused             := false

    defaultArgs        := []
    ignoreEXEs         := []
    allowQuickAccess   := false
    allowHungCheck     := true
    allowPause         := true
    allowExit          := true
    shouldExit         := false
    requireInternet    := false
    requireFullscreen  := false
    overlayActivateFix := false

    pauseOrder    := []
    pauseOptions  := Map()

    launcher := Map()
    hotkeys  := Map()
    mouse    := Map()

    hotkeyButtonTime := 70

    ; TODO - create a config obj that gives details how to update the program config before launch
    ; think emulator configs -> allow create defaults per args?
    configObj := ""

    ; number of seconds before determining a program not responding
    hungCount    := 0
    maxHungCount := 20

    ; delays for post launching actions, can be overwritten in custom classes
    postLaunchSend       := ""
    fullscreenSend       := ""
    postLaunchDelay      := 1000
    fullscreenDelay      := 2500
    mouseMoveDelay       := 3500
    checkPropertiesDelay := 3000

    ; if waiting on check of program relaunching
    _waitingExistTimer       := false
    _waitingHungTimer        := false
    _waitingPostLaunchTimer  := false
    _waitingFullscreenTimer  := false
    _waitingMouseMoveTimer   := false
    _waitingWindowTimer      := false
    _waitingWindowFailed     := false
    _overrideFullscreenDelay := 0

    ; controls win position on screen
    monitorNum := MONITOR_N
    _monitorX := 0
    _monitorY := 0
    _monitorW := 0
    _monitorH := 0

    _restoreMousePos := []
    _launchArgs := []

    ; used when exe/wndw are lists - keep current active
    _currEXE      := ""
    _currShownEXE := ""
    _currHWND     := 0
    _currHWNDList := []

    _currPIDList := []

    __New(exeConfigRef) {
        exeConfig := ObjDeepClone(exeConfigRef)

        this.id   := exeConfig["id"]
        this.time := A_TickCount

        ; set basic attributes
        this.name                 := (exeConfig.Has("name"))                 ? exeConfig["name"]                 : this.name
        this.className            := (exeConfig.Has("className"))            ? exeConfig["className"]            : this.className
        this.exe                  := (exeConfig.Has("exe"))                  ? exeConfig["exe"]                  : this.exe
        this.wndw                 := (exeConfig.Has("wndw"))                 ? exeConfig["wndw"]                 : this.wndw
        this.overlay              := (exeConfig.Has("overlay"))              ? exeConfig["overlay"]              : this.overlay
        this.priority             := (exeConfig.Has("priority"))             ? exeConfig["priority"]             : this.priority
        this.background           := (exeConfig.Has("background"))           ? exeConfig["background"]           : this.background
        this.launcher             := (exeConfig.Has("launcher"))             ? exeConfig["launcher"]             : this.launcher
        this.allowPause           := (exeConfig.Has("allowPause"))           ? exeConfig["allowPause"]           : this.allowPause
        this.allowExit            := (exeConfig.Has("allowExit"))            ? exeConfig["allowExit"]            : this.allowExit
        this.allowQuickAccess     := (exeConfig.Has("allowQuickAccess"))     ? exeConfig["allowQuickAccess"]     : this.allowQuickAccess
        this.allowHungCheck       := (exeConfig.Has("allowHungCheck"))       ? exeConfig["allowHungCheck"]       : this.allowHungCheck
        this.requireInternet      := (exeConfig.Has("requireInternet"))      ? exeConfig["requireInternet"]      : this.requireInternet
        this.requireFullscreen    := (exeConfig.Has("requireFullscreen"))    ? exeConfig["requireFullscreen"]    : this.requireFullscreen
        this.overlayActivateFix   := (exeConfig.Has("overlayActivateFix"))   ? exeConfig["overlayActivateFix"]   : this.overlayActivateFix
        this.postLaunchSend       := (exeConfig.Has("postLaunchSend"))       ? exeConfig["postLaunchSend"]       : this.postLaunchSend
        this.fullscreenSend       := (exeConfig.Has("fullscreenSend"))       ? exeConfig["fullscreenSend"]       : this.fullscreenSend
        this.postLaunchDelay      := (exeConfig.Has("postLaunchDelay"))      ? exeConfig["postLaunchDelay"]      : this.postLaunchDelay
        this.fullscreenDelay      := (exeConfig.Has("fullscreenDelay"))      ? exeConfig["fullscreenDelay"]      : this.fullscreenDelay
        this.mouseMoveDelay       := (exeConfig.Has("mouseMoveDelay"))       ? exeConfig["mouseMoveDelay"]       : this.mouseMoveDelay
        this.checkPropertiesDelay := (exeConfig.Has("checkPropertiesDelay")) ? exeConfig["checkPropertiesDelay"] : this.checkPropertiesDelay

        ; parse dir
        tempDir := ""
        if (exeConfig.Has("dir")) {
            tempDir := exeConfig["dir"]
        }
        else if (exeConfig.Has("dirs")) {
            tempDir := exeConfig["dirs"]
        }

        if (tempDir != "") {
            if (Type(tempDir) = "Array") {
                if (tempDir.Length > 1) {
                    this.dir := []
                    for path in tempDir {
                        this.dir.Push(validateDir(path))
                    }
                }
                else if (tempDir.Length = 1) {
                    this.dir := validateDir(tempDir[1])
                }
            }
            else {
                this.dir := validateDir(tempDir)
            }
        }

        ; parse ignoreEXEs
        if (exeConfig.Has("ignoreEXEs")) {
            this.ignoreEXEs := Type(exeConfig["ignoreEXEs"]) = "Array" ? exeConfig["ignoreEXEs"] : [exeConfig["ignoreEXEs"]]
        }
        else if (exeConfig.Has("ignoreEXE")) {
            this.ignoreEXEs := Type(exeConfig["ignoreEXE"]) = "Array" ? exeConfig["ignoreEXE"] : [exeConfig["ignoreEXE"]]
        }

        ; parse default args
        if (exeConfig.Has("defaultArgs")) {
            if (Type(exeConfig["defaultArgs"]) = "Array") {
                for item in exeConfig["defaultArgs"] {
                    if (InStr(item, A_Space) && (!(SubStr(item, 1, 1) = '"' && SubStr(item, -1, 1) = '"')
                        || !(SubStr(item, 1, 1) = "'" && SubStr(item, -1, 1) = "'"))) {
    
                        this.defaultArgs.Push('"' . item . '"')
                    }
                    else {
                        this.defaultArgs.Push(item)
                    }
                }
            }
            else if (exeConfig["defaultArgs"] != "") {
                argArr := StrSplitIgnoreQuotes(exeConfig["defaultArgs"])
                if (argArr.Length > 0) {
                    this.defaultArgs.Push(argArr*)
                }
            }
        }

        ; parse hotkeys
        this.mouse := (exeConfig.Has("mouse"))   ? exeConfig["mouse"]   : this.mouse
        if (exeConfig.Has("hotkeys")){
            if (exeConfig["hotkeys"].Has("buttonTime")) {
                this.hotkeyButtonTime := exeConfig["hotkeys"]["buttonTime"]
                exeConfig["hotkeys"].Delete("buttonTime")
            }

            this.hotkeys := exeConfig["hotkeys"]
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
    
        ; add custom keys from config
        for key, value in exeConfig {
            if (!this.HasOwnProp(key)) {
                ; needs to be a try bc functions arent included in HasOwnProp??
                try this.%key% := value
            }
        }

        ; parse monitor info
        monitorInfo := getMonitorInfo(this.monitorNum)
        this._monitorX := monitorInfo[1]
        this._monitorY := monitorInfo[2]
        this._monitorW := monitorInfo[3]
        this._monitorH := monitorInfo[4]
    }

    ; runs the program
    ;  args - args to run the program with
    ;
    ; returns null
    launch(args*) {
        global globalStatus
        
        this.time := A_TickCount

        monitorInfo := getMonitorInfo(this.monitorNum)
        this._monitorX := monitorInfo[1]
        this._monitorY := monitorInfo[2]
        this._monitorW := monitorInfo[3]
        this._monitorH := monitorInfo[4]

        restoreCritical := A_IsCritical
        Critical("Off")

        restoreAllowExit := this.allowExit
        this.allowExit   := true
        this.shouldExit  := false

        restoreHotkeys := this.hotkeys
        this.hotkeys := Map()
        
        writeLog(this.id . " launching...", "PROGRAM")

        ; if require internet & internet check fails -> return
        if (this.requireInternet) {
            if (!waitForInternetProgram(this.id, 30)) {
                writeLog("Failed to launch " . this.id . " - no internet", "PROGRAM")
                Critical(restoreCritical)
                return
            }
        }

        if (this.shouldExit) {
            writeLog(this.id . " exiting...", "PROGRAM")
            Critical(restoreCritical)
            resetLoadScreen()
            return
        }

        this.allowExit := false

        setLoadScreen("Waiting for " . this.name . "...")

        this._launchArgs := ObjDeepClone(this.defaultArgs)
        if (Type(args) = "Array") {
            for item in args {
                if (InStr(item, A_Space) && (!(SubStr(item, 1, 1) = '"' && SubStr(item, -1, 1) = '"')
                    || !(SubStr(item, 1, 1) = "'" && SubStr(item, -1, 1) = "'"))) {

                    itemString := '"' . item . '"'
                    if (!inArray(itemString, this._launchArgs)) {
                        this._launchArgs.Push(itemString)
                    }
                }
                else if (!inArray(item, this._launchArgs)) {
                    this._launchArgs.Push(item)
                }
            }
        }
        else {
            argArr := StrSplitIgnoreQuotes(args)
            for item in argArr {
                if (!inArray(item, this._launchArgs)) {
                    this._launchArgs.Push(item)
                }
            }
        }

        writeLog(this.id . " running program (args: " . toString(this._launchArgs) . ")...", "PROGRAM")

        ; if launch returns false -> assume failed
        if (this._launch(this._launchArgs*) = false) {
            writeLog("Failed to launch " . this.id, "PROGRAM")
            Critical(restoreCritical)
            resetLoadScreen()
            return
        }
        
        ; handle launcher if program has one (ie. Fallout 3)
        if (this.launcher.Count > 0 && (this.launcher.Has("exe") || this.launcher.Has("wndw"))) {
            this.allowExit := true

            launcherWNDW := (this.launcher.Has("wndw")) ? this.launcher["wndw"] : ("ahk_exe " this.launcher["exe"])
            launcherDelay := (this.launcher.Has("delay")) ? Integer(this.launcher) : 1000

            writeLog(this.id . " bypassing launcher...", "PROGRAM")    

            count := 0
            maxCount := 30
            ; wait for executable
            while (!this.exists(!this.background) && !WinShown(launcherWNDW) && count < maxCount) {
                if (this.shouldExit) {
                    writeLog(this.id . " exiting...", "PROGRAM")
                    Critical(restoreCritical)
                    resetLoadScreen()
                    return
                }

                Sleep(100)
                count += 1
            }

            ; cancel launch if launcher never shows
            if (!this.exists(!this.background) && !WinShown(launcherWNDW)) {
                writeLog("Failed to launch " . this.id . " - waiting for launcher timeout", "PROGRAM")
                Critical(restoreCritical)
                resetLoadScreen()
                return
            }

            ; flatten double array
            mouseArr := []
            if (this.launcher.Has("mouseClick")) {
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
            }

            globalStatus["loadscreen"]["overrideWNDW"] := launcherWNDW

            hiddenCount := 0
            maxCount := 3
            ; try to skip launcher as long as exectuable is shown
            while (!this.exists(!this.background) && hiddenCount < maxCount) {
                if (this.shouldExit) {
                    globalStatus["loadscreen"]["overrideWNDW"] := ""

                    writeLog(this.id . " exiting...", "PROGRAM")
                    Critical(restoreCritical)
                    resetLoadScreen()
                    return
                }

                if (mouseArr.Length > 0) {
                    loop (mouseArr.Length / 2) {
                        index := ((A_Index - 1) * 2) + 1
    
                        Sleep(launcherDelay)
    
                        if (this.exists(!this.background)) {
                            break
                        }
                        if (!WinShown(launcherWNDW)) {
                            hiddenCount += 1
                            break
                        }
                        if (this.shouldExit) {
                            globalStatus["loadscreen"]["overrideWNDW"] := ""
        
                            writeLog(this.id . " exiting...", "PROGRAM")
                            Critical(restoreCritical)
                            resetLoadScreen()
                            return
                        }
    
                        MouseClick("Left"
                            , percentWidthRelativeWndw(mouseArr[index], launcherWNDW)
                            , percentHeightRelativeWndw(mouseArr[index + 1], launcherWNDW)
                            ,,, "D"
                        )
                        Sleep(75)
                        MouseClick("Left",,,,, "U")
                        Sleep(75)
                        HideMouseCursor()
                    }
                }
                else {
                    Sleep(launcherDelay)

                    if (this.exists(!this.background)) {
                        break
                    }
                    if (!WinShown(launcherWNDW)) {
                        hiddenCount += 1
                        continue
                    }
                    if (this.shouldExit) {
                        continue
                    }

                    if (this.launcher.Has("sendKey")) {
                        SendSafe(this.launcher["sendKey"])
                    }
                }
            }

            this.allowExit := false
            globalStatus["loadscreen"]["overrideWNDW"] := ""
        }

        count := 0
        maxCount := 200
        ; wait for just exe
        while (this.getEXE() = "" && count < maxCount) {
            count += 1
            Sleep(50)
        }

        this.allowExit := restoreAllowExit
        this.hotkeys   := restoreHotkeys

        globalStatus["loadscreen"]["show"] := false
        globalStatus["loadscreen"]["overrideWNDW"] := ""

        if (count = maxCount) {
            writeLog("Failed to launch " . this.id . " - waiting for program timeout", "PROGRAM")
            
            Critical(restoreCritical)
            resetLoadScreen()
            return
        }

        if (!this.background) {
            count := 0
            ; wait for program to show
            while (!this.exists(true) && count < maxCount) {
                count += 1
                Sleep(50)
            }

            if (count = maxCount) {
                writeLog("Failed to launch " . this.id . " - waiting for program timeout", "PROGRAM")

                Critical(restoreCritical)
                resetLoadScreen()
                return
            }

            ; read properties of window after delay
            SetTimer(DelayCheckProperties, Neg(this.checkPropertiesDelay))
        }

        if (this.priority != "") {
            ProcessSetPriority(this.priority, this.getPID())
        }

        writeLog(this.id . " launched successfully", "PROGRAM")
        Critical(restoreCritical)
        resetLoadScreen()

        return

        ; saves screenshot & updates program data
        DelayCheckProperties() {
            global globalStatus

            if (!this.exists(true) || globalStatus["currProgram"]["id"] != this.id) {
                return
            }

            ; wait for program to get focused
            if (this.hungCount > 0 || this._currShownEXE = "" || !WinActive("ahk_exe " this._currShownEXE)) {
                SetTimer(CheckPropertiesTimer, 500)
                return
            }

            this.checkFullscreen()
            saveScreenshot(this.id, this.monitorNum)

            return
        }

        ; if delay launch fails
        CheckPropertiesTimer() {
            global globalStatus

            if (!this.exists(true) || globalStatus["currProgram"]["id"] != this.id) {
                SetTimer(CheckPropertiesTimer, 0)
                return
            }

            if (this.hungCount > 0 || this._currShownEXE = "" || !WinActive("ahk_exe " this._currShownEXE)) {
                return
            }

            this.checkFullscreen()
            saveScreenshot(this.id, this.monitorNum)

            SetTimer(CheckPropertiesTimer, 0)
            return
        }
    }
    _launch(args*) {
        try {
            ; run dir\exe
            if (!IsObject(this.exe) && !IsObject(this.dir) && this.exe != "") {
                ; Run this.dir . this.exe . A_Space . joinArray(args), this.dir, ((this.background) ? "Hide" : "Max")
                RunAsUser(this.dir . this.exe, args, this.dir)
            }
            ; fail
            else {
                ErrorMsg(this.name . "does not have an exe defined, it cannot be launched with default settings")
                return false
            }
        }
        catch {
            return false
        }
    }

    ; designed to be overwritten -> runs after first successful restore
    postLaunch() {
        this._postLaunch()
    }
    _postLaunch() {
        if (this.postLaunchSend != "") {
            if (IsObject(this.postLaunchSend)) {
                this.send(this.postLaunchSend[1])

                if (this.postLaunchSend.Length > 1) {
                    SetTimer(SendKeyTimer.Bind(2), Neg(this.postLaunchDelay))
                }
            }
            else {
                this.send(this.postLaunchSend)
            }
        }

        return

        SendKeyTimer(index) {
            global globalStatus

            if (!this.exists()) {
                return
            }

            if (this._currShownEXE = "" || !WinActive("ahk_exe " this._currShownEXE) || this.shouldExit || globalStatus["currProgram"]["id"] != this.id) {
                return
            }

            this.send(this.postLaunchSend[index])
            if (this.postLaunchSend.Length > index) {
                SetTimer(SendKeyTimer.Bind(index + 1), Neg(this.postLaunchDelay))
            }

            return
        }
    }

    ; activates the program's window
    restore() {
        global globalStatus

        ; exit the program if failed to find window
        if (this._waitingWindowFailed) {
            this.exit()
            return
        }
        if (this.hungCount > 0 || this.shouldExit || this._waitingWindowTimer) {
            return
        }

        currHWND := this.getHWND()
        ; check if program is running but window is missing
        if (!currHWND && !this.background && !this._waitingWindowTimer) {
            SetTimer(CheckMissingWindow, Neg(1000))
            this._waitingWindowTimer := true
            return
        }

        ; check if program was minimized -> restore windows in reverse order from minimized
        if (this.minimized) {
            if (this._currHWNDList.Length > 0) {
                loop this._currHWNDList.Length {
                    index := (this._currHWNDList.Length + 1) - A_Index

                    if (WinShown(this._currHWNDList[index])) {
                        WinActivateForeground(this._currHWNDList[index])
                    }

                    if (A_Index < this._currHWNDList.Length) {
                        Sleep(200)
                    }
                }

                this._currHWNDList := []
            }
            
            this.minimized := false
        }
        
        if (globalStatus["currGui"] != "pause") {
            this.resume()
        }
        
        restoreTMM := A_TitleMatchMode

        overlayHWND := 0
        if (globalStatus["currOverlay"]) {
            SetTitleMatchMode(3)
            overlayHWND := WinShown(globalStatus["currOverlay"])
            SetTitleMatchMode(restoreTMM)

            ; check that overlay still exists
            if (!overlayHWND) {
                globalStatus["currOverlay"] := ""
            }
        }

        restoreSuccess := true
        ; activate the overlay window if appropriate
        if (overlayHWND) {
            WinGetPos(&overlayX, &overlayY, &overlayW, &overlayH, overlayHWND)
            MouseGetPos(&mouseX, &mouseY)

            ; activate the program then the overlay if program needs fix
            if (this.overlayActivateFix) {              
                overlayIndex := 0
                programIndex := 0

                winList := WinGetList()
    
                currIndex := 1
                loop winList.Length {
                    if (WinShown(winList[A_Index]) && WinActivatable(winList[A_Index])) {
                        if (winList[A_Index] = overlayHWND) {
                            overlayIndex := currIndex
                        }
                        else if (winList[A_Index] = currHWND) {
                            programIndex := currIndex
                        }

                        currIndex += 1
                    }
    
                    if (overlayIndex != 0 && programIndex != 0) {
                        break
                    }
                }
    
                ; check that curr win is right under picture in picture
                if (!WinActive(overlayHWND) || (programIndex - overlayIndex) != 1) {
                    restoreSuccess := this._restore()
                    Sleep(250)
                    WinActivateForeground(overlayHWND)
    
                    Sleep(100)
                    MouseMove(overlayX + (overlayW / 2), overlayY + (overlayH / 2))
                    Sleep(70)
                    
                    ; restore mouse pos if its important to the program
                    if (this.mouse.Count > 0) {
                        MouseMove(mouseX, mouseY)
                    }
                    else {
                        HideMouseCursor()
                    }
                }
            }
            ; activate overlay if under mouse
            else if (mouseX >= overlayX && mouseX <= (overlayX + overlayW)
                && mouseY >= overlayY && mouseY <= (overlayY + overlayH)) {
              
                WinActivateForeground(overlayHWND)
            }
            ; activate program
            else {
                restoreSuccess := this._restore()
            }
        }
        else {
            restoreSuccess := this._restore()
        }

        ; on fail - try to tab to a different window, then restore
        ; this is an attempt to fix when a window get stuck in an unactivatable state
        if (restoreSuccess = false && WinResponsive(currHWND)) {
            activateLoadScreen()
            Sleep(80)
            this._restore()
        }

        ; after first restore -> perform post launch action
        if (!this._waitingPostLaunchTimer) {
            SetTimer(DelayPostLaunch, Neg(this.postLaunchDelay))
            this._waitingPostLaunchTimer := true
        }

        ; after first restore -> fullscreen window if required
        if (!this._waitingFullscreenTimer) {
            SetTimer(DelayFullscreen, 
                Neg(this._overrideFullscreenDelay != 0 ? this._overrideFullscreenDelay : this.fullscreenDelay)
            )
            this._waitingFullscreenTimer  := true
            this._overrideFullscreenDelay := 0
        }

        ; after first restore -> move mouse to proper position
        if (!this._waitingMouseMoveTimer) {
            ; hide mouse
            x := this.mouse.Has("initialPos") ? this.mouse["initialPos"][1] : 1
            y := this.mouse.Has("initialPos") ? this.mouse["initialPos"][2] : 1

            if (this.mouseMoveDelay != 0) {
                SetTimer(DelayMouseMove.Bind(x, y), Neg(this.mouseMoveDelay))
            } 
            else {
                DelayMouseMove(x, y)
            }

            this._waitingMouseMoveTimer := true
        }

        return

        ; do custom post launch function
        DelayPostLaunch() {
            global globalStatus

            if (!this.exists()) {
                return
            }

            if (this._currShownEXE = "" || !WinActive("ahk_exe " this._currShownEXE) || this.shouldExit || globalStatus["currProgram"]["id"] != this.id) {
                this._waitingPostLaunchTimer := false
                return
            }

            this.postLaunch()
            return
        }

        ; fullscreen window
        DelayFullscreen() {
            global globalStatus

            if (!this.exists()) {
                return
            }

            if (this._currShownEXE = "" || !WinActive("ahk_exe " this._currShownEXE) || this.shouldExit || globalStatus["currProgram"]["id"] != this.id) {
                this._waitingFullscreenTimer  := false
                return
            }

            hwnd := this.getHWND()

            ; don't interact if window is a TOOLWINDOW (for launchers)
            if (hwnd && WinShown(hwnd) && !(WinGetExStyle(hwnd) & 0x00000080)) {               
                WinGetPos(&X, &Y, &W, &H, hwnd)
                if ((X + (W * 0.05)) < this._monitorX || X >= ((this._monitorX + this._monitorW) * 0.95)
                    || (Y + (H * 0.05)) < this._monitorY || Y >= ((this._monitorY + this._monitorH) * 0.95)) {
                    
                    WinMove(this._monitorX, this._monitorY,,, hwnd)
                }

                if (this.requireFullscreen && !this.checkFullscreen()) {
                    this.fullscreen()

                    ; if fullscreen failed, try again
                    if (!this.fullscreened) {
                        this._waitingFullscreenTimer := false
                    }
                }
            ; window is not valid for interaction - wait till it is
            } else {
                this._waitingFullscreenTimer := false
            }

            return
        }

        ; move mouse to x, y position
        DelayMouseMove(x, y) {
            global globalStatus

            if (!this.exists() || this.shouldExit || this._restoreMousePos.Length = 2) {
                return
            }

            if (this._currShownEXE = "" || !WinActive("ahk_exe " this._currShownEXE) || globalStatus["currProgram"]["id"] != this.id) {
                this._waitingMouseMoveTimer := false
                return
            }
            
            MouseMovePercent(x, y, this.monitorNum)
            return
        }

        ; window missing check
        CheckMissingWindow(loopCount := 0) {
            ; if window exists -> stop checking
            if (this.getHWND() || !this.exists() || this.shouldExit) {
                this._waitingWindowTimer := false
                if (loopCount > 15) {
                    resetLoadScreen()
                }

                return
            }

            ; at 15s mark -> enable load screen to wait
            if (loopCount = 15) {            
                setLoadScreen("Waiting for " . this.name . "...")
            }
            ; ; at 20s mark -> reset program
            ; else if (loopCount > 19) {
            ;     this._waitingWindowTimer := false

            ;     restoreCritical := A_IsCritical
            ;     Critical("On")

            ;     this.exit(false)
            ;     Sleep(500)
            ;     this.launch(ObjDeepClone(this._launchArgs)*)

            ;     Critical(restoreCritical)
            ;     return
            ; }
            ; at 30s mark -> exit program
            else if (loopCount > 30) {
                this._waitingWindowFailed := true
                this._waitingWindowTimer := false
                return
            }
            
            SetTimer(CheckMissingWindow.Bind(loopCount + 1), Neg(1000))
            return
        }
    }
    _restore() {
        global globalStatus

        exe := (this._currShownEXE != "" && ProcessExist(this._currShownEXE)) ? this._currShownEXE : this.getEXE()
        exeWNDW := (IsInteger(exe) ? "ahk_pid " : "ahk_exe ") . exe
        if (!WinShown(exeWNDW)) {
            return
        }
        
        try {       
            ; try to activate window if non active
            overlayActive := (this.overlay) ? WinActive(this.overlay) : false
            if (!WinActive(exeWNDW) || overlayActive) {
                return WinActivateForeground(this.getHWND())
            }
        }
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
        Sleep(200)

        this._minimize()

        this.minimized := true

        ; reset fullscreen status on minimize
        this.fullscreened := false
        this._waitingFullscreenTimer  := false
        this._waitingMouseMoveTimer   := false
        this._overrideFullscreenDelay := 1000

        Critical(restoreCritical)
    }
    _minimize() {
        loop this._currHWNDList.Length {
            WinMinimizeMessage(this._currHWNDList[A_Index])

            if (A_Index < this._currHWNDList.Length) {
                Sleep(200)
            }
        }
    }

    switchMonitor(newMonitor) {
        global globalStatus

        hwnd := this.getHWND()
        if (!hwnd || this.background || !IsInteger(newMonitor) || Integer(newMonitor) < 0) {
            return
        } 

        this.monitorNum := Integer(newMonitor)
        
        monitorInfo := getMonitorInfo(this.monitorNum)
        this._monitorX := monitorInfo[1]
        this._monitorY := monitorInfo[2]
        this._monitorW := monitorInfo[3]
        this._monitorH := monitorInfo[4]

        if (this.id = globalStatus["currProgram"]["id"] && WinShown(hwnd) && !(WinGetExStyle(hwnd) & 0x00000080)) {
            WinGetPos(&X, &Y, &W, &H, hwnd)

            ; check that window is showing within proper monitor bounds, move to correct monitor if not
            ; (custom fullscreen functions usually cause the window to get fullscreened on currently showing monitor)
            if ((X + (W * 0.05)) < this._monitorX || X >= ((this._monitorX + this._monitorW) * 0.95) 
                || (Y + (H * 0.05)) < this._monitorY || Y >= ((this._monitorY + this._monitorH) * 0.95)) {
                
                try WinRestoreMessage(hwnd)
                Sleep(75)
                try WinMove(this._monitorX, this._monitorY,,, hwnd)
                Sleep(75)

                this._restoreMousePos := []
                if (this.requireFullscreen && !this.checkFullscreen()) {
                    try this.fullscreen()
                }

                if (this.mouse.Has("initialPos")) {
                    MouseMovePercent(this.mouse["initialPos"][1], this.mouse["initialPos"][2], this.monitorNum)
                } else {
                    HideMouseCursor()
                }
            }
        }

        ; reset fullscreen status on switching monitors
        this.fullscreened := false
        this._waitingFullscreenTimer  := false
        this._overrideFullscreenDelay := 1000

        Sleep(250)
    }

    ; fullscreen window if not fullscreened
    fullscreen() {
        global globalStatus
        global globalConfig

        if (this.hungCount > 0) {
            return
        }
        
        restoreCritical := A_IsCritical
        Critical("On")

        hwnd := this.getHWND()

        allowActivate := globalConfig["General"].Has("ForceActivateWindow") && globalConfig["General"]["ForceActivateWindow"]
        ; activate window for _function()
        if (!WinActive(hwnd) && allowActivate) {
            this._restore()
            Sleep(100)
        }

        WinGetPos(&X, &Y, &W, &H, hwnd)
        ; check that window is showing within proper monitor bounds, move to correct monitor if not
        ; (custom fullscreen functions usually cause the window to get fullscreened on currently showing monitor)
        if ((X + (W * 0.05)) < this._monitorX || X >= ((this._monitorX + this._monitorW) * 0.95)
            || (Y + (H * 0.05)) < this._monitorY || Y >= ((this._monitorY + this._monitorH) * 0.95)) {
            
            WinMove(this._monitorX, this._monitorY,,, hwnd)
        }

        this._fullscreen()

        Critical(restoreCritical)

        Sleep(50)
        this.checkFullscreen()
    }
    _fullscreen() {
        global globalStatus

        if (this.fullscreenSend != "") {
            if (IsObject(this.fullscreenSend)) {
                loop this.fullscreenSend.Length {
                    this.send(this.fullscreenSend[A_Index])

                    if (A_Index < this.fullscreenSend.Length) {
                        sleepTime := this.fullscreenDelay / 5

                        loop 5 {
                            Sleep(sleepTime)

                            if (!this.exists() || this._currShownEXE = "" || !WinActive("ahk_exe " this._currShownEXE) 
                                || this.shouldExit || globalStatus["currProgram"]["id"] != this.id) {
                                return
                            }
                        }
                    }
                }
            }
            else {
                this.send(this.postLaunchSend)
            }

            return
        }

        hwnd := this.getHWND()

        try {
            if (!WinShown(hwnd)) {
                return
            }
    
            WinGetClientPos(,, &W, &H, hwnd)
            if (W < 1 || H < 1) {
                return
            }
    
            ; remove border around window
            WinSetStyle(-0xC40000, hwnd)
            Sleep(50)
    
            WinSetExStyle(-0x00000200, hwnd)
            Sleep(50)
        }
        catch {
            return
        }

        ; TODO - GET BETTER WAY TO CALCULATE FULLSCREEN ASPECT RATIO

        ; currently rounding the INACCURATE client area as returned by WinGetClientPos
        ; bc of that i'm rounding the reported aspect ratios to common ones
        validWidths  := [this._monitorW, 21, 16, 4]
        validHeights := [this._monitorH,  9,  9, 3]

        minDiff := 69
        aspectIndex := 1
        loop validWidths.Length {
            currDiff := Abs((W / H) - (validWidths[A_Index] / validHeights[A_Index]))

            if (currDiff < minDiff) {
                minDiff := currDiff
                aspectIndex := A_Index
            }
        }

        multiplier := Min(this._monitorW / validWidths[aspectIndex], this._monitorH / validHeights[aspectIndex])
        newW := validWidths[aspectIndex]  * multiplier
        newH := validHeights[aspectIndex] * multiplier

        try WinMove(this._monitorX + ((this._monitorW - newW) / 2), this._monitorY + ((this._monitorH - newH) / 2), newW, newH, hwnd)
    }

    ; return if program is "fullscreen" & update the fullscreen value of the program
    checkFullscreen() {
        if (this.hungCount > 0) {
            return
        }

        oldFullscreened := this.fullscreened
        this.fullscreened := this._checkFullscreen()

        if (oldFullscreened != this.fullscreened) {
            this._waitingFullscreenTimer := false
        }

        return this.fullscreened
    }
    _checkFullscreen() {
        hwnd := this.getHWND()

        try {
            WinGetClientPos(&X, &Y, &W, &H, hwnd)
            return (!(WinGetStyle(hwnd) & 0x20800000) 
                && ((W >= (this._monitorW * 0.95) && W <= (this._monitorW * 1.05)) || (H >= (this._monitorH * 0.95) && H <= (this._monitorH * 1.05)))
                && (X + (W * 0.05)) >= this._monitorX && X < (this._monitorX + this._monitorW) 
                && (Y + (H * 0.05)) >= this._monitorY && Y < (this._monitorY + this._monitorH)) ? true : false
        }

        return false
    }

    ; check if the program is responding
    checkResponding() {
        return this._checkResponding()
    }
    _checkResponding() {
        hwnd := this.getHWND()
        if (hwnd = 0) {
            return true
        }

        return WinResponsive(hwnd)
    }

    ; check if program executable exists
    ;  requireShown - require program to be shown
    ;  checkHung - check the responding state of the program
    ;
    ; returns true if program exists
    exists(requireShown := false, checkHung := false) {
        ; skip cycle if waiting for exist timers
        if (this._waitingExistTimer) {
            return true
        }

        ; skip cycle if exe & waiting for user choice dialog
        if (this._waitingHungTimer && ProcessExist(this._currEXE)) {
            return true
        }

        existed := false
        if (requireShown) {
            existed := (this._currShownEXE != "") ? true : false
        }
        else {
            existed := (this._currEXE != "") ? true : false
        }
       
        ; update curr exe & hwnd
        this.getEXE()
        this.getHWND()

        existing := this._exists(requireShown)
        ; if not existing and existed, and if multiple exe/wndw, wait and check for new window
        if (existed && !existing && !this._waitingExistTimer && (IsObject(this.exe) || IsObject(this.wndw) || (this.exe = "" && this.wndw = ""))) {
            SetTimer(DelayCheckExists.Bind(0, 0), Neg(250))
            this._waitingExistTimer := true

            return true
        }

        if (!this.paused && this.allowHungCheck && checkHung) {
            ; check if wndw hung 
            if (existing && !this.checkResponding()) {
                if (this.hungCount = 0) {
                    SetTimer(CheckHungTimer, Neg(1000))
                    this.hungCount += 1
                }
            }
            ; reset hung counter if wndw not hung
            else if (this.hungCount > 0) {
                this.hungCount := 0
                this._waitingHungTimer := false
            }
        }

        return existing

        ; check if exists
        DelayCheckExists(loopCount := 0, existedCount := 0) {
            this.getEXE()
            this.getHWND()
            
            ; return to main exists() if either:
            ; - loopCount = timeout (1.5s)
            ; - existedCount = program exists (0.75s)
            if (loopCount > 5 || existedCount > 2) {
                this._waitingExistTimer := false
                return
            }

            if (this._currEXE = "") {
                existedCount := -1

                ; reset loop count if existed recently 
                if (existedCount > 0) {
                    loopCount := -1
                }
            }

            SetTimer(DelayCheckExists.Bind(loopCount + 1, existedCount + 1), Neg(250))
            return
        }

        ; repeated check while program is hung
        CheckHungTimer() {
            global globalGuis
            global globalStatus

            ; if exists & hung
            currPID := this.getPID()
            if (!globalStatus["suspendScript"] && globalStatus["currProgram"]["id"] = this.id 
                && !this.paused && !this.minimized && ProcessExist(currPID) && !this.checkResponding()) {               
                
                if (this.hungCount > this.maxHungCount) {
                    ; create "wait for program" gui dialog
                    if (!this._waitingHungTimer) {
                        createInterface("choice",,, this.name " has stopped responding", "Wait",,, "Exit", "ProcessKill " . currPID, "FF0000")
                        this._waitingHungTimer := true
                    }
                    ; reset hung count if gui dialog doesn't exist
                    else if (!globalGuis.Has("choice")) {
                        this.hungCount := 0
                        this._waitingHungTimer := false
                    }
                }

                this.hungCount += 1
                writeLog(this.id . " hanging... (" . this.hungCount . ")")
                SetTimer(CheckHungTimer, Neg(1000))
            }
            ; reset hung count if no longer exists/hung
            else {
                this.hungCount := 0

                ; close gui dialog if it exists
                if (this._waitingHungTimer && globalGuis.Has("choice")) {
                    this._waitingHungTimer := false
                    globalGuis["choice"].Destroy()
                }
            }
            
            return
        }
    }
    _exists(requireShown) {
        if (requireShown) {
            return (this._currShownEXE != "") ? true : false
        }
        else {
            return (this._currEXE != "") ? true : false
        }
    }

    ; exit program 
    exit(updateGlobalRunning := true) {
        global globalStatus
        global globalRunning

        ; disable hotkeys
        this.hotkeys := Map()
        this.shouldExit := true
        
        writeLog(this.id . " exiting...", "PROGRAM")

        ; close the keyboard if open
        if (keyboardExists()) {
            closeKeyboard()
        }
        
        setLoadScreen("Exiting " . this.name . "...")

        restoreCritical := A_IsCritical
        Critical("Off")

        this._exit()

        writeLog(this.id . " exited", "PROGRAM")
        
        Sleep(500)
        resetLoadScreen()

        if (updateGlobalRunning) {
            updatePrograms()
        }

        Critical(restoreCritical)
        return
    }
    _exit() {
        try {
            count := 0
            maxCount := 60
            ; wait for program executable to close
            while (this.exists() && count < maxCount) {
                ; update PID list
                this.getEXE()
                if (this._currPIDList.Length = 0) {
                    return
                }

                ; try to exit all exes every 7.5s or once 25s have passed
                if (count >= 50 || Mod(count, 15) = 0) {
                    currPID := this._currPIDList[1]
                    currName := ProcessGetName(currPID)

                    internalLoopCount := 0
                    while (true) {
                        try {
                            if (!ProcessExist(currPID)) {
                                break
                            }
                            
                            ; go hard in the paint when
                            ;  - the program is hung
                            ;  - the program has been exiting for >22.5s
                            ;  - over 15 PIDs have been cycled during the exit
                            if (this.hungCount = 0 && count < 50 && internalLoopCount < 15) {
                                ; attempt to processclose >= 15s
                                if (!currName || count >= 30) {
                                    ProcessClose(currPID)
                                } 
                                else {
                                    WinCloseAll("ahk_pid " currPID)
                                }
    
                                Sleep(75)
                            }
                            ; THIS IS THE HARD IN THE PAINT PART
                            else {
                                writeLog(this.id . " gone nuclear (PID: " . currPID . ")", "PROGRAM")
                                ProcessKill(currPID)
                            }


                            ; big assumption time - no exe without a proper name is worth saving
                            if (!currName) {
                                this._currPIDList.RemoveAt(1)
                            }

                            ; update PID list
                            this.getEXE()

                            ; if winclose did not immediately exit program, then wait
                            if (this._currPIDList.Length = 0 || this._currPIDList[1] = currPID) {
                                break
                            }

                            ; if winclose did exit program, move to next
                            currPID := this._currPIDList[1]
                            currName := ProcessGetName(currPID)

                            internalLoopCount += 1
                        }
                    }
                }
                
                count += 1
                Sleep(500)
            }
        }
    }

    ; run custom post exit function
    postExit() {
        this._postExit()

        wndw := ""
        if (this.launcher.Has("wndw")) {
            wndw := this.launcher["wndw"]
        }
        else if (this.launcher.Has("exe")) {
            wndw := "ahk_exe " this.launcher["exe"]
        }

        ; close program launcher if it still exists
        if (wndw != "") {
            count := 0
            maxCount := 100
            while (WinHidden(wndw) && !WinShown(wndw) && count < maxCount) {
                count += 1
                Sleep(100)
            }
    
            if (WinShown(wndw)) {
                WinClose(wndw)
            }
        }
    }
    _postExit() {
        return
    }
    
    ; runs custom pause function on pause
    pause() {
        global globalStatus
        global globalConfig

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
            this._restoreMousePos := [x, y]
        }

        try {
            if (this.id = globalStatus["currProgram"]["id"] && this.hungCount = 0 
                && !globalStatus["suspendScript"] && !globalStatus["desktopmode"]) {
                    
                allowActivate := globalConfig["General"].Has("ForceActivateWindow") && globalConfig["General"]["ForceActivateWindow"]
                ; activate window for _function()
                if (!WinActive(this.getHWND()) && allowActivate) {
                    this._restore()
                    Sleep(100)
                }
    
                ; get new thumbnail
                saveScreenshot(this.id, this.monitorNum)
            }
        }

        this._pause()
        
        Critical(restoreCritical)
        return
    }
    _pause() {
        return
    }

    ; runs custom resume function after pause close
    resume() {
        global globalStatus
        global globalConfig

        if (!this.paused) {
            return
        }
        
        restoreCritical := A_IsCritical
        Critical("On")

        this.paused := false
        
        if (this._restoreMousePos.Length = 2) {
            MouseMove(this._restoreMousePos[1], this._restoreMousePos[2])
            this._restoreMousePos := []
        }

        try {
            if (this.id = globalStatus["currProgram"]["id"] && this.hungCount = 0 
                && !globalStatus["suspendScript"] && !globalStatus["desktopmode"]) {
                
                allowActivate := globalConfig["General"].Has("ForceActivateWindow") && globalConfig["General"]["ForceActivateWindow"]
                ; activate window for _function()
                if (!WinActive(this.getHWND()) && allowActivate) {
                    this._restore()
                    Sleep(100)
                }
    
                ; get new thumbnail
                saveScreenshot(this.id, this.monitorNum)
            }
        }
        
        this._resume()

        Critical(restoreCritical)
        return
    }
    _resume() {
        return
    }
    
    ; send key to program
    send(key, time := -1) {
        global globalStatus
        global globalConfig
        global globalRunning

        allowActivate := globalConfig["General"].Has("ForceActivateWindow") && globalConfig["General"]["ForceActivateWindow"]

        exe := (this._currShownEXE != "" && ProcessExist(this._currShownEXE)) ? this._currShownEXE : this.getEXE()
        exeWNDW := (IsInteger(exe) ? "ahk_pid " : "ahk_exe ") . exe
        if (this.id = globalStatus["currProgram"]["id"] && this.hungCount = 0 && !WinActive(exeWNDW) 
            && allowActivate && !globalStatus["suspendScript"] && !globalStatus["desktopmode"]) {
            
            this._restore()
            Sleep(100)
        }

        this._send(key, time)
    }
    _send(key, time := -1) {
        exe := (this._currShownEXE != "" && ProcessExist(this._currShownEXE)) ? this._currShownEXE : this.getEXE()
        exeWNDW := (IsInteger(exe) ? "ahk_pid " : "ahk_exe ") . exe

        try WindowSend(key, exeWNDW, time)
    }

    ; get program exe name
    getEXE() {
        global globalStatus
        global wmiCOM
        global mainPID
        
        maintainerPID := WinHidden(MAINLOOP) ? WinGetPID(WinHidden(MAINLOOP)) : 0

        launcherEXE := ""
        if (this.launcher.Count > 0) {
            restoreDHW := A_DetectHiddenWindows
            DetectHiddenWindows(true)
            
            if (this.launcher.Has("exe") && ProcessExist(this.launcher["exe"])) {
                launcherEXE := this.launcher["exe"]
            }
            else if (this.launcher.Has("wndw") && WinExist(this.launcher["wndw"])) {
                launcherEXE := WinGetProcessName(this.launcher["wndw"])
            }

            DetectHiddenWindows(restoreDHW)
        }

        toIgnore := ObjDeepClone(this.ignoreEXEs)
        ; ignore the launcher exe so not caught by _getEXE
        if (launcherEXE != "") {
            toIgnore.Push(launcherEXE)
        }

        ; get the exe regardless of if its background or not
        if (this._currEXE = "" || !ProcessExist(this._currEXE)) {
            this._currEXE := this._getEXE(false, toIgnore)
        }

        if (this.background || this._currEXE = "") {
            this._currShownEXE := ""
        }
        ; get the shown exe for a non-background program
        else if (this._currShownEXE = "" || !ProcessExist(this._currShownEXE) || !WinShown("ahk_exe " this._currShownEXE)) {
            if (WinShown((IsInteger(this._currEXE) ? "ahk_pid " : "ahk_exe ") . this._currEXE)) {
                this._currShownEXE := this._currEXE
            }
            else {
                this._currShownEXE := this._getEXE(true, toIgnore)
            }
        }

        ; check currPIDList
        currPID := (this._currEXE != "") ? ProcessExist(this._currEXE) : 0
        currShownPID := (this._currShownEXE != "") ? ProcessExist(this._currShownEXE) : 0
        
        foundPID := false
        foundShownPID := false

        toCheck := []
        toDelete := []
        ; build lists to 1.) check for child processes, 2.) delete from list
        loop this._currPIDList.Length {
            try {
                pid := this._currPIDList[this._currPIDList.Length - (A_Index - 1)]
                if ((currPID && pid = currPID) || (currShownPID && pid = currShownPID)) {
                    if (currPID && pid = currPID) {
                        foundPID := true
                    }
                    if (currShownPID && pid = currShownPID) {
                        foundShownPID := true
                    }
                }

                if (!ProcessExist(pid)) {
                    toDelete.Push(this._currPIDList.Length - (A_Index - 1))
                }

                toCheck.Push(pid)
            }
        }

        ; if process no longer exists -> remove from list
        for index in toDelete {
            try this._currPIDList.RemoveAt(index)
        }

        ; add currPID to list if not found
        if (!foundPID && currPID) {
            this._currPIDList.Push(currPID)
        }
        ; add currShownPID to list if not found
        if (!foundShownPID && currShownPID && currPID != currShownPID) {
            this._currPIDList.Push(currShownPID)
        } 

        ; add launcherEXE to toCheck list
        if (launcherEXE != "") {
            pid := ProcessExist(launcherEXE)
            if (pid) {
                toCheck.Push(pid)
            }
        }

        ; check if any of the current running exes have child processes
        if (toCheck.Length > 0) {
            query := "Select Name, ProcessId, ParentProcessId from Win32_Process Where ParentProcessId = "
            ignoredPID := ""
            loop toCheck.Length {
                ignoredPID .= toCheck[A_Index] . "|"
                query .= toCheck[A_Index]
                if (A_Index < toCheck.Length) {
                    query .= " OR ParentProcessId = "
                }
            }

            ignoredEXE := ""
            ; even check ignored programs for children
            for exe in this.ignoreEXEs {
                ignoredEXE .= StrLower(exe) . "|"
            }

            for process in wmiCOM.ExecQuery(query) {
                name := process.Name
                pid  := process.ProcessId
                if ((launcherEXE = "" || StrLower(launcherEXE) != StrLower(name)) && name != "" 
                    && !InStr(ignoredPID, pid . "|") && !InStr(ignoredEXE, StrLower(name) . "|")
                    && pid != mainPID && pid != maintainerPID) {
                    
                    this._currPIDList.Push(pid)
                }
            }
        }

        retEXE := (this._currShownEXE != "") ? this._currShownEXE : this._currEXE
        if (this.id = globalStatus["currProgram"]["id"] && globalStatus["currProgram"]["exe"] != retEXE) {
            globalStatus["currProgram"]["exe"] := retEXE
        }

        return retEXE
    }
    _getEXE(requireShown := false, ignoreEXE := "") {
        try {
            toDelete := []
            pidLength := this._currPIDList.Length
            loop pidLength {
                pid := this._currPIDList[pidLength - (A_Index - 1)]
                if (ProcessExist(pid)) {
                    processName := "eb4a1cf3-5c16-4659-8db0-2f4918747197"
                    if (requireShown && WinShown("ahk_pid " pid)) {
                        processName := ProcessGetName(pid)
                    }
                    else if (!requireShown) {
                        processName := ProcessGetName(pid)
                    }

                    ; the pid can sometimes be something without a title (ie. "System Idle Process")
                    ; this is worst case scenario - just return PID
                    if (processName != "eb4a1cf3-5c16-4659-8db0-2f4918747197") {
                        return (processName != "") ? processName : pid
                    }
                }
            }

            ; check all exes
            if (this.exe != "") {
                exe := checkRunningEXEs(this.exe, true, requireShown)
                if (exe != "") {
                    return exe
                }
            }
            ; check all wndws
            if (this.wndw != "") {
                wndw := checkRunningWNDWs(this.wndw, true, requireShown)
                if (wndw != "") {
                    return WinGetProcessName(wndw)
                }
            }
            ; check all exes in dir
            if (this.dir != "") {
                exe := checkRunningDIRs(this.dir, true, ignoreEXE, requireShown)
                if (exe != "") {
                    return exe
                }
            }
        }
        
        return ""
    }
    
    ; get program pid
    getPID() {
        return this._getPID()
    }
    _getPID() {
        exe := ""
        if (this._currShownEXE != "" && ProcessExist(this._currShownEXE)) {
            exe := this._currShownEXE
        }
        else if (this._currEXE != "" && ProcessExist(this._currEXE)) {
            exe := this._currEXE
        }
        else {
            exe := this.getEXE()
        }
        
        if (exe != "") {
            return ProcessExist(exe)
        }

        return 0
    }

    ; get program window hwnd
    getHWND() {
        global globalStatus

        oldHWND := this._currHWND
        this._currHWND := this._getHWND()
        if (this.id = globalStatus["currProgram"]["id"] && this._currHWND != globalStatus["currProgram"]["hwnd"]) {
            globalStatus["currProgram"]["hwnd"] := this._currHWND
            
            if (oldHWND != this._currHWND) {
                writeLog(this.id . " updated hwnd", "PROGRAM")
                this.checkFullscreen()
            }
        }

        return this._currHWND
    }
    _getHWND() {  
        try {
            hwndList := this.getHWNDList()

            if (hwndList.Length > 0) {
                return hwndList[1]
            }
        }      
        
        return 0
    }

    ; get program all windows ids
    getHWNDList() {
        global globalStatus

        this._currHWNDList := this._getHWNDList()
        if (this.overlay != "") {
            restoreTMM := A_TitleMatchMode
            SetTitleMatchMode(3)

            overlayHWND := WinShown(this.overlay)
            if (overlayHWND) {
                loop this._currHWNDList.Length {
                    if (overlayHWND = this._currHWNDList[A_Index]) {
                        this._currHWNDList.RemoveAt(A_Index)
                        break
                    }
                }

                if (!globalStatus["currOverlay"] || !WinShown(globalStatus["currOverlay"])) {
                    globalStatus["currOverlay"] := this.overlay
                }
            }
            else if (globalStatus["currOverlay"] && !WinShown(globalStatus["currOverlay"])) {
                globalStatus["currOverlay"] := ""
            }

            SetTitleMatchMode(restoreTMM)
        }

        return this._currHWNDList
    }
    _getHWNDList() {
        restoreDHW := A_DetectHiddenWindows
        DetectHiddenWindows(this.background)

        winList := []
        tempWinList := []
        if (this._currPIDList.Length = 0) {
            try this.getEXE()
        }

        pidLength := this._currPIDList.Length
        ; check hwnd of every running exe
        loop pidLength {
            try {
                pid := this._currPIDList[pidLength - (A_Index - 1)]
                if (!ProcessExist(pid) || !WinExist("ahk_pid " pid)) {
                    continue
                }
    
                exe := WinGetProcessName("ahk_pid " pid)
                if (exe = "") {
                    continue
                }
    
                ; don't use WinGetList for background apps -> too many windows
                if (this.background) {
                    if (WinExist("ahk_pid " pid)) {
                        winList.Push(WinGetID("ahk_pid " pid))
                    }
                }
                else {
                    for item in WinGetList("ahk_pid " pid) {
                        if (WinGetProcessName(item) = exe) {
                            tempWinList.Push(item)
    
                            if (WinActivatable(item)) {
                                winList.Push(item)
                            }
                        }
                    }
                }
            }
        }
            
        ; use tempWinList as a less restrictive backup if window styles are weird
        if (winList.Length = 0) {
            winList := tempWinList
        }

        DetectHiddenWindows(restoreDHW)
        return winList
    }

    ; get program main window name
    getWNDW() {
        return this._getWNDW()
    }
    _getWNDW() {
        try {               
            winList := this._getHWNDList()
            if (winList.Length > 0) {
                return WinGetTitle(winList[1])
            }
        }
        
        return ""
    }

    ; update the volume value of the program
    checkVolume() {
        volumeInterface := this._getVolumeInterfacePtrs()
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
        volumeInterface := this._getVolumeInterfacePtrs()
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
        volumeInterface := this._getVolumeInterfacePtrs()
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
    _getVolumeInterfacePtrs() {
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
            if (sessionPID = 0) {
                continue
            }
            
            processPtr := DllCall("OpenProcess", "UInt", 0x0010 | 0x0400, "UInt", 0, "UInt", sessionPID, "UPtr")
            processName := ""

            size := 4096
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
            if (sessionPID = this.getPID() || processName = this.getEXE()) {
                interfacePtrs.Push(ComObjQuery(sessionInterface.Ptr, isav).Ptr)
            }
        }

        return interfacePtrs
    }
}

; takes a variable amount of exe maps (key=exe) and returns the process exe if its running
;  exe - either an exe or a map with each key being an exe
;  retName - return name rather than boolean
;  requireShown - whether the exe needs to be shown to be valid
;
; return either "" if the process is not running, or the name of the process
checkRunningEXEs(exe, retName := false, requireShown := false) {
    if (exe = "") {
        return (retName) ? "" : false
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

            if (processName != "" && exe.Has(StrLower(processName)) && (!requireShown || (requireShown && WinShown("ahk_exe " processName)))) {
                return (retName) ? processName : true
            }
        }
    }
    else if (ProcessExist(exe) && (!requireShown || (requireShown && WinShown("ahk_exe " exe)))) {
        return (retName) ? exe : true
    }

    return (retName) ? "" : false
}

; takes a variable amount of dirs (array) to check if any exe within the dir is running
;  dir - either an dir or an array with each item being a dir
;  retName - return name of exe rather than boolean
;  ignoreEXE - either an exe or array of exes to ignore
;  requireShown - whether the exe needs to be shown to be valid
;
; return either "" if the process is not running, or the name of the process
checkRunningDIRs(dir, retName := false, ignoreEXE := "", requireShown := false) {
    global wmiCOM
    global mainPID
    
    maintainerPID := WinHidden(MAINLOOP) ? WinGetPID(WinHidden(MAINLOOP)) : 0

    if (dir = "") {
        return (retName) ? "" : false
    }

    dirArr := []
    ; clean directory strings for sql cmd
    if (!IsObject(dir)) {
        dirArr.Push(StrReplace(StrReplace(dir, "\", "\\"), "'", "\'"))
    }
    else {
        for currDir in dir {
            dirArr.Push(StrReplace(StrReplace(currDir, "\", "\\"), "'", "\'"))
        }
    }

    ignoreStr := ""
    if (IsObject(ignoreEXE)) {
        for exe in ignoreEXE {
            ignoreStr .= StrLower(exe) . "|"
        }
    }
    else if (ignoreEXE != "") {
        ignoreStr := StrLower(ignoreEXE) . "|"
    }

    ; check if any programs exist where dir is subset of exe path 
    query := joinArray(dirArr, "%' OR ExecutablePath Like '%")
    for process in wmiCOM.ExecQuery("Select ExecutablePath from Win32_Process Where ExecutablePath Like '%" . query . "%'") {
        processPath := process.ExecutablePath
        processPathArr := StrSplit(processPath, "\")

        if (processPathArr.Length > 0) {
            processName := processPathArr[processPathArr.Length]
            if (processName = "" || InStr(ignoreStr, StrLower(processName) . "|")) {
                continue
            }

            processPID := ProcessExist(processName)
            if ((!requireShown || (requireShown && WinShown("ahk_exe " processName)))
                && processPID != mainPID && processPID != maintainerPID) {

                return (retName) ? processName : true
            }
        }
    }

    return (retName) ? "" : false
}

; takes a variable of window maps (key=window) and returns true if any of the functions return
;  wndw - either an wndw name or a map with each key being an wndw
;  retName - return name rather than boolean
;  requireShown - if false -> checking hidden windows
;
; return either "" if the process is not running, or the name of the process
checkRunningWNDWs(wndw, retName := false, requireShown := false) {
    if (wndw = "") {
        return (retName) ? "" : false
    }

    restoreDHW := A_DetectHiddenWindows
    DetectHiddenWindows(!requireShown)

    retVal := ""
    if (IsObject(wndw)) {
        for key, empty in wndw {
            if (WinExist(key)) {
                retVal := key
                break
            }
        }
	}
    else if (WinExist(wndw)) {
        retVal := wndw
    }

    DetectHiddenWindows(restoreDHW)

    return (retName) ? retVal : (retVal != "")
}

; merges extension data with the main config of the program if extension matches
;  programConfig - base config of the program
;  argString - arguments that the program was ran with
;
; returns appropriate config for program
getExtendedProgramConfig(programConfig, argString) {
    internalConfig := ObjDeepClone(programConfig)
    if (!programConfig.Has("_extensions")) {
        return internalConfig
    }

    for item in internalConfig["_extensions"] {
        argCheck := ""
        if (item["extends"].Has("arg")) {
            argCheck := item["extends"]["arg"]
        }
        else if (item["extends"].Has("args")) {
            argCheck := item["extends"]["args"]
        }

        if (argCheck = "") {
            continue
        }
        
        matchType := (item["extends"].Has("matchType")) ? StrLower(Trim(item["extends"]["matchType"])) : "full"
        matchResult := false
        if (!IsObject(argCheck)) {
            switch (matchType) {
                case "full":
                    matchResult := (StrLower(Trim(argString)) = StrLower(argCheck))
                case "partial":
                    matchResult := InStr(StrLower(argString), StrLower(argCheck))
                case "start":
                    matchResult := SubStr(StrLower(Trim(argString)), 1, StrLen(argCheck)) = StrLower(argCheck)
                case "end":
                    matchResult := SubStr(StrLower(Trim(argString)), -StrLen(argCheck)) = StrLower(argCheck)
            }
        } else {
            multiType := (item["extends"].Has("multiType")) ? StrLower(Trim(item["extends"]["multiType"])) : "and"
            multiResult := (multiType = "and") ? true : false
            for arg in argCheck {
                currSolution := false
                switch (matchType) {
                    case "full":
                        currSolution := (StrLower(Trim(argString)) = StrLower(arg))
                    case "partial":
                        currSolution := InStr(StrLower(argString), StrLower(arg))
                    case "start":
                        currSolution := SubStr(StrLower(Trim(argString)), 1, StrLen(arg)) = StrLower(arg)
                    case "end":
                        currSolution := SubStr(StrLower(Trim(argString)), -StrLen(arg)) = StrLower(arg)
                }

                if (multiType = "and") {
                    multiResult := multiResult && currSolution
                }
                else if (multiType = "or") {
                    multiResult := multiResult || currSolution
                }
            }

            matchResult := multiResult
        }

        if (matchResult) {
            for key, value in item {
                internalConfig[key] := value
            }

            return internalConfig
        }
    }

    return internalConfig
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

    programParams := []
    if (IsObject(params)) {
        programParams := params
    }
    else {
        programParams := StrSplitIgnoreQuotes(params)
    }

    newID := programParams.RemoveAt(1)
    
    for key, value in globalPrograms {
        ; find program config from id
        if (StrLower(key) != StrLower(newID)) {
            continue
        }

        ; if config missing required values
        if (!value.Has("id") || !value.Has("name")) {
            ErrorMsg("Tried to create program " . newID . "missing required fields id/name", true)
            return
        }

        ; check if program or program w/ same name exists
        for key2, value2 in globalRunning {
            if ((key = key2 || value["name"] = value2.name) && value2.exists()) {
                ; just set the running program as current
                if (setCurrent) {
                    setCurrentProgram(key2)
                }

                resetLoadScreen()
                return
            }
        }
        
        programConfig := getExtendedProgramConfig(value, joinArray(programParams)) 

        ; create program class if has custom class
        if (programConfig.Has("className")) {
            globalRunning[newID] := %programConfig["className"]%(programConfig)
            writeLog(newID . " created (class: " . programConfig["className"] . ")", "PROGRAM")
        }
        ; create generic program
        else {
            globalRunning[newID] := Program(programConfig)   
            writeLog(newID . " created (class: Program)", "PROGRAM")
        }

        ; set new program as current
        if (setCurrent) {
            setCurrentProgram(newID)
        }

        ; launch new program
        if (launchProgram) {
            globalRunning[newID].launch(programParams*)
        }

        ; set attributes of program (basically only done from backup.bin)
        if (customAttributes != "") {                
            for key, value in customAttributes {
                globalRunning[newID].%key% := value
            }
        }
    
        return
    }

    ErrorMsg("Program " . newID . " was not found")
}

; runs/restores the default program
;
; returns null
createDefaultProgram() {
    global globalConfig
    global globalRunning

    if (globalConfig["Plugins"].Has("DefaultProgram") && globalConfig["Plugins"]["DefaultProgram"] != "") {
        defaultProgram := globalConfig["Plugins"]["DefaultProgram"]

        if (globalRunning.Has(defaultProgram)) {
            setCurrentProgram(defaultProgram)
        }
        else {
            createProgram(defaultProgram)
        }
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

; sets the requested id as the current program if it exists
;  id - id of program to set as current
;
; returns null
setCurrentProgram(id) {
    global globalStatus
    global globalRunning

    if (!globalRunning.Has(id) || globalRunning[id].background) {
        ErrorMsg("Requested current program doesn't exist / is background")
        return
    }

    currProgram   := globalStatus["currProgram"]["id"]
    currSuspended := globalStatus["suspendScript"] || globalStatus["desktopmode"]
    
    if (currProgram != id) {
        if (globalStatus["kbmmode"]) {
            disableKBMMode()
        }
        else if (keyboardExists()) {
            closeKeyboard()
        }

        ; get new thumbnail
        if (currProgram != "" && globalRunning.Has(currProgram) && WinActive(globalRunning[currProgram].getHWND())) {
            saveScreenshot(currProgram, globalRunning[currProgram].monitorNum)
        }

        writeLog(id . " set as current program", "PROGRAM")

        globalStatus["currProgram"]["id"] := id
        globalStatus["currProgram"]["exe"] := ""
        globalStatus["currProgram"]["hwnd"] := 0
        globalRunning[id].time := A_TickCount

        if (!currSuspended) {
            setLoadScreen()
            activateLoadScreen()
            HideMouseCursor()
            
            Sleep(200)
            resetLoadScreen()
        }
    }

    if (globalRunning[id].exists(true) && !currSuspended) {
        globalRunning[id].fullscreened := false
        globalRunning[id]._waitingFullscreenTimer := false
        globalRunning[id]._overrideFullscreenDelay := 1000
        globalRunning[id].restore()
    }
}

; resets the current program
;
; returns null
resetCurrentProgram() {
    global globalStatus

    globalStatus["currProgram"]["id"] := ""
    globalStatus["currProgram"]["exe"] := ""
    globalStatus["currProgram"]["hwnd"] := 0
}

; checks that the program exists
;  programConfig - config from program to check 
;
; returns [program exists, console name if console else ""]
checkProgramExists(programConfig) {
    global globalConsoles

    ; create program class if has custom class
    try {
        if (programConfig.Has("className")) {
            return [%programConfig["className"]%(programConfig).getEXE() != "", ""]
        }
        ; create generic program
        else {
            return [Program(programConfig).getEXE() != "", ""]
        }
    }
    ; if fails - assume its a console
    catch {
        for key, value in globalConsoles {
            if (inArray(programConfig["id"], value["emulators"])) {
                if (programConfig.Has("className")) {
                    return [%programConfig["className"]%(key, programConfig, value).getEXE() != "", key]
                }
                ; create generic emulator
                else {
                    return [Emulator(key, programConfig, value).getEXE() != "", key]
                }
            }
        }
    }

    return [false, ""]
}

; checks & updates the running list of programs
; launches missing background programs
;
; returns null
checkAllPrograms() {
    global globalConfig
    global globalStatus
    global globalRunning
    global globalPrograms
    global globalConsoles

    runningKeys := []
    for key, value in globalPrograms {
        if (globalRunning.Has(key)) {
            runningKeys.Push(key)
            continue
        }

        if (value.Has("_extensions")) {
            for item in value["_extensions"] {
                ; check each extension individually if it has unique program indentifiers
                if (item.Has("exe") || item.Has("dir") || item.Has("wndw") || item.Has("className")) {
                    tempValue := ObjDeepClone(value)
                    for key2, value2 in item {
                        tempValue[key2] := value2
                    }

                    checkArr := checkProgramExists(tempValue)
                    if (checkArr[1]) {
                        if (checkArr[2] != "") {
                            createConsole([checkArr[2], ""], false, false)
                        }
                        else {
                            createProgram(key, false, false)
                        }
                    }   
                }
            }
        }

        checkArr := checkProgramExists(value)
        if (checkArr[1]) {
            if (checkArr[2] != "") {
                createConsole([checkArr[2], ""], false, false)
            }
            else {
                writeLog(key . " was detected as already running")
                createProgram(key, false, false)
            }
        }
    }

    currSuspended   := globalStatus["suspendScript"]
    currDesktopMode := globalStatus["desktopmode"]

    activeProgram := false
    for key in runningKeys {
        if (!globalRunning.Has(key)) {
            continue
        }

        ; yes this actually needs a try
        try {
            if (!globalRunning[key].exists()) {
                if (!currSuspended && !currDesktopMode) {
                    try globalRunning[key].postExit()
                }
    
                writeLog(key . " deleted", "PROGRAM")
                globalRunning.Delete(key)
            }
            else if (!globalRunning[key].background) {
                activeProgram := true
            }
        }
    }

    if (!activeProgram && !currSuspended && !currDesktopMode
        && globalConfig["Plugins"].Has("DefaultProgram") && globalConfig["Plugins"]["DefaultProgram"] != "") {
        
        if (!globalPrograms.Has(globalConfig["Plugins"]["DefaultProgram"])) {
            ErrorMsg("Default Program" . globalConfig["Plugins"]["DefaultProgram"] . " has no config", true)
        }

        createProgram(globalConfig["Plugins"]["DefaultProgram"])
    }
}

; updates the global running list & the current program
;
; returns null
updatePrograms() {
    global globalStatus

    currProgram := globalStatus["currProgram"]["id"]

    checkAllPrograms()

    mostRecentProgram := getMostRecentProgram()
    if (mostRecentProgram = "") {
        resetCurrentProgram()
    }
    else if (mostRecentProgram != currProgram) {
        setCurrentProgram(mostRecentProgram)
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

        globalRunning[name].exit(false)
        Sleep(250)

        if (globalRunning[name].exists()) {
            ProcessKill(globalRunning[name].getPID())
        }

        try globalRunning[name].postExit()
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
		if (programID != "" && (!globalRunning.Has(programID) || globalRunning[programID].shouldExit)) {
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

			DllCall("Ws2_32\WSAAddressToStringW", "Ptr", addr, "UInt", addrLen, "Ptr", 0, "Ptr", wsaData.Ptr, "UInt*", 204)
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