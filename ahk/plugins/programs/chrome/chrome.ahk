class ChromeProgram extends Program {
    _restore() {
        retVal := super._restore()

        if (WinGetMinMax(this.getHWND()) = 1) {
            this._fullscreen()
        }

        return retVal
    }

    _fullscreen() {
        hwnd := this.getHWND()
        if (WinGetMinMax(hwnd) = 1) {
            WinRestoreMessage(hwnd)
            Sleep(80)
        }

        ; for some reason chrome's display area is smaller than the window (cool!)
        WinMove(Round(MONITOR_X - (MONITOR_W * 0.003)), MONITOR_Y, Round(MONITOR_W + (MONITOR_W * 0.007)), Round(MONITOR_H + (MONITOR_H * 0.006)), hwnd)
    }

    _checkFullscreen() {
        hwnd := this.getHWND()
      
        try {
            WinGetClientPos(&X, &Y, &W, &H, hwnd)

            return (W >= (MONITOR_W * 0.98) && H >= (MONITOR_H * 0.98) 
                && (X + (W * 0.02)) >= MONITOR_X && X < (MONITOR_X + MONITOR_W) 
                && (Y + (H * 0.02)) >= MONITOR_Y && Y < (MONITOR_Y + MONITOR_H)) ? true : false
        }

        return false
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

    ; custom functions
    pip() {
        this.send("!p")
    }

    zoomIn() {
        Send("{Ctrl down}")
        Sleep(50)
        MouseClick("WheelUp")
        Sleep(50)
        Send("{Ctrl up}")
    }

    zoomOut() {
        Send("{Ctrl down}")
        Sleep(50)
        MouseClick("WheelDown")
        Sleep(50)
        Send("{Ctrl up}")
    }
}
