class BigBoxProgram extends Program {
    _launch(args*) {
        global globalStatus

        if (globalStatus["currProgram"]["id"] = this.id && !globalStatus["suspendScript"] && !globalStatus["desktopmode"]) {
            count := 0
            maxCount := 100
            ; make sure LaunchBox is not open while launching bigbox
            while (ProcessExist("LaunchBox.exe") && count < maxCount) {
                count += 1
                Sleep(200)
            }

            if (ProcessExist("LaunchBox.exe")) {
                ProcessClose("LaunchBox.exe")
                Sleep(500)
            }
        }

        ; for some reason BigBox freaks out when using RunAsUser (ShellExecute) 
        Run(this.dir . this.exe . A_Space . joinArray(args), this.dir)
    }

    _restore() {
        startupHWND := 0
        mainHWND := 0

        for hwnd in this.getHWNDList() {
            title := WinGetTitle(hwnd)
            if (title = "LaunchBox Game Startup") {
                startupHWND := hwnd
                break
            }
            if (title = "LaunchBox Big Box") {
                mainHWND := hwnd
            }
        }

        if (startupHWND != 0) {
            if (!WinActive(startupHWND)) {
                WinActivateForeground(startupHWND)
            }
        }
        else if (mainHWND != 0) {
            if (!WinActive(mainHWND)) {
                return WinActivateForeground(mainHWND)
            }
        }
    }
}