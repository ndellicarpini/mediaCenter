#Include std.ahk
#Include confio.ahk

; create an executable generic object that gets added to openEXE
; this executable object will contain a lot of the generic features taken from executable json files
; each function & more in json files has default version as well
class Program {
    ; attributes
    name    := ""
    dir     := ""
    exe     := ""
    wndw    := ""
    time    := 0

    background := false

    enablePause   := true
    enableTooltip := true

    pauseOptions := Map()
    hotkeys      := Map()

    tooltipInner := ""

    ; functions
    customLaunch      := ""
    customPostTooltip := ""

    customPause  := ""
    customResume := ""

    customExit     := ""
    customRestore  := ""
    customMinimize := ""

    __New(exeConfig) {
        ; set basic attributes
        this.name := (exeConfig.items.Has("name")) ? exeConfig.items["name"] : this.name
        this.dir  := (exeConfig.items.Has("dir"))  ? exeConfig.items["dir"]  : this.dir
        this.exe  := (exeConfig.items.Has("exe"))  ? exeConfig.items["exe"]  : this.exe
        this.wndw := (exeConfig.items.Has("wndw")) ? exeConfig.items["wndw"] : this.wndw

        this.time := A_TickCount

        ; set custom functions
        this.customLaunch      := (exeConfig.items.Has("launch"))      ? exeConfig.items["launch"]      : this.customLaunch
        this.customPostTooltip := (exeConfig.items.Has("postTooltip")) ? exeConfig.items["postTooltip"] : this.customPostTooltip

        this.customPause       := (exeConfig.items.Has("pause"))       ? exeConfig.items["pause"]       : this.customPause
        this.customResume      := (exeConfig.items.Has("resume"))      ? exeConfig.items["resume"]      : this.customResume

        this.customExit        := (exeConfig.items.Has("exit"))        ? exeConfig.items["exit"]        : this.customExit
        this.customRestore     := (exeConfig.items.Has("restore"))     ? exeConfig.items["restore"]     : this.customRestore
        this.customMinimize    := (exeConfig.items.Has("minimize"))    ? exeConfig.items["minimize"]    : this.customMinimize

        ; set pause/tooltip/hotkey attributes
        this.enablePause := (exeConfig.items.Has("enablePause")) 
            ? exeConfig.items["enablePause"] : this.enablePause
        
        this.enableTooltip := (exeConfig.items.Has("enableTooltip")) 
            ? exeConfig.items["enableTooltip"] : this.enableTooltip

        this.hotkeys := (exeConfig.subConfigs.Has("hotkeys")) 
            ? this.cleanHotkeys(exeConfig.subConfigs["hotkeys"]) : this.hotkeys

        ; set pause & tooltip contents if appropriate
        if (this.enablePause) {
            this.pauseOptions := (exeConfig.subConfigs.Has("pauseOptions")) 
                ? this.cleanPauseOptions(exeConfig.subConfigs["pauseOptions"]) : this.pauseOptions
        }

        if (this.enableTooltip) {
            this.tooltipInner := (exeConfig.items.Has("tooltip")) 
                ? this.cleanTooltip(toArray(exeConfig.items["tooltip"])) : this.tooltipText
        }
    }

    launch(args*) {
        ; TODO
        ; take args from mainMessage
        ; set currEXE -> then tooltip -> then postTooltip
        if (this.customLaunch != "") {
            runFunction(this.customLaunch, args)
        }
        else {
            Run "%validateDir(this.dir)%%this.exe%" (args != "" || (args && args.Length > 0)) ? joinArray(args) : ""
        }

        if (this.enableTooltip) {
            this.tooltip()
            this.postTooltip()
        }
    }

    tooltip() {
        ; TODO
    }

    postTooltip() {
        if (this.customPostTooltip != "") {
            runFunction(this.customPostTooltip)
        }
        
        this.restore()
    }
    
    pause() {
        ; TODO
    }

    resume() {
        ; TODO
    }

    restore() {
        if (this.customRestore != "") {
            runFunction(this.customRestore)
            return
        }

        ; TODO - think about removing borders & making fullscreen
        ; for now just gonna restore & activate
        window := (this.wndw != "") ? this.wndw : "ahk_exe " . this.exe

        if (!WinActive(window) || WinGetMinMax(window) = -1) {
            WinActivate(window)
            Sleep(100)
            WinMaximize(window)

            this.time := A_TickCount
        }
    }

