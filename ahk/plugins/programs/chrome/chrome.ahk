class ChromeProgram extends Program {
    _mouseMoveDelay := 100
    _fullscreenDelay := 100

    _restore() {
        retVal := super._restore()

        if (WinGetMinMax(this.getHWND()) = 1) {
            this._fullscreen()
        }

        return retVal
    }

    _fullscreen() {
        super._fullscreen()
        Sleep(80)

        hwnd := this.getHWND()
        if (WinGetMinMax(hwnd) = 1) {
            WinRestoreMessage(hwnd)
            Sleep(80)
        }
        
        ; for some reason chrome's display area is smaller than the window (cool!)
        WinMove(MONITOR_X - (MONITOR_W * 0.005), MONITOR_Y, MONITOR_W + (MONITOR_W * 0.01), MONITOR_H + (MONITOR_H * 0.01), hwnd)
    }

    _exit() {
        currHWND := this.getHWND()
        while (currHWND != 0) {
            WinClose(currHWND)
            Sleep(100)

            if (WinExist("Leave site?")) {
                WindowSend("{Enter}", "Leave site?")
            }

            currHWND := this.getHWND()
        }
    }

    ; custom function
    pip() {
        this.send("!p")
    }
}
