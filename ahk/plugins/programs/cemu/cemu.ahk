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