; creates an executable generic object that gets added to globalRunning
; this executable object will contain a lot of the generic features taken from executable json files
; each function & more in json files has default version as well
class Program {
    ; attributes
    id      := ""

    name    := ""
    dir     := ""
    exe     := ""
    wndw    := ""

    volume  := 0
    time    := 0

    ; number of seconds before determining a program not responding
    hungCount    := 0
    maxHungCount := 20

    muted            := false
    background       := false
    minimized        := false
    fullscreen       := false
    allowQuickAccess := false
    allowPause       := true

    pauseOrder   := []
    pauseOptions := Map()
    hotkeys      := Map()

    ; functions
    customLaunch := ""

    customPause  := ""
    customResume := ""

    customExit     := ""
    customRestore  := ""
    customMinimize := ""

    ; used when exe/wndw are lists - keep current active
    currEXE  := ""
    currWNDW := ""

    __New(exeConfig) {
        this.id   := exeConfig["id"]

        ; set basic attributes
        this.name := (exeConfig.Has("name")) ? exeConfig["name"] : this.name
        this.dir  := (exeConfig.Has("dir"))  ? exeConfig["dir"]  : this.dir
        this.exe  := (exeConfig.Has("exe"))  ? exeConfig["exe"]  : this.exe
        this.wndw := (exeConfig.Has("wndw")) ? exeConfig["wndw"] : this.wndw

        this.time := A_TickCount
        
        this.background := (exeConfig.Has("background")) ? exeConfig["background"] : this.background
        this.allowQuickAccess := (exeConfig.Has("allowQuickAccess")) ? exeConfig["allowQuickAccess"] : this.allowQuickAccess

        ; set custom functions
        this.customLaunch      := (exeConfig.Has("launch"))       ? exeConfig["launch"]       : this.customLaunch
  
        this.customPause       := (exeConfig.Has("pause"))        ? exeConfig["pause"]        : this.customPause
        this.customResume      := (exeConfig.Has("resume"))       ? exeConfig["resume"]       : this.customResume
  
        this.customExit        := (exeConfig.Has("exit"))         ? exeConfig["exit"]         : this.customExit
        this.customRestore     := (exeConfig.Has("restore"))      ? exeConfig["restore"]      : this.customRestore
        this.customMinimize    := (exeConfig.Has("minimize"))     ? exeConfig["minimize"]     : this.customMinimize

        this.hotkeys := (exeConfig.Has("hotkeys")) ? exeConfig["hotkeys"] : this.hotkeys

        this.allowPause := (exeConfig.Has("allowPause")) ? exeConfig["allowPause"] : this.allowPause

        ; set pause contents if appropriate
        if (this.allowPause) {
            this.pauseOptions := (exeConfig.Has("pauseOptions")) ? exeConfig["pauseOptions"]        : this.pauseOptions
            this.pauseOrder   := (exeConfig.Has("pauseOrder"))   ? toArray(exeConfig["pauseOrder"]) : this.pauseOrder
        }
    }

    launch(args) {
        ; TODO
        ; take args from externalMessage
        setLoadScreen("Waiting for " . this.name . "...")

        if (this.customLaunch != "") {
            runFunction(this.customLaunch, args)
        }
        else if (!IsObject(this.exe) && this.exe != "") {
            Run validateDir(this.dir) . this.exe . ((args != "" || (args && args.Length > 0)) ? joinArray(args) : ""), validateDir(this.dir), ((this.background) ? "Hide" : "Max")
        }
        else {
            ErrorMsg(this.name . "does not have an exe defined, it cannot be launched with default settings")
        }

        count := 0
        maxCount := 150

        while (!this.exists() && count < maxCount) {
            count += 1

            Sleep(150)
        }

        resetLoadScreen()
        SetTimer(CheckLaunch, -3000)

        CheckLaunch() {
            global globalGuis

            if (globalGuis.Count > 0) {
                SetTimer(WaitCheckGuis, 500)
                return
            }

            if (this.exists()) {
                this.isFullscreen()
                saveScreenshot(this.id)
            }

            return
        }

        WaitCheckGuis() {
            global globalGuis

            if (!this.exists()) {
                SetTimer(WaitCheckGuis, 0)
                return
            }

            if (globalGuis.Count = 0) {
                SetTimer(WaitCheckGuis, 0)

                this.isFullscreen()
                saveScreenshot(this.id)
            }

            return
        }
    }
    
    pause() {
        saveScreenshot(this.id)

        if (this.customPause != "") {
            runFunction(this.customPause)
            return
        }
    }

    resume() {
        if (this.customRestore != "") {
            runFunction(this.customRestore)
            return
        }
    }

