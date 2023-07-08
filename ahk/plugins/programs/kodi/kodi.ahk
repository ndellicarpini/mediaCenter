class KodiProgram extends Program {
    _fullscreen() {
        SendSafe("\")
    }

    ; kodi only properly minimizes if its active?
    _minimize() {
        hwnd := this.getHWND()

        while (WinGetMinMax(hwnd) != -1) {
            if (!WinExist(hwnd)) {
                break
            }

            WinActivate(hwnd)
            Sleep(100)
            WinMinimize(hwnd)

            Sleep(500)
        }
    }

    ; custom function
    reload() {
        this.exit()
        Sleep(500)
    }
}