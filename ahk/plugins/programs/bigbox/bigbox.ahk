class BigBoxProgram extends Program {
    _launch(args*) {
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