    restore() {
        activeEXE  := (this.currEXE != "")  ? this.currEXE  : this.exe
        activeWNDW := (this.currWNDW != "") ? this.currWNDW : this.wndw

        window := (activeWNDW != "") ? activeWNDW : "ahk_exe " . activeEXE
        if (!WinHidden(window)) {
            return
        }

        WinWait(window)

        if (this.customRestore != "") {
            runFunction(this.customRestore)
            return
        }

        ; TODO - think about removing borders & making fullscreen
        ; for now just gonna restore & activate
        if (!WinActive(window) || WinGetMinMax(window) != 1) {
            maxCount := 150
            
            if (!this.fullscreen) {
                count := 0
                while (WinGetMinMax(window) = -1 && count < maxCount) {
                    try {
                        WinMaximize(window)
                    }
                    catch {
                        break
                    }

                    Sleep(100)
                    count += 1
                }

                WinMoveTop(window)
                Sleep(100)
            }
            
            count := 0
            while (!WinActive(window) && count < maxCount) {
                try {
                    WinActivate(window)
                }
                catch {
                    break
                }
                
                Sleep(100)
                count += 1
            }

            this.time := A_TickCount
            this.minimized := false
        }
    }

    minimize() {
        activeEXE  := (this.currEXE != "")  ? this.currEXE  : this.exe
        activeWNDW := (this.currWNDW != "") ? this.currWNDW : this.wndw

        this.minimized := true

        if (this.id = getStatusParam("currProgram")) {
            saveScreenshot(this.id)
        }

        if (this.customMinimize != "") {
            runFunction(this.customMinimize)
            return
        }

        window := (activeWNDW != "") ? activeWNDW : "ahk_exe " . activeEXE

        WinMinimize(window)
    }

    exit() {
        setLoadScreen("Exiting " . this.name . "...")

        ; TODO - think about if this.wndw -> don't wait for exe to close
        activeEXE  := (this.currEXE != "")  ? this.currEXE  : this.exe
        activeWNDW := (this.currWNDW != "") ? this.currWNDW : this.wndw

        if (this.customExit != "") {
            runFunction(this.customExit)
            resetLoadScreen()
            
            return
        }

        count := 0
        maxCount := 50

        window := (activeWNDW != "") ? activeWNDW : "ahk_exe " . activeEXE
        WinClose(window)

        exeExists := (activeEXE != "") ? ProcessExist(activeEXE) : WinHidden(window)
        while (exeExists && count < maxCount) {
            count += 1
            exeExists := (activeEXE != "") ? ProcessExist(activeEXE) : WinHidden(window)

            Sleep(150)
        }

        if (WinHidden(window)) {
            ProcessWinClose(window)
        }

        resetLoadScreen()
    }

    exists() {
        wndwStatus := false
        exeStatus := false

        ; check if wndw exists
        if (IsObject(this.wndw)) {
            if (this.currWNDW = "") {
                this.currWNDW := checkWNDW(this.wndw, true)
            }

            if (this.currWNDW != "") {
                wndwStatus := true

                if (!checkWNDW(this.currWNDW)) {
                    SetTimer(DelayCheckWNDW, -1000)
                }
            }
        }
        else {
            wndwStatus := checkWNDW(this.wndw)
        }

        ; check if exe exists
        if (!wndwStatus) {
            if (IsObject(this.exe)) {
                if (this.currEXE = "") {
                    this.currEXE := checkEXE(this.exe, true)
                }

                if (this.currEXE != "") {
                    exeStatus := true

                    if (!checkEXE(this.currEXE)) {
                        SetTimer(DelayCheckEXE, -1000)
                    }
                }
            }
            else {
                exeStatus := checkEXE(this.exe)
            }

        }

        ; check if wndw hung 
        if (!getGUI(GUICHOICETITLE)) {
            if ((exeStatus || wndwStatus) && this.hungCount = 0 && DllCall("IsHungAppWindow", "Ptr", this.getHWND())) {
                SetTimer(CheckHungTimer, 1000)
                CheckHungTimer()
            }
            else {
                hungCount := 0
            }
        }
        

        return exeStatus || wndwStatus

        DelayCheckEXE() {
            if (this.exe = "") {
                return
            }

            this.currEXE := checkEXE(this.exe, true)
            if (this.currEXE = "") {
                this.exe := ""
            }

            return
        }

        DelayCheckWNDW() {
            if (this.wndw = "") {
                return
            }

            this.currWNDW := checkWNDW(this.wndw, true)
            if (this.currWNDW = "") {
                this.wndw := ""
            }

            return
        }

        CheckHungTimer() {
            if (ProcessExist(this.getPID()) && DllCall("IsHungAppWindow", "Ptr", this.getHWND())) {
                this.hungCount += 1
                
                if (this.hungCount > this.maxHungCount) {
                    createChoiceDialog(this.name " has stopped responding", "Wait",,, "Exit", "ProcessKill " . this.getPID(), "FF0000")
                    
                    this.hungCount := 0
                    SetTimer(CheckHungTimer, 0)
                }
            }
            else {
                this.hungCount := 0
                SetTimer(CheckHungTimer, 0)
            }
            
            return
        }
    }

