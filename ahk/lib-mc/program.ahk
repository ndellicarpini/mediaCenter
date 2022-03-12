; creates an executable generic object that gets added to globalRunning
; this executable object will contain a lot of the generic features taken from executable json files
; each function & more in json files has default version as well
class Program {
    ; attributes
    name    := ""
    dir     := ""
    exe     := ""
    wndw    := ""
    time    := 0

    background  := false
    enablePause := true

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
        ; set basic attributes
        this.name := (exeConfig.Has("name")) ? exeConfig["name"] : this.name
        this.dir  := (exeConfig.Has("dir"))  ? exeConfig["dir"]  : this.dir
        this.exe  := (exeConfig.Has("exe"))  ? exeConfig["exe"]  : this.exe
        this.wndw := (exeConfig.Has("wndw")) ? exeConfig["wndw"] : this.wndw
        
        this.background := (exeConfig.Has("background")) ? exeConfig["background"] : this.background

        this.time := A_TickCount

        ; set custom functions
        this.customLaunch      := (exeConfig.Has("launch"))       ? exeConfig["launch"]       : this.customLaunch
  
        this.customPause       := (exeConfig.Has("pause"))        ? exeConfig["pause"]        : this.customPause
        this.customResume      := (exeConfig.Has("resume"))       ? exeConfig["resume"]       : this.customResume
  
        this.customExit        := (exeConfig.Has("exit"))         ? exeConfig["exit"]         : this.customExit
        this.customRestore     := (exeConfig.Has("restore"))      ? exeConfig["restore"]      : this.customRestore
        this.customMinimize    := (exeConfig.Has("minimize"))     ? exeConfig["minimize"]     : this.customMinimize

        this.hotkeys := (exeConfig.Has("hotkeys")) ? exeConfig["hotkeys"] : this.hotkeys

        this.enablePause := (exeConfig.Has("enablePause")) ? exeConfig["enablePause"] : this.enablePause

        ; set pause contents if appropriate
        if (this.enablePause) {
            this.pauseOptions := (exeConfig.Has("pauseOptions")) ? exeConfig["pauseOptions"]        : this.pauseOptions
            this.pauseOrder   := (exeConfig.Has("pauseOrder"))   ? toArray(exeConfig["pauseOrder"]) : this.pauseOrder
        }
    }

    launch(args) {
        ; TODO
        ; take args from externalMessage
        if (this.customLaunch != "") {
            runFunction(this.customLaunch, args)
        }
        else if (!IsObject(this.exe) && this.exe != "") {
            Run validateDir(this.dir) . this.exe . ((args != "" || (args && args.Length > 0)) ? joinArray(args) : ""), validateDir(this.dir), ((this.background) ? "Hide" : "Max")
        }
        else {
            ErrorMsg(this.name . "does not have an exe defined, it cannot be launched with default settings")
            return
        }
    }
    
    pause() {
        ; TODO
    }

    resume() {
        ; TODO
    }

    restore() {
        activeEXE  := (this.currEXE != "")  ? this.currEXE  : this.exe
        activeWNDW := (this.currWNDW != "") ? this.currWNDW : this.wndw

        window := (activeWNDW != "") ? activeWNDW : "ahk_exe " . activeEXE
        if (!WinHidden(window)) {
            return
        }

        WinWait window

        if (this.customRestore != "") {
            runFunction(this.customRestore)
            return
        }

        ; TODO - think about removing borders & making fullscreen
        ; for now just gonna restore & activate
        if (!WinActive(window) || WinGetMinMax(window) != 1) {
            WinActivate(window)
            Sleep(100)
            WinMaximize(window)

            this.time := A_TickCount
        }
    }

    minimize() {
        activeEXE  := (this.currEXE != "")  ? this.currEXE  : this.exe
        activeWNDW := (this.currWNDW != "") ? this.currWNDW : this.wndw

        if (this.customMinimize != "") {
            runFunction(this.customMinimize)
            return
        }

        window := (activeWNDW != "") ? activeWNDW : "ahk_exe " . activeEXE

        WinMinimize(window)
    }

    exit() {
        ; TODO - think about if this.wndw -> don't wait for exe to close
        activeEXE  := (this.currEXE != "")  ? this.currEXE  : this.exe
        activeWNDW := (this.currWNDW != "") ? this.currWNDW : this.wndw

        if (this.customExit != "") {
            runFunction(this.customExit)
            return
        }

        window := (activeWNDW != "") ? activeWNDW : "ahk_exe " . activeEXE
        count := 0
        maxCount := 32

        WinClose(window)

        exeExists := (activeEXE != "") ? ProcessExist(activeEXE) : WinHidden(window)
        while (exeExists && count < maxCount) {
            count += 1
            exeExists := (activeWNDW != "") ? ProcessExist(activeWNDW) : WinHidden(window)

            Sleep(250)
        }

        if (exeExists) {
            ProcessWinClose(window)
        }
    }

    exists() {
        ; check if wndw exists
        wndwStatus := false

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

        if (wndwStatus) {
            return true
        }

        ; check if exe exists
        exeStatus := false

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

        return exeStatus

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
    }

    getPID() {
        PID := ProcessExist(this.exe)

        if (PID > 0 && this.exe != "") {
            return PID
        }

        if (WinHidden(this.wndw) && this.wndw != "") {
            resetDHW := A_DetectHiddenWindows

            DetectHiddenWindows(false)
            PID := WinGetPID(this.wndw)
            DetectHiddenWindows(resetDHW)

            return PID
        }

        ErrorMsg(this.name . ".getPID() failed")
        return -1
    }

}

; creates a program that gets added to globalRunning
;  params - params to pass to Program(), first element of params must be program name
;  launchProgram - if program.launch() should be called
;  setCurrent - if currProgram should be updated
;  customTime - manual time value to set (useful for backup)
;
; returns null
createProgram(params, launchProgram := true, setCurrent := true, customTime := "") {   
    global globalRunning
    global globalPrograms

    newProgram := toArray(StrSplit(params, A_Space))
    newName    := newProgram.RemoveAt(1)

    for key, value in globalPrograms {
        if (key = newName) {
            globalRunning[newName] := Program(value)

            if (setCurrent) {
                setStatusParam("currProgram", newName)
            }

            if (launchProgram) {
                globalRunning[newName].launch(newProgram)
            }

            if (customTime != "") {
                globalRunning[newName].time := customTime
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

    prevTime := 0
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

        createProgram(globalConfig["Programs"]["Default"], true, true)
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