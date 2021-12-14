; create an executable generic object that gets added to openEXE
; this executable object will contain a lot of the generic features taken from executable json files
; each function & more in json files has default version as well
class Executable {
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
    cleanTooltup(tooltipArr) {
        ; TODO
    }

    launch(args*) {
        ; TODO
        ; take args from mainMessage
        ; set currEXE -> then tooltip -> then postTooltip
    }

    tooltip() {
        ; TODO
    }

    postTooltip() {
        ; TODO
    }
    
    pause() {
        ; TODO
    }

    resume() {
        ; TODO
    }

    restore() {
        ; TODO
    }

    minimize() {
        ; TODO
    }

    exit() {
        ; TODO
        
        exitExecutable(name)
    }

    ; called in hotkeyThread
    checkHotkeys() {
        ; TODO
    }

}


createExecutable(name, params, executables) {
    for key in StrSplit(executables['keys'], ',') {
        if (key = name) {
            retObj := Executable.New(executables[key])
            retObj.launch(params)
        
            return retObj
        }
    }

    ErrorMsg("Executable " . name . " was not found in config\executables")
    return ""
}

exitExecutable(name, params := "") {
    ; TODO - maybe send to main so localexecutables can be updated? maybe not?
    msgList := ["Exit", name]
    for item in params {
        msgList.Push(item)
    }

    sendListToMain(msgList)
}