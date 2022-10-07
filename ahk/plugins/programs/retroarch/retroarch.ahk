retroarchLaunch(rom) {
    global globalRunning

    this := globalRunning["retroarch"]
    core := "cores\" . this.core . "_libretro.dll"

    Run validateDir(this.dir) . this.exe . A_Space . '"-L" "' . core . '" "' . rom . '"', validateDir(this.dir), "Max"
}

retroarchSaveState(slot) {
    SendSafe("{F2}")
}

retroarchLoadState(slot) {
    SendSafe("{F4}")
}

retroarchRewind() {
    global globalRunning

    this := globalRunning["retroarch"]

    if (this.rewinding) {
        Send("{r up}")
    }
    else {
        Send("{r down}")
    }
}

retroarchMAMECheck() {
    global globalRunning
    return (globalRunning["retroarch"].console = "arcade") ? true : false
}

retroarchToggleMAMEMenu() {
    global globalRunning

    this := globalRunning["retroarch"]

    this.resume()
    Sleep(50)
    
    SendSafe("{Tab}")
}