    minimize() {
        if (this.customMinimize != "") {
            runFunction(this.customMinimize)
            return
        }

        window := (this.wndw != "") ? this.wndw : "ahk_exe " . this.exe

        WinMinimize(window)
    }

    exit() {
        if (this.customExit != "") {
            runFunction(this.customExit)
            return
        }

        window := (this.wndw != "") ? this.wndw : "ahk_exe " . this.exe
        count := 0
        maxCount := 50

        WinClose(window)
        Sleep(250)

        exeExists := (this.exe != "") ? ProcessExist(this.exe) : WinHidden(window)
        while (exeExists && count < maxCount) {
            count += 1
            exeExists := (this.exe != "") ? ProcessExist(this.exe) : WinHidden(window)

            Sleep(100)
        }

        ProcessWinClose(window)
        Sleep(500)

        exeExists := (this.exe != "") ? ProcessExist(this.exe) : WinHidden(window)
        while (exeExists) {
            ProcessWaitClose(window)

            Sleep(500)
            exeExists := (this.exe != "") ? ProcessExist(this.exe) : WinHidden(window)
        }
    }

    exists() {
        return (checkEXE(this.exe) || checkWNDW(this.wndw))
    }

    ; clean up hotkeys to make appropriate to check in hotkeyScript (like clean keys, get funcs)
    ;  hotkeyConfig - config object w/ hotkey info from json
    ;
    ; returns this.hotkeys
    cleanHotkeys(hotkeyConfig) {
        ; TODO
    }

    ; clean up pause options to be appended to pause screen (like variable options)
    ;  pauseConfig - config object w/ pause info from json
    ;
    ; returns this.pauseOptions
    cleanPauseOptions(pauseConfig) {
        ; TODO
    }

    ; clean up tooltip
    ;  tooltipArr - tooltip info from json
    ;
    ; returns this.tooltipInner
    cleanTooltip(tooltipArr) {
        ; TODO
    }

}

; creates an program to use
;  params - params to pass to Program.New(), first element of params must be program name
;  status - thread safe status object
;  programs - list of programs parsed at start of main
;  launchProgram - if program.launch() should be called
;  setCurrent - if currProgram should be updated
;  customTime - manual time value to set (useful for backup)
;
; returns either the program, or empty string
createProgram(params, status, programs, launchProgram := true, setCurrent := true, customTime := 0) {
    newProgram := toArray(StrSplit(params, A_Space))
    if (newProgram.Length = 0) {
        return status
    }

    newName := newProgram.RemoveAt(1)

    for key in StrSplit(programs["keys"], ",") {
        if (key = newName) {
            status["openPrograms"] := addKeyListString(status["openPrograms"], newName)
            status["openPrograms"][newName] := Program.New(programs[key])

            if (setCurrent) {
                status["currProgram"] := newName
            }

            if (launchProgram) {
                status["openPrograms"][newName].launch(newProgram)
            }

            if (customTime > 0) {
                status["openPrograms"][newName].time := customTime
            }
        
            return status
        }
    }

    ErrorMsg("Program " . newName . " was not found")
    return status
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
;
; return either "" if the process is not running, or the name of the process
checkEXE(exe) {
    if (exe = "") {
        return false
    }

    if (IsObject(exe)) {
        for process in ComObjGet("winmgmts:").ExecQuery("Select * from Win32_Process") {
            if (exe.Has(process.Name)) {
                return true
            }
        }
    }
    else {
        return ProcessExist(exe) ? true : false
    }

    return false
}

; takes a variable of window maps (key=window) and returns true if any of the functions return
;  wndw - either an wndw name or a map with each key being an wndw
;
; return either "" if the process is not running, or the name of the process
checkWNDW(wndw) {
    if (wndw = "") {
        return false
    }

    if (IsObject(wndw)) {
		if (wndw.Has("keys")) {
			for key in StrSplit(wndw["keys"], ",") {
				if (WinShown(key)) {
					return true
				}
			}
		}
		else {
			for key, empty in wndw {
				if (WinShown(key)) {
					return true
				}
			}
		}
	}
    else {
        return WinShown(wndw) ? true : false
    }

	return false
}

; checks that any of the programs exist in program list
;  programs - list of program configs
;
; returns either the name of the program or ""
checkAllPrograms(programs) {
    for key in StrSplit(programs["keys"], ",") {
        if ((programs[key].items.Has("exe") && checkEXE(programs[key].items["exe"]))
            || (programs[key].items.Has("wndw") && checkWNDW(programs[key].items["wndw"]))) {
            
            return key
        }
    }

    return ""
}