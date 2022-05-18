; console should either start the configurator, or load default settings
; console should check defaultOverride for different controllers/emulators
; emuobj should hold all of the settings of the emulator & controller options
; rom & currentController passed through

; default override should be based on "name" rather than rom file, that way aliases like Slippi can work
; need some way to set platform -> emulator

; STUBS FINGER LICKIN GOOD

jackboxLaunch(version) {
    global globalRunning

    this := globalRunning["jackbox"]

    retVal := 0
    if (version = 1) {
        retVal := steamGameLaunchHandler("jackbox", "steam://rungameid/331670")
    }
    else if (version = 2) {
        retVal := steamGameLaunchHandler("jackbox", "steam://rungameid/397460")
    }
    else if (version = 3) {
        retVal := steamGameLaunchHandler("jackbox", "steam://rungameid/434170")
    }

    return (retVal) ? 0 : -1
}

winGameLaunch(game) {
    global globalRunning

    this := globalRunning["wingame"]

    pathArr := StrSplit(game, "\")
    
    exe := pathArr.RemoveAt(pathArr.Length)
    path := joinArray(pathArr, "\")

    Run game, path
}

bigBoxRestore() {
    if (WinShown("LaunchBox Game Startup")) {
        return -1
    }
}