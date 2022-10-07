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