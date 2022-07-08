; --- CEMU --- 
cemuLaunch(rom) {
    global globalRunning

    this := globalRunning["cemu"]

    Run validateDir(this.dir) . this.exe . A_Space . '"-f" "-g" "' . rom . '"', validateDir(this.dir), ((this.background) ? "Hide" : "Max")
}

cemuPause() {
    global globalRunning

    this := globalRunning["cemu"]

    this.fullscreen()
    Sleep(100)

    ProcessSuspend(this.getPID())
}

cemuResume() {
    global globalRunning

    this := globalRunning["cemu"]

    ProcessResume(this.getPID())

    Sleep(100)
    this.fullscreen()
}

; --- CITRA ---
citraSaveState(slot) {
    Send("{Ctrl down}")
    SendSafe("c")
    Send("{Ctrl up}")
}

citraLoadState(slot) {
    Send("{Ctrl down}")
    SendSafe("v")
    Send("{Ctrl up}")
}

citraFastForward() {
    Send("{Ctrl down}")
    SendSafe("z")
    Send("{Ctrl up}")
}

; --- DESMUME ---
desmumeReset() {
    Send("{Ctrl down}")
    SendSafe("r")
    Send("{Ctrl up}")
}

desmumeSaveState(slot) {
    Send("{Shift down}")
    SendSafe("{F1}")
    Send("{Shift up}")
}

desmumeLoadState(slot) {
   SendSafe("{F1}")
}

desmumeFastForward() {
    global globalRunning

    this := globalRunning["desmume"]

    if (this.fastForwarding) {
        Send("{Tab up}")
    }
    else {
        Send("{Tab down}")
    }
}

; --- DOLPHIN ---
dolphinSaveState(slot) {
    Send("{Shift down}")
    Sleep(100)
    SendSafe("{F1}")
    Sleep(100)
    Send("{Shift up}")
}

dolphinLoadState(slot) {
    SendSafe("{F1}")
}

dolphinFastForward() {
    global globalRunning

    this := globalRunning["dolphin"]

    if (this.fastForwarding) {
        Send("{Tab up}")
    }
    else {
        Send("{Tab down}")
    }
}

; --- PCSX2 --- 
pcsx2SaveState(slot) {
    SendSafe("{F1}")
}

pcsx2LoadState(slot) {
    SendSafe("{F3}")
}

; --- PPSSPP --
ppssppReset() {
    Send("{Ctrl down}")
    SendSafe("b")
    Send("{Ctrl up}")
}

ppssppSaveState(slot) {
    SendSafe("{F1}")
}

ppssppLoadState(slot) {
    SendSafe("{F3}")
}

ppssppFastForward() {
    global globalRunning

    this := globalRunning["ppsspp"]

    if (this.fastForwarding) {
        Send("{Tab up}")
    }
    else {
        Send("{Tab down}")
    }
}

; --- RETROARCH
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

; --- XEMU --- 
xemuLaunch(rom) {
    global globalRunning

    this := globalRunning["xemu"]

    Run validateDir(this.dir) . this.exe . A_Space . '"-full-screen" "-dvd_path" "' . rom . '"', validateDir(this.dir), "Max"
}

xemuResume() {
    Send("{Ctrl down}p{Ctrl up}")
    Sleep(85)
    SendSafe("{Escape}")
}

xemuReset() {
    Send("{Ctrl down}")
    SendSafe("r")
    Send("{Ctrl up}")
}

; --- XENIA ---
xeniaPause() {
    global globalRunning

    this := globalRunning["xenia"]

    ProcessSuspend(this.getPID())
}

xeniaResume() {
    global globalRunning

    this := globalRunning["xenia"]

    ProcessResume(this.getPID())
}