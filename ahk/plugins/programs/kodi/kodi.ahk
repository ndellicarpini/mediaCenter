class KodiProgram extends Program {
    _fullscreen() {
        SendSafe("\")
    }

    ; kodi only properly minimizes if its active?
    _minimize() {
        WinActivate("Kodi")
        Sleep(200)
        WinMinimize("Kodi")
    }

    ; custom function
    reload() {
        this.exit()
        Sleep(500)
    }
}