    isFullscreen() {
        activeEXE  := (this.currEXE != "")  ? this.currEXE  : this.exe
        activeWNDW := (this.currWNDW != "") ? this.currWNDW : this.wndw

        window := (activeWNDW != "") ? activeWNDW : "ahk_exe " . activeEXE

        try {
            if (WinGetMinMax(window) = -1) {
                return false
            }
            
        
            style := WinGetStyle(window)
            this.fullscreen := (style & 0x20800000) ? false : true

            return this.fullscreen
        }

        return false
    }

    getPID() {
        activeEXE  := (this.currEXE != "")  ? this.currEXE  : this.exe
        activeWNDW := (this.currWNDW != "") ? this.currWNDW : this.wndw

        PID := 0

        if (activeWNDW != "" && WinHidden(activeWNDW)) {
            resetDHW := A_DetectHiddenWindows

            DetectHiddenWindows(false)
            PID := WinGetPID(activeWNDW)
            DetectHiddenWindows(resetDHW)
        }
        else if (activeEXE != "") {
            PID := ProcessExist(activeEXE)
        }

        return PID
    }

    getHWND() {
        activeEXE  := (this.currEXE != "")  ? this.currEXE  : this.exe
        activeWNDW := (this.currWNDW != "") ? this.currWNDW : this.wndw

        HWND := WinHidden((activeWNDW != "") ? activeWNDW : "ahk_exe" activeEXE)

        return HWND
    }

    updateVolume() {
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

    newProgram := toArray(StrSplit(params, A_Space))
    newName    := newProgram.RemoveAt(1)

    for key, value in globalPrograms {
        if (StrLower(key) = StrLower(newName)) {
            globalRunning[newName] := Program(value)

            if (setCurrent) {
                setStatusParam("currProgram", newName)
            }

            if (launchProgram) {
                globalRunning[newName].launch(newProgram)
            }

            if (customAttributes != "") {                
                for key, value in customAttributes {
                    globalRunning[newName].%key% := value
                }
            }
        
            return
        }
    }

    ErrorMsg("Program " . newName . " was not found")
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

            processNameBuff := Buffer(size, 0)
            processNamePtr  := DllCall("psapi.dll\GetModuleBaseName", "Ptr", processPtr, "Ptr", 0, "Ptr", processNameBuff.Ptr, "UInt", size // 2)
            if (!processNamePtr) {
                processNamePtr := DllCall("psapi.dll\GetProcessImageFileName", "Ptr", processPtr, "Ptr", processNameBuff.Ptr, "UInt", size // 2)
            }

            DllCall("CloseHandle", "Ptr", processPtr)

            processName := StrGet(processNameBuff)
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

    for key, value in globalPrograms {
        if (!globalRunning.Has(key) && ((value.Has("exe") && checkEXE(value["exe"])) || (value.Has("wndw") && checkWNDW(value["wndw"])))) {
            createProgram(key, false, false)
        }
    }

    numForeground := 0
    for key, value in globalRunning {
        if (!value.exists()) {
            globalRunning.Delete(key)
        }
        else if (!value.background) {
            numForeground += 1
        }
    }

    if (globalConfig["Programs"].Has("Default") && globalConfig["Programs"]["Default"] != "" && numForeground = 0) {
        if (!globalPrograms.Has(globalConfig["Programs"]["Default"])) {
            ErrorMsg("Default Program" . globalConfig["Programs"]["Default"] . " has no config", true)
        }

        createProgram(globalConfig["Programs"]["Default"])
    }

    if (globalConfig["Programs"].Has("Required") && globalConfig["Programs"]["Required"] != "") {
        checkRequiredPrograms()
    }
}

; checks & updates the running list of programs specifically for required programs
;
; returns null
checkRequiredPrograms() {
    global globalConfig
    global globalRunning
    global globalPrograms

    for item in toArray(globalConfig["Programs"]["Required"]) {
        if (!globalPrograms.Has(item)) {
            ErrorMsg("Required Program " . item . "has no config", true)
        }

        if (!globalRunning.Has(item)) {
            if ((globalPrograms[item].Has("exe") && checkEXE(globalPrograms[item]["exe"])) || (globalPrograms[item].Has("wndw") && checkWNDW(globalPrograms[item]["wndw"]))) {
                createProgram(item, false, false)
            }
            else {
                createProgram(item, true, false)
            }
        }
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

        globalRunning.Delete(name)
    }
}