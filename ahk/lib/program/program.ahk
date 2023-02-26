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

    muted              := false
    background         := false
    minimized          := false
    fullscreened       := false
    paused             := false
    
    defaultArgs       := ""
    allowQuickAccess  := false
    allowHungCheck    := true
    allowPause        := true
    allowExit         := true
    shouldExit        := false
    requireInternet   := false
    requireFullscreen := false

    pauseOrder    := []
    pauseOptions  := Map()

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
    _checkPropertiesDelay := 3000
    _postLaunchDelay      := 1000
    _fullscreenDelay      := 2500
    _mouseMoveDelay       := 3000

    ; if waiting on check of program relaunching
    _waitingExistTimer      := false
    _waitingHungTimer       := false
    _waitingPostLaunchTimer := false
    _waitingFullscreenTimer := false
    _waitingMouseMoveTimer  := false

    _restoreMousePos := []
    _restoreWNDWs := []

    ; used when exe/wndw are lists - keep current active
    _currEXE  := ""
    _currHWND := 0

    __New(exeConfigRef) {
        exeConfig := ObjDeepClone(exeConfigRef)

        this.id   := exeConfig["id"]

        ; set basic attributes
        this.name     := (exeConfig.Has("name"))     ? exeConfig["name"]             : this.name
        this.dir      := (exeConfig.Has("dir"))      ? validateDir(exeConfig["dir"]) : this.dir
        this.exe      := (exeConfig.Has("exe"))      ? exeConfig["exe"]              : this.exe
        this.wndw     := (exeConfig.Has("wndw"))     ? exeConfig["wndw"]             : this.wndw
        this.priority := (exeConfig.Has("priority")) ? exeConfig["priority"]         : this.priority

        this.time := A_TickCount
        
        this.background         := (exeConfig.Has("background"))         ? exeConfig["background"]         : this.background
        this.defaultArgs        := (exeConfig.Has("defaultArgs"))        ? exeConfig["defaultArgs"]        : this.defaultArgs
        this.allowPause         := (exeConfig.Has("allowPause"))         ? exeConfig["allowPause"]         : this.allowPause
        this.allowExit          := (exeConfig.Has("allowExit"))          ? exeConfig["allowExit"]          : this.allowExit
        this.allowQuickAccess   := (exeConfig.Has("allowQuickAccess"))   ? exeConfig["allowQuickAccess"]   : this.allowQuickAccess
        this.allowHungCheck     := (exeConfig.Has("allowHungCheck"))     ? exeConfig["allowHungCheck"]     : this.allowHungCheck
        this.requireInternet    := (exeConfig.Has("requireInternet"))    ? exeConfig["requireInternet"]    : this.requireInternet
        this.requireFullscreen  := (exeConfig.Has("requireFullscreen"))  ? exeConfig["requireFullscreen"]  : this.requireFullscreen

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
    }

    ; runs the program
    ;  args - args to run the program with
    ;
    ; returns null
    launch(args*) {
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

        retArgs := []
        if (Type(this.defaultArgs) = "Array") {
            for item in this.defaultArgs {
                if (InStr(item, A_Space) && (!(SubStr(item, 1, 1) = '"' && SubStr(item, -1, 1) = '"')
                    || !(SubStr(item, 1, 1) = "'" && SubStr(item, -1, 1) = "'"))) {

                    retArgs.Push('"' . item . '"')
                }
                else {
                    retArgs.Push(item)
                }
            }
        }
        else if (this.defaultArgs != "") {
            argArr := StrSplitIgnoreQuotes(this.defaultArgs)
            if (argArr.Length > 0) {
                retArgs.Push(argArr*)
            }
        }

        if (Type(args) = "Array") {
            for item in args {
                if (InStr(item, A_Space) && (!(SubStr(item, 1, 1) = '"' && SubStr(item, -1, 1) = '"')
                    || !(SubStr(item, 1, 1) = "'" && SubStr(item, -1, 1) = "'"))) {

                    retArgs.Push('"' . item . '"')
                }
                else {
                    retArgs.Push(item)
                }
            }
        }
        else {
            argArr := StrSplitIgnoreQuotes(args)
            if (argArr.Length > 0) {
                retArgs.Push(argArr*)
            }
        }

        ; if launch returns false -> assume failed
        if (this._launch(retArgs*) = false) {
            Critical(restoreCritical)
            resetLoadScreen()
            return
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
            SetTimer(DelayCheckProperties, Neg(this._checkPropertiesDelay))
        }

        this.shouldExit := false

        this.allowExit := restoreAllowExit
        this.hotkeys   := restoreHotkeys

        Critical(restoreCritical)
        resetLoadScreen()
        return

        ; saves screenshot & updates program data
        DelayCheckProperties() {
            global globalStatus

            if (!this.exists(true) || globalStatus["currProgram"] != this.id) {
                return
            }

            ; wait for program to get focused
            hwnd := this.getHWND()
            if (this.hungCount > 0 || hwnd = 0 || !WinActive(hwnd)) {
                SetTimer(CheckPropertiesTimer, 500)
                return
            }

            if (this.priority != "") {
                ProcessSetPriority(this.priority, this.getPID())
            }

            this.checkFullscreen()
            saveScreenshot(this.id)

            return
        }

        ; if delay launch fials 
        CheckPropertiesTimer() {
            global globalStatus

            if (!this.exists(true) || globalStatus["currProgram"] != this.id) {
                SetTimer(CheckPropertiesTimer, 0)
                return
            }

            ; wait for program to get focused
            hwnd := this.getHWND()
            if (this.hungCount > 0 || hwnd = 0 || !WinActive(hwnd)) {
                return
            }

            if (this.priority != "") {
                ProcessSetPriority(this.priority, this.getPID())
            }

            this.checkFullscreen()
            saveScreenshot(this.id)

            SetTimer(CheckPropertiesTimer, 0)
            return
        }
    }
    _launch(args*) {
        ; run dir\exe
        if (!IsObject(this.exe) && this.exe != "") {
            Run this.dir . this.exe . A_Space . joinArray(args), this.dir, ((this.background) ? "Hide" : "Max")
        }
        ; fail
        else {
            ErrorMsg(this.name . "does not have an exe defined, it cannot be launched with default settings")
            return false
        }
    }

    ; designed to be overwritten -> runs after first successful restore
    postLaunch() {
        this._postLaunch()
    }
    _postLaunch() {
        return
    }

    ; activates the program's window
    restore() {
        if (this.hungCount > 0) {
            return
        }

        if (this.minimized) {
            if (this._restoreWNDWs.Length > 0) {
                loop this._restoreWNDWs.Length {
                    index := (this._restoreWNDWs.Length + 1) - A_Index

                    if (WinShown(this._restoreWNDWs[index])) {
                        WinActivate(this._restoreWNDWs[index])
                    }

                    if (A_Index < this._restoreWNDWs.Length) {
                        Sleep(200)
                    }
                }

                this._restoreWNDWs := []
            }
            
            this.minimized := false
        }

        this._restore()
        this.resume()

        ; after first restore -> perform post launch action
        if (!this._waitingPostLaunchTimer) {
            SetTimer(DelayPostLaunch, Neg(this._postLaunchDelay))
            this._waitingPostLaunchTimer := true
        }

        ; after first restore -> fullscreen window if required
        if (this.requireFullscreen && !this._waitingFullscreenTimer) {
            SetTimer(DelayFullscreen, Neg(this._fullscreenDelay))
            this._waitingFullscreenTimer := true
        }

        ; after first restore -> move mouse to proper position
        if (!this._waitingMouseMoveTimer) {
            ; hide mouse
            x := percentWidth(1, false)
            y := percentHeight(1, false)
            if (this.mouse.Has("initialPos")) {
                x := percentWidth(this.mouse["initialPos"][1], false)
                y := percentHeight(this.mouse["initialPos"][2], false)
            }

            if (this._mouseMoveDelay != 0) {
                SetTimer(DelayMouseMove.Bind(x, y), Neg(this._mouseMoveDelay))
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

            hwnd := this.getHWND()
            if (hwnd = 0 || !WinActive(hwnd) || globalStatus["currProgram"] != this.id) {
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

            hwnd := this.getHWND()
            if (hwnd = 0 || !WinActive(hwnd) || globalStatus["currProgram"] != this.id) {
                this._waitingFullscreenTimer := false
                return
            }

            if (!this.checkFullscreen()) {
                this.fullscreen()

                ; if fullscreen failed, try again
                if (!this.fullscreened) {
                    this._waitingFullscreenTimer := false
                }
            }

            return
        }

        ; move mouse to x, y position
        DelayMouseMove(x, y) {
            global globalStatus

            if (!this.exists() || this._restoreMousePos.Length = 2) {
                return
            }

            hwnd := this.getHWND()
            if (hwnd = 0 || !WinActive(hwnd) || globalStatus["currProgram"] != this.id) {
                this._waitingMouseMoveTimer := false
                return
            }
            
            MouseMove(x, y)
            return
        }
    }
    _restore() {
        global globalStatus

        hwnd := (this._currHWND != 0) ? this._currHWND : this.getHWND()
        if (!WinShown(hwnd)) {
            return
        }
        
        try {
            ; if window should not be fullscreen, try to maximize parent
            if (!this.fullscreened && !this.requireFullscreen) {
                parentHWND := WinGetParent(hwnd)
                if (WinGetMinMax(parentHWND) != 1) {
                    WinMaximize(parentHWND)
                }
            }

            ; try to activate window
            if (!WinActive(hwnd)) {
                WinActivate(hwnd)
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

        this.minimized := true

        ; reset fullscreen status on minimize
        this.fullscreened := false
        this._waitingFullscreenTimer := false
        this._waitingMouseMoveTimer  := false

        ; get new thumbnail
        if (this.id = globalStatus["currProgram"]) {
            saveScreenshot(this.id)
        }

        this._minimize()

        Critical(restoreCritical)
    }
    _minimize() {
        this._restoreWNDWs := []
        hwndList := this.getHWNDList()

        loop hwndList.Length {
            WinMinimize(hwndList[A_Index])
            this._restoreWNDWs.Push(hwndList[A_Index])

            if (A_Index < hwndList.Length) {
                Sleep(200)
            }
        }
    }

    ; fullscreen window if not fullscreened
    fullscreen() {
        global globalStatus

        if (this.hungCount > 0) {
            return
        }
        
        restoreCritical := A_IsCritical
        Critical("On")

        this._fullscreen()

        Critical(restoreCritical)

        Sleep(50)
        this.checkFullscreen()
    }
    _fullscreen() {
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

        validWidths  := [MONITOR_W, 21, 16, 4]
        validHeights := [MONITOR_H,  9,  9, 3]

        minDiff := 69
        aspectIndex := 1
        loop validWidths.Length {
            currDiff := Abs((W / H) - (validWidths[A_Index] / validHeights[A_Index]))

            if (currDiff < minDiff) {
                minDiff := currDiff
                aspectIndex := A_Index
            }
        }

        multiplier := Min(MONITOR_W / validWidths[aspectIndex], MONITOR_H / validHeights[aspectIndex])
        newW := validWidths[aspectIndex]  * multiplier
        newH := validHeights[aspectIndex] * multiplier

        WinMove(MONITOR_X + ((MONITOR_W - newW) / 2), MONITOR_Y + ((MONITOR_H - newH) / 2), newW, newH, hwnd)
    }

    ; return if program is "fullscreen" & update the fullscreen value of the program
    checkFullscreen() {
        if (this.hungCount > 0) {
            return
        }

        this.fullscreened := this._checkFullscreen()
        return this.fullscreened
    }
    _checkFullscreen() {
        hwnd := this.getHWND()

        try {
            WinGetClientPos(,, &W, &H, hwnd)
            return (!(WinGetStyle(hwnd) & 0x20800000) && W >= MONITOR_W && H >= MONITOR_H) ? true : false
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
        if (this._currEXE != "") {
            if (requireShown) {
                existed := (WinShown("ahk_exe " this._currEXE)) ? true : false
            }
            else {
                existed := true
            }
        }
       
        this._currEXE  := this.getEXE()
        this._currHWND := this.getHWND()

        existing := this._exists(requireShown)
        ; if not existing and existed, and if multiple exe/wndw, wait and check for new window
        if (existed && !existing && !this._waitingExistTimer && (IsObject(this.exe) || IsObject(this.wndw))) {
            SetTimer(DelayCheckExists, -1500)
            this._waitingExistTimer := true

            return true
        }

        if (!this.paused && this.allowHungCheck && checkHung) {
            ; check if wndw hung 
            if (existing && !this.checkResponding()) {
                if (this.hungCount = 0) {
                    SetTimer(CheckHungTimer, -1000)
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
        DelayCheckExists() {
            this._currEXE  := this.getEXE()
            this._currHWND := this.getHWND()
            
            this._waitingExistTimer := false
            return
        }

        ; repeated check while program is hung
        CheckHungTimer() {
            global globalGuis

            ; if exists & hung
            if (!this.paused && ProcessExist(this.getPID()) && !this.checkResponding()) {               
                if (this.hungCount > this.maxHungCount) {
                    ; create "wait for program" gui dialog
                    if (!this._waitingHungTimer) {
                        createInterface("choice",,, this.name " has stopped responding", "Wait",,, "Exit", "ProcessKill " . this.getPID(), "FF0000")
                        this._waitingHungTimer := true
                    }
                    ; reset hung count if gui dialog doesn't exist
                    else if (!globalGuis.Has("choice")) {
                        this.hungCount := 0
                        this._waitingHungTimer := false
                    }
                }

                this.hungCount += 1
                SetTimer(CheckHungTimer, -1000)
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
        if (this._currEXE = "") {
            return false
        }

        if (requireShown) {
            return (WinShown("ahk_exe " this._currEXE)) ? true : false
        }

        return true
    }

    ; exit program 
    exit() {
        global globalStatus

        ; disable hotkeys
        this.hotkeys := Map()
        this.shouldExit := true
        
        setLoadScreen("Exiting " . this.name . "...")

        restoreCritical := A_IsCritical
        Critical("On")

        this._exit()

        Sleep(500)
        resetLoadScreen()

        Critical(restoreCritical)
        return
    }
    _exit() {
        try {
            count := 0
            maxCount := 250
            ; wait for program executable to close
            while (this.exists() && count < maxCount) {
                exe := this.getEXE()
                if (exe = "") {
                    break
                }

                ; attempt to winclose right away
                if (count = 0) {
                    if (this.hungCount = 0) {
                        WinCloseAll("ahk_exe " exe)
                    }
                    else {
                        ProcessKill(this.getPID())
                    }
                }
                ; attempt to winclose again @ 10s
                else if (count = 100) {
                    ; if program is hanging, kill it
                    if (this.hungCount = 0) {
                        WinCloseAll("ahk_exe " exe)
                    }
                    else {
                        ProcessKill(this.getPID())
                    }
                }
                ; attempt to processclose @ 20s
                else if (count = 200) {
                    ProcessClose(exe)
                }
                
                count += 1
                Sleep(100)
            }

            ; if exists -> go nuclear @ 25s
            if (this.exists()) {
                ProcessKill(this.getPID())
            }
        }
    }

    ; run custom post exit function
    postExit() {
        this._postExit()
    }
    _postExit() {
        return
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
            this._restoreMousePos := [x, y]
        }

        saveScreenshot(this.id)

        this._pause()
        
        Critical(restoreCritical)
        return
    }
    _pause() {
        return
    }

    ; runs custom resume function after pause close
    resume() {
        if (!this.paused) {
            return
        }
        
        restoreCritical := A_IsCritical
        Critical("On")
        
        this.paused := false
        
        if (this._restoreMousePos.Length = 2) {
            MouseMove(this._restoreMousePos[1], this._restoreMousePos[2])
        }

        this._resume()

        Critical(restoreCritical)
        return
    }
    _resume() {
        return
    }
    

    ; get program exe name
    getEXE() {
        return this._getEXE()
    }
    _getEXE() {
        try {
            ; check current exe
            if (this._currEXE != "" && ProcessExist(this._currEXE)) {
                return this._currEXE
            }
            
            ; check all exes
            if (this.exe != "") {
                return checkEXE(this.exe, true)
            }
    
            ; check current wndw for exe name
            hwnd := this.getHWND()
            if (hwnd != "") {
                return WinGetProcessName(hwnd)
            }
        }
        
        return ""
    }
    
    ; get program pid
    getPID() {
        return this._getPID()
    }
    _getPID() {
        exe := this.getEXE()
        if (exe != "") {
            return ProcessExist(exe)
        }

        return 0
    }

    ; get program window hwnd
    getHWND() {
        return this._getHWND()
    }
    _getHWND() {  
        try {
            if (this.wndw != "") {
                restoreDHW := A_DetectHiddenWindows
                DetectHiddenWindows(this.background)

                retVal := 0

                ; check current wndw
                if (this._currHWND != 0 && WinExist(this._currHWND)) {    
                    retVal := this._currHWND
                }
                else {
                    currWNDW := checkWNDW(this.wndw, true, this.background)
                    if (currWNDW != "") {
                        retVal := WinGetID(currWNDW)
                    }
                }

                DetectHiddenWindows(restoreDHW)
                if (retVal != 0) {
                    return retVal
                }
            }

            hwndList := this.getHWNDList()
            if (hwndList.Length > 0) {
                return hwndList[1]
            }
        }      
        
        return 0
    }

    ; get program all windows ids
    getHWNDList() {
        return this._getHWNDList()
    }
    _getHWNDList() {
        try {
            exe := this.getEXE()
            if (exe = "") {
                return []
            }
    
            restoreDHW := A_DetectHiddenWindows
            DetectHiddenWindows(this.background)
    
            winList := []
            for item in WinGetList("ahk_exe " exe) {
                if ((this.background || (!this.background && WinActivatable(item)))
                    && WinGetProcessName(item) = exe) {
    
                    winList.Push(item)
                }
            }
    
            DetectHiddenWindows(restoreDHW)
    
            return winList
        }
        
        return []
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
            
            exeNameBuff := Buffer(512, 0)
            processPtr := DllCall("OpenProcess", "UInt", 0x1000, "UInt", 0, "UInt", sessionPID, "UPtr")
            DllCall("QueryFullProcessImageName", "UPtr", processPtr, "UInt", 0, "Str", exeNameBuff.Ptr, "UInt*", 512, "UInt")
            DllCall("CloseHandle", "UPtr", processPtr, "UInt")
            
            exeNameArr := StrSplit(StrGet(exeNameBuff), "\")
            if (sessionPID != 0 && (sessionPID = this.getPID() || (exeNameArr.Length > 0 && exeNameArr[exeNameArr.Length] = this.getEXE()))) {
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

            if (processName != "" && exe.Has(StrLower(processName))) {
                return (retName) ? processName : true
            }
        }
    }
    else if (ProcessExist(exe)) {
        return (retName) ? exe : true
    }

    return (retName) ? "" : false
}

; takes a variable of window maps (key=window) and returns true if any of the functions return
;  wndw - either an wndw name or a map with each key being an wndw
;  retName - return name rather than boolean
;  hidden - enables checking hidden windows
;
; return either "" if the process is not running, or the name of the process
checkWNDW(wndw, retName := false, hidden := false) {
    if (wndw = "") {
        return (retName) ? "" : false
    }

    restoreDHW := A_DetectHiddenWindows
    DetectHiddenWindows(hidden)

    retVal := ""
    if (IsObject(wndw)) {
        for key, empty in wndw {
            ; if not hidden -> check for a valid interactable wndw
            if (WinExist(key) && (hidden || (!hidden && WinActivatable(key)))) {
                retVal := key
                break
            }
        }
	}
    else if (WinExist(wndw) && (hidden || (!hidden && WinActivatable(wndw)))) {
        retVal := wndw
    }

    DetectHiddenWindows(restoreDHW)

    return (retName) ? retVal : (retVal != "")
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
            if (key = key2 || value["name"] = value2.name) {
                ; just set the running program as current
                if (setCurrent || launchProgram) {
                    setCurrentProgram(key2)
                }

                resetLoadScreen()
                return
            }
        }
        
        programConfig := ObjDeepClone(value) 
        paramString := joinArray(programParams)

        ; replace config options specified in the overrides
        if (paramString != "" && programConfig.Has("overrides") && Type(programConfig["overrides"]) = "Map") {  
            for key2, value2 in programConfig["overrides"] {
                if (key2 = "" || !RegExMatch(paramString, "U)" . key2)) {
                    continue
                }

                ; replace config fields w/ override
                if (IsObject(value2)) {
                    for key3, value3 in value2 {
                        programConfig[key3] := value3
                    }
                }
                ; assume className is replaced
                else {
                    programConfig["className"] := value2
                }

                break
            }
        }

        ; create program class if has custom class
        if (programConfig.Has("className")) {
            globalRunning[newID] := %programConfig["className"]%(programConfig)
        }
        ; create generic program
        else {
            globalRunning[newID] := Program(programConfig)   
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
    
    if (globalStatus["currProgram"] != id) {
        if (globalStatus["kbmmode"]) {
            disableKBMMode()
        }
        else if (keyboardExists()) {
            closeKeyboard()
        }

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

    runningKeys := []
    for key, value in globalPrograms {
        if (globalRunning.Has(key)) {
            runningKeys.Push(key)
            continue
        }

        if ((value.Has("exe") && checkEXE(value["exe"])) || (value.Has("wndw") && checkWNDW(value["wndw"]))) {
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

    activeProgram := false
    for key in runningKeys {
        if (!globalRunning[key].exists()) {
            globalRunning[key].postExit()
            globalRunning.Delete(key)
        }
        else if (!globalRunning[key].background) {
            activeProgram := true
        }
    }

    if (!activeProgram && globalConfig["Plugins"].Has("DefaultProgram") && globalConfig["Plugins"]["DefaultProgram"] != "") {
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