class ChromeProgram extends Program {
    _mouseMoveDelay := 0

    _getHWNDList() {
        hwndList := super._getHWNDList()
        loop hwndList.Length {
            if (WinGetTitle(hwndList[A_Index]) = "Picture in picture") {
                hwndList.RemoveAt(A_Index)
                break
            }
        }

        return hwndList
    }

    _fullscreen() {
        SendSafe("{F11}")
    }

    _exit() {
        currHWND := this.getHWND()
        while (currHWND != 0) {
            WinClose(currHWND)
            Sleep(100)

            if (WinExist("Leave site?")) {
                ControlSend("{Enter}",, "Leave site?")
            }

            currHWND := this.getHWND()
        }
    }

    ; custom function
    pip() {
        Send("{Alt down}")
        SendSafe("p")
        Send("{Alt up}")
    }
}
