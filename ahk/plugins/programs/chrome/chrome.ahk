class ChromeProgram extends Program {
    _restore() {
        retVal := super._restore()

        hwnd := this.getHWND()
        WinGetClientPos(&X, &Y,,, hwnd)

        if (WinGetMinMax(hwnd) = 1
            && (X >= this._monitorX && X < (this._monitorX + this._monitorW)) 
            && (Y >= this._monitorY && Y < (this._monitorY + this._monitorH))) {
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
        WinMove(Round(this._monitorX - (this._monitorW * 0.003)), this._monitorY, Round(this._monitorW + (this._monitorW * 0.007)), Round(this._monitorH + (this._monitorH * 0.006)), hwnd)
    }

    _checkFullscreen() {
        hwnd := this.getHWND()
      
        try {
            WinGetClientPos(&X, &Y, &W, &H, hwnd)

            return (W >= (this._monitorW * 0.98) && H >= (this._monitorH * 0.98)
                && W <= (this._monitorW * 1.05) && H <= (this._monitorH * 1.05) 
                && (X + (W * 0.02)) >= this._monitorX && X < (this._monitorX + this._monitorW) 
                && (Y + (H * 0.02)) >= this._monitorY && Y < (this._monitorY + this._monitorH)) ? true : false
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

        if (this.getEXE() != "") {
            super._exit()
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
